# CPS Card Magic

Cyber Physical Systems — Group 13

An interactive card-magic prototype using an Arduino Uno R3, an L293D
motor driver, two DC motors, Processing, a camera and Wekinator. The machine
uses a fully black marker card as a positional reference for revealing a
participant's selected card, rather than identifying the selected card's rank
and suit.

## Project status

The current prototype can:

- run both motors in a staggered shuffle sequence;
- deal cards with timed pulses from the left motor;
- sample a live camera image into 400 brightness features;
- use a two-class Wekinator classifier to decide when the target has been
  detected;
- run three complete target pulses after detection, then stop; and
- stop automatically if Processing stops sending a heartbeat.

The classifier does **not** identify all 52 card ranks and suits. Class 1 means
an ordinary playing card; class 2 means the fully black marker card. The
controller uses detection of that marker to initiate the final transport
sequence intended to reveal the adjacent selected card.

## Repository structure

```text
arduino/TwoDC/TwoDC.ino
processing/ExternalCamera_Control_v2/ExternalCamera_Control_v2.pde
processing/ExternalCamera_Control_v2/sketch.properties
wekinator/WekinatorProject/WekinatorProject.wekproj
wekinator/WekinatorProject/inputConfig.xml
wekinator/WekinatorProject/outputConfig.xml
wekinator/WekinatorProject/current/currentData.arff
docs/debug-log.md
```

## Interaction

1. Start Arduino, Wekinator and the Processing sketch as described below.
   Confirm the correct live camera view by pressing `C`.
2. The participant loads the deck into the machine for the initial shuffle.
   Press `S`: motor 1 starts immediately and motor 2 starts 600 ms later.
   Press `X` to stop before removing the deck or changing modes.
3. Remove the shuffled deck and deal cards for selection. The participant
   indicates when to stop and chooses the card at that point. This selection
   interaction is separate from the final camera-scanning phase.
4. Before the selected card is returned, ensure that the fully black marker
   card is at the bottom of the remaining deck. Ask the participant to place
   their selected card at the very bottom, directly adjacent to the marker.
5. Invite the participant to cut the deck with the instruction:
   **"Please cut the deck."** This is the participant's post-selection action;
   the machine's interleaving shuffle is not run again at this stage.
6. Place the deck in the left-hand feed compartment. Press `D` to begin the
   recognition phase. Motor 1 runs for 80 ms and pauses for 1000 ms; motor 2
   remains off. The camera continuously supplies features to Wekinator as
   cards pass through the viewing area.
7. Class 1 leaves the timed feed cycle running. Class 2 identifies the fully
   black marker and latches the final transport sequence.
8. Arduino does not count a pulse already in progress as part of the final
   sequence. It runs three new complete 80 ms pulses, separated by the normal
   1000 ms pauses, then disables both motor outputs.
9. After Arduino returns `TARGET_DONE`, Processing displays
   **"this is your card"**. The final transport is intended to bring the
   participant's selected card to the reveal position.
10. Press `X` or `Esc` at any time to request an immediate stop.

`T` simulates a class-2 detection during scanning and is intended for testing.
The participant's request to stop during selection is a human interaction;
the software does not automatically detect a spoken stop request.

### Marker-card principle

The fully black marker is a reference card, not the participant's chosen card.
Placing the chosen card at the bottom of a deck whose bottom card is the
marker establishes their adjacency. Cutting relocates a block of cards while
preserving cyclic order; arbitrary interleaving shuffles do not preserve this
relationship. The participant-facing instruction is simply **"Please cut the
deck."**

The intended scanning order is to encounter the black marker before its
adjacent selected card. Wekinator only distinguishes **marker** from
**non-marker**. It does not recognise the selected card's identity or infer
adjacency from an image. The deck arrangement and physical feed order provide
that relationship; the software is not a general card-location system.

### Why three target pulses?

A motor pulse is a short transport action, **not a count of cards**. The team
reports that, in the current mechanism, advancing the next card fully out
typically takes approximately **three to five pulses**; one additional pulse
can leave the selected card only partly advanced.

The current firmware fixes `TARGET_PULSE_COUNT` at **3**, with each pulse
lasting **80 ms** at PWM **255**. These extra pulses are intended to complete
transport of the selected card following marker detection. They do not mean
that three additional cards should be dealt. The observed three-to-five-pulse
range is a qualitative operating observation, not a measured success rate;
the fixed three-pulse setting does not guarantee full delivery on every run.

## Hardware

### Components

| Component | Role |
|---|---|
| Arduino Uno R3 | Receives serial commands and controls the motor driver |
| L293D | Drives two DC motors from Arduino control signals |
| Two DC motors | Shuffle and deal cards |
| External camera | Captures the card area for classification |
| Computer | Runs Processing and Wekinator |
| School-provided power bank and power board | Supply the motor-power path |

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
The diagram documents the intended wiring; it is not a photograph or an
electrical measurement of the assembled prototype.

See [Circuit wiring and power-supply notes](docs/circuit-and-power.md) for the
L293D package-pin mapping, logic/motor-power separation and evidence status.

A labelled photograph of the actual power and common-ground wiring will
complement the simulator diagram.

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
| Class 1 | Ordinary playing cards / non-marker: continue scanning |
| Class 2 | Fully black marker card: latch the final transport sequence |

The included ARFF dataset contains 605 labelled recordings: 305 class-1
examples and 300 class-2 examples. The class definitions are ordinary playing
cards and the fully black marker card, respectively. The repository does not
contain an independent test set or measured accuracy. Before final submission,
record the lighting, camera position, training procedure and test results
using previously unseen examples.

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

## Debugging and iteration

The [Debug and Iteration Log](docs/debug-log.md) records the camera-capture
workaround, motor-direction and pulse tuning, acknowledgement handling,
feeding limitations, target transport and fault-handling changes. It separates
reported test outcomes from changes that are only established by source code.

## Known limitations and required evidence

- The camera classifier depends on the training view, lighting and card
  position.
- The motor mechanism may slip, jam or advance cards inconsistently. A pulse
  is not equivalent to one card; three final pulses may be insufficient when
  the next card needs more transport.
- The marker method depends on the prepared deck relationship, cutting rather
  than interleaving after selection, and the physical scanning order.
- Classification uses image brightness, so non-marker dark scenes or backgrounds
  may be confused with the black marker; robustness has not been quantified.
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
