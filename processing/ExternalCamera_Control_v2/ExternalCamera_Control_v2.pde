import processing.serial.*;
import processing.video.*;
import oscP5.*;
import netP5.*;

// ============================================================
// USER SETTINGS
// ============================================================
final String ARDUINO_PORT = "/dev/cu.usbmodem11201";
final int BAUD = 9600;

// The external camera that worked previously used device-index 0.
// Change only if the preview shows the wrong camera.
final int CAMERA_INDEX = 1;

// Must match Wekinator's project settings.
final String WEKINATOR_HOST = "127.0.0.1";
final int WEKINATOR_INPUT_PORT = 6448;
final int WEKINATOR_OUTPUT_PORT = 12000;

final int COLS = 20;
final int ROWS = 20;
final int FEATURE_INTERVAL_MS = 100;

// These are display values only. The real timing is controlled by Arduino.
final int DISPLAY_ON_TIME_MS = 80;
final int DISPLAY_OFF_TIME_MS = 1000;

// ============================================================
// DEVICES AND COMMUNICATION
// ============================================================
Serial arduino;
Capture camera;
OscP5 osc;
NetAddress wekinator;

// ============================================================
// CAMERA STATE
// ============================================================
int cameraFrames = 0;
int lastCameraFrame = 0;
int lastFeatures = 0;
int featureMessages = 0;
boolean cameraConfirmed = false;

// ============================================================
// ARDUINO / MACHINE STATE
// ============================================================
boolean ready = false;
boolean scanning = false;
boolean targetPending = false;
boolean targetSent = false;
boolean cardFound = false;
boolean commandWaiting = false;

char activeMode = 'X';
int latestClass = -1;
int scanStarted = 0;
int openedAt = 0;
int lastHeartbeat = 0;
int lastProbe = 0;
int commandAt = 0;

String status = "Waiting for Arduino";
String feedback = "None";
String serialLine = "";

void setup() {
  size(1200, 500);
  pixelDensity(1);
  colorMode(RGB, 255);
  textAlign(LEFT, TOP);

  println("Available serial ports:");
  printArray(Serial.list());

  arduino = new Serial(this, ARDUINO_PORT, BAUD);
  openedAt = millis();

  // One OSC listener receives Wekinator output on port 12000.
  // The same object sends camera features to Wekinator port 6448.
  osc = new OscP5(this, WEKINATOR_OUTPUT_PORT);
  wekinator = new NetAddress(WEKINATOR_HOST, WEKINATOR_INPUT_PORT);

  // This custom pipeline is the method that worked with the external camera.
  camera = new Capture(this,
    "pipeline:avfvideosrc device-index=" + CAMERA_INDEX);
  camera.start();
}

void draw() {
  readArduino();
  updateCamera();

  // Stop scanning if the camera stream disappears.
  if (scanning && millis() - lastCameraFrame > 2000) {
    stopNow();
    status = "Camera frames lost - stop requested";
  }

  // Keep the Arduino safety watchdog alive.
  if (ready && millis() - lastHeartbeat >= 500) {
    arduino.write('H');
    lastHeartbeat = millis();
  }

  // Probe the Arduino if its startup READY message was missed.
  if (!ready && millis() - openedAt > 2000 &&
      millis() - lastProbe > 1000) {
    arduino.write('?');
    lastProbe = millis();
  }

  // Only time out while still waiting in X state.
  // Once SCANNING or SHUFFLING is received, activeMode changes and this
  // timeout can no longer overwrite the acknowledged state.
  if (commandWaiting && activeMode == 'X' &&
      millis() - commandAt > 3000) {
    arduino.write('X');
    commandWaiting = false;
    scanning = false;
    activeMode = 'X';
    status = "No command acknowledgement - stop requested";
  }

  // Wekinator class 2 is translated into Arduino command T.
  if (scanning && targetPending && !targetSent) {
    targetPending = false;
    targetSent = true;
    arduino.write('T');
    status = "Class 2 detected - requesting three target pulses";
  }

  drawInterface();
}

void drawInterface() {
  background(30);

  fill(255);
  textSize(25);
  text("Card Machine - Three Target Pulses", 30, 25);

  textSize(18);
  text("S = Shuffle both motors", 30, 80);
  text("D = Scan: motor 1 ON " + DISPLAY_ON_TIME_MS +
       " ms / OFF " + DISPLAY_OFF_TIME_MS + " ms", 30, 115);
  text("X / Esc = Stop immediately", 30, 150);
  text("T = Simulate class 2 while scanning", 30, 185);

  textSize(16);
  text("Wekinator: " +
       (latestClass < 0 ? "Waiting" : str(latestClass)), 30, 235);
  text("Arduino: " + feedback, 30, 265);

  fill(100, 220, 150);
  text(status, 30, 300, 720, 55);

  if (cardFound) {
    fill(255, 220, 80);
    textSize(32);
    text("this is your card", 30, 365);
  }

  fill(255);
  textSize(16);
  text("External camera preview (index " + CAMERA_INDEX + ")", 800, 30);

  if (cameraFrames > 0) {
    image(camera, 800, 70, 380, 285);
  }

  text("Frames: " + cameraFrames +
       " | OSC sent: " + featureMessages, 800, 370);
  text("400 features -> Wekinator :" + WEKINATOR_INPUT_PORT, 800, 400);
  text("C = Confirm this is the external camera", 30, 420);
  text("Camera confirmed: " + cameraConfirmed, 800, 430);
}

