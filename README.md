# CPS Card Magic

Cyber Physical Systems — Group 13

An interactive card-handling prototype using an Arduino Uno R3, an L293D
motor driver, two DC motors, Processing, a camera and Wekinator.

## Project status

The current prototype can:

- run both motors in a staggered shuffle sequence;
- deal cards with timed pulses from the left motor;
- sample a live camera image into 400 brightness features;
- use a two-class Wekinator classifier to decide when the target has been
  detected;
- run three complete target pulses after detection, then stop; and
- stop automatically if Processing stops sending a heartbeat.

The classifier does **not** identify all 52 card ranks and suits. In the current
software, class 1 means continue scanning and class 2 means the target has been
detected. The team should document how the physical target card or marker is
prepared before final submission.

## Repository structure

```text
arduino/TwoDC/TwoDC.ino
processing/ExternalCamera_Control_v2/ExternalCamera_Control_v2.pde
processing/ExternalCamera_Control_v2/sketch.properties
wekinator/WekinatorProject/WekinatorProject.wekproj
wekinator/WekinatorProject/inputConfig.xml
wekinator/WekinatorProject/outputConfig.xml
wekinator/WekinatorProject/current/currentData.arff
```

## Interaction

1. Start Arduino, Wekinator and the Processing sketch as described below.
2. Confirm the correct live camera view by pressing `C` in Processing.
3. Press `S` to start shuffling. Motor 1 starts immediately and motor 2 starts
   600 ms later. Press `X` before beginning another mode.
4. After the participant has selected and replaced the card, move the pack to
   the dealing side of the machine.
5. Press `D` to scan and deal. Motor 1 runs for 80 ms and pauses for 1000 ms.
6. When Wekinator outputs class 2, Arduino completes the pulse already in
   progress without counting it, then runs three new complete 80 ms pulses and
   stops.
7. Press `X` or `Esc` at any time to request an immediate stop.

`T` simulates a class-2 detection during scanning and is intended for testing.

## Hardware

### Components

| Component | Role |
|---|---|
| Arduino Uno R3 | Receives serial commands and controls the motor driver |
| L293D | Drives two DC motors from Arduino control signals |
| Two DC motors | Shuffle and deal cards |
| External camera | Captures the card area for classification |
| Computer | Runs Processing and Wekinator |
| School-provided power bank and power board | Supply the motor-power path; exact output ratings remain to be confirmed |

### Arduino pin assignments

| Arduino pin | Connection | Function |
|---|---|---|
| 5 | L293D enable for motor 1 | PWM speed control |
| 4 | L293D input 1 for motor 1 | Direction control |
| 3 | L293D input 2 for motor 1 | Direction control |
| 6 | L293D enable for motor 2 | PWM speed control |
| 7 | L293D input 1 for motor 2 | Direction control |
| 8 | L293D input 2 for motor 2 | Direction control |
| GND | Arduino, L293D and motor-supply ground | Common reference |

Motor 1 is identified in the firmware as the physical left motor. Both motors
currently use full PWM (`255`). The yellow power-board bridge must be removed,
as noted in the firmware comments.

### Circuit diagram and power supply

![Simulator wiring diagram for the two-DC prototype](docs/images/two-dc-circuit.png)

**Simulation placeholder:** The 9 V battery shown in the simulator represents
the school-provided power bank and power board, which were unavailable in the
simulator's component library. It is not the power source used in the physical
prototype, does not establish its actual supply voltage, and is not a
recommendation to power the motors from a 9 V battery.

The physical prototype uses a school-provided power bank and power board.
Their make/model, output voltage and current rating have not yet been supplied.
The diagram documents the intended wiring; it is not a photograph or an
electrical measurement of the assembled prototype.

See [Circuit wiring and power-supply notes](docs/circuit-and-power.md) for the
L293D package-pin mapping, logic/motor-power separation and evidence status.

Still to confirm before final submission:

- the camera make and model;
- motor part numbers and rated voltage;
- power-bank and power-board output ratings; and
- a labelled photograph confirming the actual power and common-ground wiring.

