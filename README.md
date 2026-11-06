# -cps-card-magic
Cyber Physical Systems project: an interactive card magic machine using Arduino, Processing and Wekinator.

Cyber Physical Systems — Group 13
Team: Group 13

### 1. Project overview

Our project is a card shuffling machine that enables a participant to select a random playing card, have it lost in the pack, then the machine can successfully tell you what the card is. We chose this concept because magic is great and so is technology!

The intended interaction is:
1. The participant presses S on the computer keyboard
2. The machine then has both DC motors rotate the gearboxes, causing the cards to shuffle into the box
3. The participant takes the cards out and begins dealing the cards face down, they stop when they want and look at the card they just dealt. They place the rest of the cards on top. These cards are then placed on the right side of the machine.
4. The participant is instructed to press D on the computer keyboard
5. The right hand side motor deals the cards down 1 at a time, until it stops at their chosen card


The final prototype successfully demonstrated finding the final card. Its current limitations are it may not always accurately deal one at a time, and the camera recognition software is limited in training data

Evidence: [Overall photograph and demonstration video.]

### 2. Mechanical design

The mechanism consists of an existing commercial card shuffling machine from Amazon connected to an arduino with a breadboard. We chose this because of the time constraint of the project and ensuring the accuracy of dealing cards to the table.

We modified the supplied card shuffling machine by feeding the motor wiring to a breadboard connected to an L293D driver and an Arduino. This enabled the machine to be controlled and change the rate at which the motor would spin.

During development, cards weren't dealing from the gearbox. We changed the rate at which it would be dealt, which resulted in the cards dealing efficiently one by one.

Evidence to include:
- Labelled photograph of the complete mechanism.
- CAD, sketch or dimensions needed to understand the construction.

### 3. Hardware and power

Components:

| Component | Purpose | Why it was chosen |
|---|---|---|
| Arduino Uno | Receives commands from Processing and controls the motors through the motor driver. | Supports digital outputs and PWM for controlling motor direction, speed and timing. |
| [Camera model] | Captures images of playing cards for recognition. | Provides visual input without physical contact with the cards. |
| Two DC motors | Drive the card handling mechanism during shuffling and dealing. | Continuous rotation drives the rollers that move the cards. |
| L293D motor driver | Controls the DC motors using a separate motor supply. | Supports two DC motors with direction and speed control. |
| [Final power supply and voltage] | Powers the motors. | [Explain why it meets the motors' voltage and current requirements.] |
| USB connection | Powers the Arduino and provides serial communication with the computer. | Allows Processing to send commands to the Arduino. |
| Breadboard and jumper wires | Connect the circuit components. | Allow connections to be modified during prototyping. |

Connections:

The Arduino sends control signals to the L293D. The motors connect to the driver's outputs rather than directly to the Arduino pins.

The initial single-motor test used the following connections. These must be checked against the final circuit.

| Arduino pin | Connection | Function |
|---|---|---|
| 5 | L293D enable input for motor 1 | PWM speed control |
| 4 | L293D direction input for motor 1 | Direction control |
| 3 | L293D second direction input for motor 1 | Direction control |
| [Confirm pins] | L293D inputs and enable for motor 2 | Second motor control |
| GND | Common circuit ground | Shared reference for control signals |

[Add a labelled wiring diagram showing the final pin assignments, both motors, logic supply, motor supply and ground connections.]

Power Arrangement:

The Arduino is powered through its USB connection to the computer. The motors are powered by 5V through an L293D motor driver.

The Arduino provides control signals, while the motor supply provides the current required to drive the motors.

[Confirm the common ground connections between the Arduino, motor driver and motor supply. State how the L293D logic supply is connected.]

[Describe the precautions actually implemented, including polarity checks, protection against short circuits and disconnecting power before changing connections.]

**Hardware Development**

During initial testing, a motor moved the cards effectively when connected directly to a 9 V battery, but produced weaker movement through the L293D circuit.

We explored changes to the motor control code, including PWM settings and timed on/off operation. Possible contributing factors included voltage loss through the driver, battery limitations and mechanical resistance; these were not confirmed by measurement.

[Describe the final change and observed result, or explain the remaining limitation.]
[Arduino model]	[Role]	[Reason]
[Camera]	[Role]	[Reason]
[Motor/servo and quantity]	[Role]	[Reason]
[Motor driver]	[Role]	[Reason]
[Power supply]	[Role]	[Reason]


Connections: [Include a labelled wiring diagram and pin assignments.]

Power arrangement: [State the actual supply voltages, which components they power, grounding arrangement and precautions implemented. Explain how motors are powered and controlled.]

Hardware development: [Describe one significant issue, what you tried and the outcome.]

### 4. Software and communication

The software pipeline is:

Webcam → Wekinator → Processing → Arduino → Motor 1

Stage	What it receives and does	What it sends

Input program	[Camera data and feature extraction]	[Features, destination and protocol]
Wekinator	[Inputs and model task]	[Output labels/values and destination]
Processing	[Interprets output and controls sequence]	[Serial commands]
Arduino	[Reads commands]	[Motor/servo control signals]

Our additions to the supplied example code were [specific changes]. These enabled [behaviour].

Communication settings: [OSC addresses/ports, serial baud rate and command meanings.]

Source files: [Link every relevant sketch, input program and Wekinator project.]

### 5. Machine learning

Task: The model was trained to identify a black playing card amongst normal playing cards.

Inputs: [What numerical features enter Wekinator, how they are produced and how many there are.]

Outputs: [Classes or continuous outputs, including their meaning.]

Training data: We collected [number of examples per class or training recordings] under [lighting, camera position, card orientation and other conditions]. Training labels were assigned by [method].

Model choice: We used [actual model/algorithm] because [reason it suited the task].

Testing: We tested using [new examples not used for training and testing procedure]. We observed [actual results; give counts if recorded].

Limitations and improvements: The model struggled with [observed conditions]. Improvements could include [more varied training data] and [alternative model or input approach], because [expected benefit].

### 6. Testing and iteration

Test or problem	Change made	Observed result
[Mechanical issue]	[Change]	[Outcome]
[Hardware issue]	[Change]	[Outcome]
[Recognition issue]	[Change]	[Outcome]
[Complete interaction test]	[Change, if any]	[Outcome]

The final system can [confirmed capabilities]. Further development would focus on [highest-priority improvement].

### 7. Setup and operation

1. **Install the software.** Install Arduino IDE, Processing and Wekinator. In Processing, install the **oscP5** library for OSC communication. The **Serial** library provides communication with the Arduino. Record the software versions used in the final build: **[versions]**.

2. **Connect the hardware.** With the power disconnected, connect the two DC motors to the L293D motor driver using the wiring diagram in Section 3. Connect the Arduino to the computer by USB. Connect the power supply board to a power supply. Connect the external motor supply and ensure the Arduino and motor driver share a common ground. Connect the webcam via usb to the computer. Keep the card mechanism clear before switching on the motor power supply board.

3. **Upload the Arduino code.** Open **[Arduino sketch filename]** in Arduino IDE. Select **Arduino Uno** and its USB port under **Tools → Board** and **Tools → Port**, then upload the sketch. Close Serial Monitor before running Processing so that the serial port is available.

4. **Open the recognition and control programs.** Open the camera input program, the saved Wekinator project **[project name]**, and the Processing control sketch **[filename]**. Allow access to the camera if requested.

5. **Configure communication.** Set the Processing serial connection to the Arduino’s actual USB port and use a baud rate of **9600**, matching the Arduino sketch. Match the OSC ports and message addresses between the camera program, Wekinator and Processing. Use the input count and output settings saved with the trained Wekinator project. **[Add the final OSC ports, addresses and input/output counts here.]**

6. **Start the system.** After uploading the Arduino sketch, start the camera input program, open the trained Wekinator project, then run the Processing control sketch. Enable **Run** in Wekinator to send live predictions. Check that the camera image and recognition output respond before operating the motors.

7. **Operate the system.** Click the Processing window so that it receives keyboard input. The intended controls are:
   - **S:** run both motors to shuffle the cards.
   - **D:** start the dealing sequence.
   - **X:** stop both motors.

   Present cards clearly to the camera for recognition. **Verify these controls against the final code before submission.**

8. **Stop the system.** Press **X** and confirm that both motors stop. Disable **Run** in Wekinator, then stop the Processing and camera programs. Disconnect the external motor supply before adjusting the mechanism or wiring, then disconnect the Arduino USB cable.
Troubleshooting: [Two or three likely problems and their fixes.]

### 8. Credits and references

- Albert Phillips: 
- Junzhe (Christina) Ren: 
- Robbie Stevens: Adapted the existing card shuffling machine and developed the initial code to make the motors work.

- Adapted code/resources: [Links and what you used.]