void stopNow() {
  scanning = false;
  targetPending = false;
  targetSent = false;
  cardFound = false;
  commandWaiting = false;
  commandAt = 0;
  activeMode = 'X';

  arduino.write('X');
  status = "Stop requested - awaiting Arduino";
}

void keyPressed() {
  // Emergency software stop is never suppressed by key-repeat filtering.
  if (key == ESC) {
    key = 0;
    stopNow();
    return;
  }

  char command = Character.toUpperCase(key);

  if (command == 'X') {
    stopNow();
    return;
  }

  if (keyEvent.isAutoRepeat()) {
    return;
  }

  if (command == 'C') {
    cameraConfirmed = cameraFrames > 0;
    status = cameraConfirmed
      ? "Camera confirmed - use this same view for training and running"
      : "No camera frames yet";
    return;
  }

  if (command == 'T') {
    if (scanning && !targetSent) {
      targetPending = true;
    }
    return;
  }

  if (command != 'S' && command != 'D') {
    return;
  }

  if (command == 'D' &&
      (!cameraConfirmed || cameraFrames == 0 ||
       millis() - lastCameraFrame > 2000)) {
    status = "Confirm the live external camera with C before D";
    return;
  }

  if (!ready) {
    status = "Upload TWO_DC_NEXT_V1 and wait for Ready";
    return;
  }

  if (activeMode != 'X' || commandWaiting) {
    status = "Press X and wait for STOPPED before restarting";
    return;
  }

  scanning = false;
  targetPending = false;
  targetSent = false;
  cardFound = false;

  // Set the acknowledgement state BEFORE writing the command.
  // This removes the ordering problem in the previous version.
  commandWaiting = true;
  commandAt = millis();
  status = "Start requested";
  arduino.write(command);
}

void readArduino() {
  for (int i = 0; i < 1024 && arduino.available() > 0; i++) {
    char incoming = (char)arduino.read();

    if (incoming == '\r') {
      continue;
    }

    if (incoming == '\n') {
      handleFeedback(trim(serialLine));
      serialLine = "";
    } else if (serialLine.length() < 150) {
      serialLine += incoming;
    } else {
      serialLine = "";
    }
  }
}

void handleFeedback(String line) {
  if (line.length() == 0) {
    return;
  }

  feedback = line;
  println("Arduino: " + line);

  if (line.equals("READY TWO_DC_NEXT_V1")) {
    if (!ready) {
      ready = true;
      arduino.write('X');
      status = "Ready - click this window, then press S or D";
    }
  }
  else if (line.equals("SCANNING")) {
    activeMode = 'D';
    targetPending = false;
    targetSent = false;
    scanStarted = millis();
    scanning = true;
    commandWaiting = false;
    commandAt = 0;
    status = "Scanning - class 1 continues; class 2 starts target sequence";
  }
  else if (line.equals("SHUFFLING")) {
    activeMode = 'S';
    scanning = false;
    commandWaiting = false;
    commandAt = 0;
    status = "Shuffling";
  }
  else if (line.equals("TARGET_LATCHED")) {
    status = "Arduino accepted target - three full pulses will run";
  }
  else if (line.startsWith("TARGET_PULSE ")) {
    status = line;
  }
  else if (line.equals("TARGET_DONE")) {
    activeMode = 'X';
    scanning = false;
    targetPending = false;
    targetSent = false;
    commandWaiting = false;
    commandAt = 0;
    cardFound = true;
    status = "Final pulse completed; motor outputs disabled";
  }
  else if (line.equals("STOPPED") || line.startsWith("FAULT")) {
    activeMode = 'X';
    scanning = false;
    targetPending = false;
    targetSent = false;
    commandWaiting = false;
    commandAt = 0;
    cardFound = false;
    status = line;
  }
  else if (line.equals("BUSY")) {
    stopNow();
  }
}

void oscEvent(OscMessage message) {
  if (!message.checkAddrPattern("/wek/outputs")) {
    return;
  }

  int label;

  if (message.checkTypetag("f")) {
    float value = message.get(0).floatValue();

    if (abs(value - 1.0) < 0.01) {
      label = 1;
    } else if (abs(value - 2.0) < 0.01) {
      label = 2;
    } else {
      return;
    }
  }
  else if (message.checkTypetag("i")) {
    label = message.get(0).intValue();
  }
  else {
    return;
  }

  if (label != 1 && label != 2) {
    return;
  }

  latestClass = label;

  // Ignore a stale class 2 prediction during the first 300 ms of a scan.
  if (scanning && millis() - scanStarted >= 300 && label == 2) {
    targetPending = true;
  }
}

void updateCamera() {
  if (camera == null || !camera.available()) {
    return;
  }

  camera.read();
  camera.loadPixels();

  if (camera.width <= 0 || camera.height <= 0 ||
      camera.pixels.length < camera.width * camera.height) {
    return;
  }

  cameraFrames++;
  lastCameraFrame = millis();

  if (millis() - lastFeatures < FEATURE_INTERVAL_MS) {
    return;
  }

  OscMessage message = new OscMessage("/wek/inputs");

  for (int row = 0; row < ROWS; row++) {
    for (int col = 0; col < COLS; col++) {
      int x = constrain(
        int((col + 0.5) * camera.width / COLS),
        0, camera.width - 1);
      int y = constrain(
        int((row + 0.5) * camera.height / ROWS),
        0, camera.height - 1);

      message.add(brightness(camera.pixels[x + y * camera.width]));
    }
  }

  osc.send(message, wekinator);
  featureMessages++;
  lastFeatures = millis();
}
