# Final runtime guide

## Files

- [Arduino source](../arduino/TwoDC/TwoDC.ino)
- [Processing source](../processing/ExternalCamera_Control_v2/ExternalCamera_Control_v2.pde)
- [Wekinator project](../wekinator/WekinatorProject/WekinatorProject.wekproj)
- [Saved model](../wekinator/WekinatorProject/current/models/model0.xml)
- [Complete English report and source package](downloads/CardMagic_Final_Delivery.zip)

The supplied final source is retained without behavioural edits. Extract the complete package to use the Word report's relative source hyperlinks. GitHub links on this page open the repository files directly.

## Startup

1. Upload TwoDC.ino to Arduino Uno R3. Close Serial Monitor.
2. Open the Wekinator project, keeping its inputConfig.xml, outputConfig.xml and current folder together.
3. In Processing, install Video and oscP5; Serial is bundled. Set ARDUINO_PORT to the actual USB port and verify CAMERA_INDEX (currently 1).
4. Run the Processing sketch. Wait for READY and live camera frames, then press C to confirm the camera.
5. Click Run in Wekinator. Focus Processing before using keyboard commands.

## Controls

| Key | Action |
|---|---|
| S | Start motor 1 immediately and motor 2 after 600 ms; both continue |
| D | Motor 1 runs 80 ms on and 1000 ms off; motor 2 remains off |
| X or Esc | Stop and clear the current sequence |
| C | Confirm the live camera |
| T | Simulate class 2 during scanning |

Press X and wait for STOPPED before switching modes. Class 1 continues feeding. Class 2 sends T once: Arduino finishes any current pulse without counting it, then executes three new complete 80 ms pulses and returns TARGET_DONE. Processing then displays "this is your card". Three pulses are feeding distance, not three cards.

## Communication

Serial is 9600 baud. Processing samples 400 brightness values every 100 ms and sends /wek/inputs to port 6448. Wekinator sends one classification output to localhost:12000 at /wek/outputs. Class 1 is ordinary cards; class 2 is the black marker. Heartbeats are sent every 500 ms; Arduino stops after 3000 ms without contact. Scanning requests a stop after 2000 ms without camera frames.

## Interface wording

Some Processing messages still say "final pulse" and include an older FINAL_PULSE handler. Arduino sends TARGET_PULSE 1/3, 2/3 and 3/3, then TARGET_DONE. The actual sequence has three pulses. The saved source is not silently changed to match these older display strings.

No physical hardware test was performed as part of this repository update.
