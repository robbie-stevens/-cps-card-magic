import processing.serial.*;
import processing.video.*;
import oscP5.*;
import netP5.*;
import java.util.concurrent.ConcurrentLinkedQueue;

final String ARDUINO_PORT = "/dev/cu.usbmodem21201";
final int BAUD = 9600, CAMERA_INDEX = 1;
final int MARKER_MIN_RESULTS = 5, MARKER_HOLD_MS = 400;
final int MAX_RESULT_GAP_MS = 250, ORDINARY_MIN_RESULTS = 3;
final int ORDINARY_HOLD_MS = 200;
final long LINK_STALE_MS = 2000;

Capture camera;
OscP5 osc;
NetAddress wekinator;
ConcurrentLinkedQueue<String> commands = new ConcurrentLinkedQueue<String>();
ConcurrentLinkedQueue<String> replies = new ConcurrentLinkedQueue<String>();
ConcurrentLinkedQueue<Prediction> predictions = new ConcurrentLinkedQueue<Prediction>();
volatile boolean workerRunning = true, connected = false, reconnectRequested = false;
volatile String linkStatus = "Connecting";
volatile long lastHostTick = System.currentTimeMillis();
Thread serialWorker;
boolean ready = false, stopped = false, waiting = false, scanning = false;
boolean targetSent = false, cardFound = false, cameraConfirmed = false;
char mode = 'X';
int cameraFrames = 0, lastFeatureAt = 0, features = 0, latestClass = -1;
int ordinaryCount = 0, markerCount = 0;
long ordinaryFirst = 0, markerFirst = 0, lastPrediction = 0, scanStarted = 0;
long waitStarted = 0;
boolean markerArmed = false;
String status = "Waiting for confirmed STOPPED", feedback = "None", detection = "Not scanning";

class Prediction {
  int label;
  long time;
  Prediction(int value) { label = value; time = System.currentTimeMillis(); }
}

void setup() {
  size(1200, 580);
  pixelDensity(1);
  textAlign(LEFT, TOP);
  printArray(Serial.list());
  serialWorker = new Thread(new Runnable() { public void run() { serialLoop(); } });
  serialWorker.setDaemon(true);
  serialWorker.start();
  osc = new OscP5(this, 12000);
  wekinator = new NetAddress("127.0.0.1", 6448);
  camera = new Capture(this, "pipeline:avfvideosrc device-index=" + CAMERA_INDEX);
  camera.start();
  printArray(Capture.list());
}

// This worker exclusively owns serial reads/writes. Camera work cannot delay H.
// Missing replies cause a stopped reconnect, NEVER an automatic motion restart.
void serialLoop() {
  while (workerRunning) {
    Serial port = null;
    try {
      connected = false;
      linkStatus = "Opening " + ARDUINO_PORT;
      commands.clear();
      port = new Serial(this, ARDUINO_PORT, BAUD);
      reconnectRequested = false;
      long opened = System.currentTimeMillis(), lastRx = opened, lastH = 0, lastProbe = 0;
      boolean handshaken = false, stopAcknowledged = false;
      String line = "";
      while (workerRunning && !reconnectRequested) {
        long now = System.currentTimeMillis();
        if (now - lastHostTick > 2500) {
          port.write('X');
          throw new RuntimeException("Control loop unresponsive; stopping for safety");
        }
        for (int i = 0; i < 2048 && port.available() > 0; i++) {
          char c = (char)port.read();
          if (c == '\n') {
            String message = line.trim(); line = "";
            if (message.length() == 0) continue;
            // Only valid protocol traffic counts as a live connection.
            if (message.startsWith("PONG ") || message.startsWith("READY ") ||
                message.equals("STOPPED") || message.equals("SCANNING") ||
                message.equals("SHUFFLING") || message.startsWith("TARGET_") ||
                message.startsWith("FAULT ") || message.startsWith("INFO ") || message.equals("BUSY")) {
              lastRx = now;
              if (message.equals("READY TWO_DC_NEXT_V1")) {
                handshaken = true; stopAcknowledged = false;
                connected = false; commands.clear(); port.write('X');
              }
              if (message.equals("STOPPED") && handshaken) {
                stopAcknowledged = true; connected = true; linkStatus = "Connected";
              }
              if (!message.startsWith("PONG ")) replies.offer(message);
            }
          } else if (c != '\r') {
            if (line.length() < 180) line += c; else line = "";
          }
        }
        if (!handshaken && now - opened > 2000 && now - lastProbe >= 1000) {
          port.write('?'); lastProbe = now;
        }
        if (handshaken && now - lastH >= 500) { port.write('H'); lastH = now; }
        String command;
        while ((command = commands.poll()) != null) {
          if (command.equals("X")) {
            stopAcknowledged = false;
            port.write('X');
          } else if (handshaken && connected) port.write(command);
        }
        if ((handshaken && now - lastRx > LINK_STALE_MS) ||
            (!handshaken && now - opened > 8000)) {
          port.write('X');
          throw new RuntimeException("No Arduino replies; reopening serial port");
        }
        Thread.sleep(10);
      }
    } catch (Exception e) {
      linkStatus = "Disconnected: " + e.getMessage();
    } finally {
      connected = false;
      commands.clear();
      replies.offer("HOST_LINK_LOST");
      if (port != null) {
        try { port.write('X'); } catch (Exception ignored) { }
        try { port.stop(); } catch (Exception ignored) { }
      }
    }
    try { Thread.sleep(1500); } catch (InterruptedException ignored) { }
  }
}

