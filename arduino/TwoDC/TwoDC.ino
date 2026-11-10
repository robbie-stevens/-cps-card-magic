// Arduino Uno R3 + L293D + two DC motors
// Use with the yellow power-board bridge REMOVED.
//
// S mode:
//   Motor 1 starts immediately.
//   Motor 2 starts 600 ms later.
//   Both continue until X or link timeout.
//
// D mode:
//   Motor 1 ON 80 ms / OFF 1000 ms, repeated.
//   Motor 2 remains off.
//
// When T arrives (Wekinator class 2):
//   Do not count or extend the pulse currently in progress.
//   After it finishes, execute THREE new complete 80 ms pulses.
//   Stop after the third target pulse and send TARGET_DONE.

#include <LiquidCrystal.h>
// LCD: RS=D12, E=D11, LCD D4=D9, D5=D10, D6=D13, D7=D2.
LiquidCrystal lcd(12, 11, 9, 10, 13, 2);
bool thankYouPending = false;
unsigned long cardShownAt = 0;

void showLCD(char state) {
  thankYouPending = false;
  lcd.clear();
  lcd.setCursor(0, 0);
  switch (state) {
    case 'C':
      lcd.print(F("Enjoy the"));
      lcd.setCursor(0, 1); lcd.print(F("magic trick")); break;
    case 'S': lcd.print(F("shuffle")); break;
    case 'D': lcd.print(F("Wizadry")); break;
    case 'F':
      lcd.print(F("Your Card!"));
      cardShownAt = millis(); thankYouPending = true; break;
    case 'Y': lcd.print(F("Thank you!")); break;
    case 'X': lcd.print(F("Stopped")); break;
    default: lcd.print(F("Welcome!")); break;
  }
}

const int speedPin1 = 5;
const int dir1A = 4;
const int dir1B = 3;

const int speedPin2 = 6;
const int dir2A = 7;
const int dir2B = 8;

const int shuffleSpeed1 = 255;
const int shuffleSpeed2 = 255;
const int dealSpeed = 255;

const unsigned long SHUFFLE_STAGGER_MS = 600;
const unsigned long DEAL_ON_MS = 80;
const unsigned long DEAL_OFF_MS = 1000;
const unsigned long LINK_TIMEOUT_MS = 3000;

const byte TARGET_PULSE_COUNT = 3;

char mode = 'X';

bool shuffleMotor2Started = false;
bool pulseOn = false;
bool targetLatched = false;
bool targetSequenceStarted = false;

byte targetPulsesRemaining = 0;

unsigned long shuffleStarted = 0;
unsigned long lastChange = 0;
unsigned long lastContact = 0;

void motorOff() {
  analogWrite(speedPin1, 0);
  analogWrite(speedPin2, 0);
}

void stopAll() {
  motorOff();
  mode = 'X';
  shuffleMotor2Started = false;
  pulseOn = false;
  targetLatched = false;
  targetSequenceStarted = false;
  targetPulsesRemaining = 0;
}

void printReady() {
  // Keep the handshake expected by ExternalCamera_Control_v2.
  Serial.println(F("READY TWO_DC_NEXT_V1"));
}

void printTargetPulseProgress() {
  byte pulseNumber = TARGET_PULSE_COUNT - targetPulsesRemaining + 1;
  Serial.print(F("TARGET_PULSE "));
  Serial.print(pulseNumber);
  Serial.print('/');
  Serial.println(TARGET_PULSE_COUNT);
}

