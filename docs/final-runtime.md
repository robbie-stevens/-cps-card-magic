# Current runtime guide — 10 November 2026

## Authoritative files

- [Arduino source](../arduino/TwoDC/TwoDC.ino): supplied 1110ArduinoNew.ino, stored under the existing repository sketch name.
- [Processing source](../processing/ExternalCamera_Control_v2/ExternalCamera_Control_v2.pde): supplied sketch_1110Processing_New.pde, stored under the existing repository sketch name.
- [Wekinator project](../wekinator/WekinatorProject/WekinatorProject.wekproj): supplied 1110WekinatorNew/WekinatorProject, including all five project, configuration, training and model files.

All seven supplied files are retained byte-for-byte. This update does not establish successful compilation or physical verification. Download the current repository with Code → Download ZIP. Earlier packages are isolated under [Historical resources](history/README.md) and are not current runtime downloads.

## Startup

1. Upload TwoDC.ino to the Uno R3 and close Serial Monitor. The same Uno controls both DC motors and the LCD.
2. Keep the complete WekinatorProject directory together and open WekinatorProject.wekproj.
3. Install Processing Video and oscP5; Serial is bundled. Check ARDUINO_PORT (supplied value /dev/cu.usbmodem21201).
4. Check CAMERA_INDEX (supplied value 1). This is an AVFoundation numeric index, NOT a permanent webcam binding. Confirm the actual live preview after reconnecting devices.
5. Run Processing, wait for Connected and STOPPED, then press C. Click Run in Wekinator.

## Controls and detection

| Key | Action |
|---|---|
| C | Confirm camera; when stopped, display Enjoy the / magic trick on LCD |
| S | Start motor 1, then motor 2 after 600 ms; continuous shuffling |
| D | Motor 1 ON 80 ms / OFF 1000 ms; motor 2 off; LCD Wizadry |
| X / Esc | Request stop; wait for STOPPED before restarting |
| R | Request stop and reopen serial; never resume motion automatically |

There is no keyboard T simulation. During D, detection first requires at least 3 consecutive class-1 results over 200 ms. Once armed, class 2 requires at least 5 consecutive results over 400 ms; class 1 or a prediction gap above 250 ms resets a marker candidate. A stable but incorrect class-2 prediction can still trigger the machine.

After a confirmed marker, Processing sends internal serial T once. Arduino excludes the current pulse, executes three new complete 80 ms pulses separated by 1000 ms, stops and returns TARGET_DONE. Only then does Processing show this is your card. LCD shows Your Card!, then Thank you! after 5 seconds. Three pulses represent feed distance, not three cards.

## Pins

Motor 1: PWM D5, direction D4/D3. Motor 2: PWM D6, direction D7/D8. LCD: RS D12, E D11, D4 D9, D5 D10, D6 D13, D7 D2. Preserve the verified LCD power, contrast and RW wiring as well as motor-driver power wiring.

## Communication and recovery

Serial is 9600 baud. The serial worker sends H every 500 ms; Arduino replies PONG plus its current mode. Processing requests a stop and reconnects after 2 seconds without valid board replies. The board retains its 3-second contact watchdog. A main control-loop stall above 2.5 seconds also requests a stop. Restoring a connection requires confirmed STOPPED and a new S/D command. Software reconnection does not repair supply, driver, USB or wiring faults, and is not a physical emergency stop.

Camera frames are sampled as 400 brightness values every 100 ms, sent to /wek/inputs on port 6448. Wekinator sends one classification output to localhost:12000 at /wek/outputs. Class 1 is ordinary cards; class 2 is the black marker. The supplied kNN model uses k=1. currentData.arff contains 5,005 training vectors (2,313 class 1 and 2,692 class 2); these are not independent evaluation trials.