void resetDetection() {
  ordinaryCount = markerCount = 0;
  markerArmed = false;
  lastPrediction = 0;
  predictions.clear();
}

void stopRequest() {
  commands.clear(); commands.offer("X");
  scanning = false; targetSent = false; cardFound = false;
  stopped = false; waiting = true; waitStarted = millis();
  resetDetection();
  status = "Stop requested - waiting for STOPPED; motion restart locked";
}

void handleReply(String line) {
  println("[" + millis() + " ms] Arduino: " + line);
  feedback = line;
  if (line.equals("HOST_LINK_LOST") || line.startsWith("READY ")) {
    ready = false; stopped = false; waiting = false;
    scanning = false; targetSent = false; cardFound = false; mode = 'X';
    resetDetection(); status = "Synchronising connection; no automatic restart";
  } else if (line.equals("STOPPED") || line.startsWith("FAULT ")) {
    ready = connected; stopped = true; waiting = false; scanning = false;
    targetSent = false; cardFound = false; mode = 'X'; resetDetection(); status = line;
  } else if (line.equals("SHUFFLING")) {
    mode = 'S'; stopped = false; waiting = false; scanning = false; status = "Shuffling";
  } else if (line.equals("SCANNING")) {
    mode = 'D'; stopped = false; waiting = false; scanning = true; targetSent = false;
    resetDetection(); scanStarted = System.currentTimeMillis(); status = "Scanning";
  } else if (line.equals("TARGET_LATCHED")) {
    status = "Marker confirmed; completing THREE additional feeding pulses";
  } else if (line.startsWith("TARGET_PULSE ")) {
    status = line;
  } else if (line.equals("TARGET_DONE")) {
    if (targetSent && mode == 'D') {
      cardFound = true; status = "Your Card! Motors stopped";
    } else status = "Unexpected TARGET_DONE ignored";
    scanning = false; mode = 'X'; stopped = true; waiting = false;
  } else if (line.equals("BUSY")) stopRequest();
}

void draw() {
  lastHostTick = System.currentTimeMillis();
  String line;
  while ((line = replies.poll()) != null) handleReply(line);
  if (!connected) { ready = false; scanning = false; }
  if (waiting && millis() - waitStarted > 3500) {
    waiting = false; ready = false; stopped = false;
    reconnectRequested = true; status = "Acknowledgement missing; reconnecting safely";
  }
  updateCamera();
  Prediction p;
  while ((p = predictions.poll()) != null) processPrediction(p);
  long now = System.currentTimeMillis();
  if (scanning && now - lastPrediction > MAX_RESULT_GAP_MS) {
    ordinaryCount = markerCount = 0;
  }
  background(30); fill(255); textSize(25);
  text("Card Machine - monitored connection", 25, 20);
  textSize(17);
  text("C = Confirm camera / LCD welcome", 25, 75);
  text("S = Shuffle | D = Scan | X / Esc = Stop", 25, 110);
  text("R = Reconnect (stops motion; never resumes automatically)", 25, 145);
  text("Wekinator class: " + latestClass, 25, 200);
  text("Detection: " + detection, 25, 235, 730, 65);
  text("Arduino: " + feedback, 25, 305);
  text("Link: " + linkStatus, 25, 340, 730, 60);
  fill(100, 220, 150); text(status, 25, 405, 730, 65);
  if (cardFound) { fill(255, 220, 80); textSize(32); text("this is your card", 25, 490); }
  if (cameraFrames > 0) image(camera, 800, 75, 380, 285);
  fill(255); textSize(16);
  text("Camera frames: " + cameraFrames, 800, 390);
  text("OSC inputs sent: " + features, 800, 420);
  text("Camera confirmed: " + cameraConfirmed, 800, 450);
}