void setup() {
  pinMode(speedPin1, OUTPUT);
  pinMode(dir1A, OUTPUT);
  pinMode(dir1B, OUTPUT);

  pinMode(speedPin2, OUTPUT);
  pinMode(dir2A, OUTPUT);
  pinMode(dir2B, OUTPUT);

  stopAll();
  lcd.begin(16, 2);
  showLCD('R');

  // Motor 1 is the physical LEFT motor. Its direction has been reversed
  // from the previous firmware as requested.
  digitalWrite(dir1A, LOW);
  digitalWrite(dir1B, HIGH);

  // Motor 2 direction remains unchanged.
  digitalWrite(dir2A, LOW);
  digitalWrite(dir2B, HIGH);

  Serial.begin(9600);
  printReady();
  Serial.println(F("INFO NO_BRIDGE STAGGER_600MS TARGET_PULSES_3"));
}

void loop() {
  for (byte i = 0; i < 16 && Serial.available() > 0; i++) {
    char command = Serial.read();

    if (command == 'H') {
      lastContact = millis();
      Serial.print(F("PONG "));
      Serial.println(mode);
    }
    else if (command == '?') {
      printReady();
      Serial.println(F("INFO NO_BRIDGE STAGGER_600MS TARGET_PULSES_3"));
    }
    else if (command == 'X') {
      stopAll();
      showLCD('X');
      Serial.println(F("STOPPED"));
    }
    else if (command == 'C') {
      if (mode == 'X') showLCD('C');
    }
    else if (command == 'S' || command == 'D') {
      if (mode != 'X') {
        Serial.println(F("BUSY"));
        continue;
      }

      stopAll();
      lastContact = millis();
      mode = command;

      if (command == 'S') {
        shuffleStarted = millis();
        shuffleMotor2Started = false;

        // Start Motor 1 first to reduce simultaneous inrush current.
        analogWrite(speedPin1, shuffleSpeed1);
        analogWrite(speedPin2, 0);

        Serial.println(F("SHUFFLING"));
        showLCD('S');
        Serial.println(F("INFO SHUFFLE_MOTOR1_ON"));
      }
      else {
        // Start the ordinary D-mode pulse cycle.
        pulseOn = true;
        lastChange = millis();
        analogWrite(speedPin1, dealSpeed);
        analogWrite(speedPin2, 0);

        Serial.println(F("SCANNING"));
        showLCD('D');
      }
    }
    else if (command == 'T' && mode == 'D' && !targetLatched) {
      targetLatched = true;
      targetSequenceStarted = false;
      targetPulsesRemaining = TARGET_PULSE_COUNT;

      Serial.println(F("TARGET_LATCHED"));
      // The pulse currently in progress is deliberately not counted.
      // The target sequence begins at the next OFF -> ON transition.
    }
  }

  unsigned long now = millis();
  if (thankYouPending && now - cardShownAt >= 5000UL) showLCD('Y');

  if (mode != 'X' && now - lastContact > LINK_TIMEOUT_MS) {
    stopAll();
    showLCD('X');
    Serial.println(F("FAULT LINK_TIMEOUT"));
    return;
  }

  if (mode == 'S') {
    if (!shuffleMotor2Started &&
        now - shuffleStarted >= SHUFFLE_STAGGER_MS) {
      analogWrite(speedPin2, shuffleSpeed2);
      shuffleMotor2Started = true;
      Serial.println(F("INFO SHUFFLE_MOTOR2_ON"));
    }
    return;
  }

  if (mode != 'D') {
    return;
  }

  if (pulseOn && now - lastChange >= DEAL_ON_MS) {
    analogWrite(speedPin1, 0);
    pulseOn = false;
    lastChange = now;

    if (targetSequenceStarted && targetPulsesRemaining > 0) {
      targetPulsesRemaining--;

      if (targetPulsesRemaining == 0) {
        stopAll();
        showLCD('F');
        Serial.println(F("TARGET_DONE"));
      }
    }
  }
  else if (!pulseOn && now - lastChange >= DEAL_OFF_MS) {
    if (targetLatched && !targetSequenceStarted) {
      targetSequenceStarted = true;
    }

    pulseOn = true;
    lastChange = now;
    analogWrite(speedPin1, dealSpeed);

    if (targetSequenceStarted) {
      printTargetPulseProgress();
    }
  }
}