## Software and communication

```text
Camera
  -> Processing: 20 x 20 brightness samples every 100 ms
  -> Wekinator: OSC /wek/inputs, UDP port 6448, 400 floats
  -> Processing: OSC /wek/outputs, UDP port 12000, class 1 or 2
  -> Arduino: 9600-baud serial commands
  -> L293D and two DC motors
```

### Serial protocol

| Command | Meaning |
|---|---|
| `S` | Start staggered two-motor shuffle |
| `D` | Start pulsed deal/scan mode |
| `T` | Latch target detection while scanning |
| `X` | Stop both motors and reset state |
| `H` | Processing heartbeat |
| `?` | Request the Arduino ready message |

The Arduino stops both motors if it receives no heartbeat for 3000 ms while a
mode is active. It reports state using messages including `READY`, `SHUFFLING`,
`SCANNING`, `TARGET_LATCHED`, `TARGET_PULSE`, `TARGET_DONE`, `STOPPED`, `BUSY`
and `FAULT LINK_TIMEOUT`.

## Machine learning

Processing samples the brightness at the centre of each cell in a 20 by 20
grid, producing 400 numeric inputs. It sends a new feature vector every 100 ms.

The included Wekinator project is configured as a two-class classification
task:

| Output | Behaviour in the controller |
|---|---|
| Class 1 | Continue scanning |
| Class 2 | Notify Arduino that the target was detected |

The included ARFF dataset contains 605 labelled recordings: 305 class-1
examples and 300 class-2 examples. The repository does not contain an
independent test set or measured accuracy. Before final submission, record the
lighting, camera position, target-card definition, training procedure and a
test result using previously unseen examples.

## Setup

### 1. Arduino

1. Open `arduino/TwoDC/TwoDC.ino` in Arduino IDE.
2. Select **Arduino Uno** and the correct USB port.
3. Confirm that the wiring matches the pin table and that the power-board bridge
   is removed.
4. Upload the sketch and close Serial Monitor.

### 2. Processing

Install the Processing **Video**, **oscP5** and **Serial** libraries.

Open
`processing/ExternalCamera_Control_v2/ExternalCamera_Control_v2.pde`, then edit
these user settings if required:

```java
final String ARDUINO_PORT = "/dev/cu.usbmodem11201";
final int CAMERA_INDEX = 1;
```

`ARDUINO_PORT` is specific to the computer and USB connection. Run the sketch
once and use the printed `Serial.list()` output to find the correct value. If
the preview shows the wrong camera, change `CAMERA_INDEX`.

The camera capture string uses macOS AVFoundation. A different capture
configuration may be required on Windows or Linux.

### 3. Wekinator

1. Open `wekinator/WekinatorProject/WekinatorProject.wekproj`.
2. Confirm 400 inputs on `/wek/inputs`, receiving on port 6448.
3. Confirm one two-class output on `/wek/outputs`, sent to port 12000.
4. Train the model from the included data if the saved model is not available.
5. Enable **Run** so predictions are sent to Processing.

### 4. Run and stop

Start Wekinator, then run Processing. Wait for the Arduino ready message and a
live camera preview. Press `C` to confirm the camera before using `D`.

To shut down, press `X`, disable Wekinator Run, stop Processing, disconnect the
external motor supply, and then disconnect Arduino USB.

## Known limitations and required evidence

- The camera classifier depends on the training view, lighting and card
  position.
- The motor mechanism may not always release exactly one card per pulse.
- The serial port and camera index are currently configured manually.
- The dataset is balanced, but no held-out accuracy measurement is included.
- A simulator wiring diagram is included; a labelled physical mechanism/wiring
  photograph, demonstration video and short table of mechanical, electrical and
  recognition tests are still required.

## Credits and references

- Albert Phillips — contribution to be completed by the team.
- Junzhe (Christina) Ren — contribution to be completed by the team.
- Robbie Stevens — adapted the commercial card-shuffling mechanism and
  developed the initial motor-control code.

Add links and licences for any adapted code, hardware designs, libraries and
external references before final submission.