void keyPressed() {
  if (key == ESC) { key = 0; stopRequest(); return; }
  char c = Character.toUpperCase(key);
  if (c == 'X') { stopRequest(); return; }
  if (keyEvent.isAutoRepeat()) return;
  if (c == 'R') { stopRequest(); reconnectRequested = true; return; }
  if (c == 'C') {
    cameraConfirmed = cameraFrames > 0;
    if (ready && stopped && !waiting) commands.offer("C");
    return;
  }
  // T simulation intentionally removed so an accidental key cannot select a card.
  if (c != 'S' && c != 'D') return;
  if (!ready || !connected || !stopped || waiting) {
    status = "Wait for STOPPED / connection, or press X then R"; return;
  }
  if (c == 'D' && !cameraConfirmed) { status = "Confirm camera with C first"; return; }
  cardFound = false; targetSent = false; resetDetection();
  waiting = true; stopped = false; waitStarted = millis();
  commands.offer(str(c)); status = "Start requested";
}

void oscEvent(OscMessage message) {
  if (!message.checkAddrPattern("/wek/outputs")) return;
  int label;
  if (message.checkTypetag("f")) {
    float v = message.get(0).floatValue();
    if (abs(v - 1) < 0.01) label = 1;
    else if (abs(v - 2) < 0.01) label = 2;
    else return;
  } else if (message.checkTypetag("i")) label = message.get(0).intValue();
  else return;
  if (label == 1 || label == 2) {
    if (predictions.size() < 100) predictions.offer(new Prediction(label));
  }
}

void processPrediction(Prediction p) {
  latestClass = p.label;
  long now = System.currentTimeMillis();
  if (!scanning || targetSent || p.time < scanStarted || now - p.time > 250) return;
  if (p.time - lastPrediction > MAX_RESULT_GAP_MS) ordinaryCount = markerCount = 0;
  lastPrediction = p.time;
  if (!markerArmed) {
    if (p.label == 1) {
      if (ordinaryCount++ == 0) ordinaryFirst = p.time;
      if (ordinaryCount >= ORDINARY_MIN_RESULTS && p.time - ordinaryFirst >= ORDINARY_HOLD_MS) markerArmed = true;
    } else ordinaryCount = 0;
    detection = markerArmed ? "Armed: waiting for stable marker" : "Show ordinary cards first to arm detection";
    return;
  }
  if (p.label == 1) {
    markerCount = 0; detection = "Ordinary card - continuing"; return;
  }
  if (markerCount++ == 0) markerFirst = p.time;
  detection = "Marker candidate: " + markerCount + "/" + MARKER_MIN_RESULTS +
    " results, " + (p.time - markerFirst) + "/" + MARKER_HOLD_MS + " ms";
  if (markerCount >= MARKER_MIN_RESULTS && p.time - markerFirst >= MARKER_HOLD_MS) {
    targetSent = true; commands.offer("T");
    println("[" + millis() + " ms] MARKER_CONFIRMED results=" + markerCount);
    status = "Stable marker confirmed; waiting for Arduino final feeding";
  }
}

void updateCamera() {
  if (camera == null || !camera.available()) return;
  camera.read(); camera.loadPixels();
  if (camera.width <= 0 || camera.height <= 0 || camera.pixels.length < camera.width * camera.height) return;
  cameraFrames++;
  if (millis() - lastFeatureAt < 100) return;
  OscMessage message = new OscMessage("/wek/inputs");
  for (int row = 0; row < 20; row++) for (int col = 0; col < 20; col++) {
    int x = constrain(int((col + 0.5) * camera.width / 20), 0, camera.width - 1);
    int y = constrain(int((row + 0.5) * camera.height / 20), 0, camera.height - 1);
    message.add(brightness(camera.pixels[x + y * camera.width]));
  }
  osc.send(message, wekinator); lastFeatureAt = millis(); features++;
}

void dispose() {
  workerRunning = false;
  if (serialWorker != null) serialWorker.interrupt();
  super.dispose();
}
