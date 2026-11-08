# Debug and Iteration Log

This log covers the **two-DC prototype** using Arduino Uno R3, L293D,
Processing and Wekinator. It does not describe the separate stepper-motor or
servo experiments.

It summarises the team's development observations and the current source
code. Entries are grouped by problem, not presented as dated laboratory tests.
No measured accuracy, current readings or success rates are inferred from
qualitative observations.

## Status key

- **Resolved in the reported test:** the team reported that a specific test
  worked after the change; this is not a guarantee under every condition.
- **Implemented:** the change is present in the final code; quantitative
  or repeated hardware validation is not established by the code alone.
- **Open:** the issue remains, or the root cause has not been isolated.

## Current software baseline

| Item | Current setting |
|---|---|
| Serial baud rate | 9600 |
| Motor PWM in shuffle and scan | 255 |
| Normal scan pulse | 80 ms ON / 1000 ms OFF |
| Shuffle motor-start offset | Motor 2 starts 600 ms after motor 1 |
| Target transport | Three new complete pulses after detection |
| Heartbeat timeout | 3000 ms |
| Camera features | 20 x 20 brightness samples, 400 values |
| Feature-send interval | At least 100 ms between sends, when a new frame is available |
| Wekinator mapping | Class 1: ordinary card; class 2: fully black marker |

Source: [Arduino firmware](../arduino/TwoDC/TwoDC.ino) and
[Processing controller](../processing/ExternalCamera_Control_v2/ExternalCamera_Control_v2.pde).

## D01 - Camera listed but no video frames received

**Symptom:** Processing listed `Integrated Camera`, but its preview remained
blank and the frame counter stayed at zero. The console reported
`BaseSrc: [avfvideosrc0] : Internal data stream error.`

**Investigation:**
- A minimal camera-only sketch separated video capture from OSC and motor control.
- The same camera displayed an image in QuickTime.
- Selecting the device by name, using default capture settings, and explicitly
  requesting 640 x 480 at 30 or 15 fps did not resolve the reported failure.

**Change:** Use the custom capture string
`pipeline:avfvideosrc device-index=...` instead of the name-based constructor.
Keep the camera index editable and require the operator to confirm the preview
with `C` before scanning.

**Result / status:** **Resolved in the reported test.** The team confirmed that
the pipeline version displayed the camera image. The exact underlying capture
negotiation failure was not isolated. Device indices can change; this is a
configuration workaround, not proof that every camera or format will work.

**Evidence:** Development screenshots showed the zero-frame error; subsequent
success was reported by the operator. A dedicated camera-test recording is not
included in the repository.

## D02 - Motor direction did not match the required feed direction

**Symptom:** A motor rotated, but its direction did not match the mechanism.

**Investigation:** Compare the two direction outputs rather than treating
direction and PWM speed as the same parameter. A standalone pulse sketch and
an earlier integrated sketch used opposite direction settings.

**Change:** Adjust the direction-input pair to the required physical motion.
The final supplied firmware uses `LOW / HIGH` for motor 1 and `LOW / HIGH`
for motor 2.

**Result / status:** **Implemented.** The final source records the selected
settings. The mechanism's physical direction also depends on how each motor's
terminals are connected. Do not copy a historical HIGH/LOW setting from another
prototype without checking its wiring.

**Evidence:** Final firmware `setup()`; development discussion comparing the
standalone and integrated code.

## D03 - Slow-looking scan motion and pulse-duration tuning

**Symptom:** Scan mode appeared slower and less effective at feeding than
continuous shuffle mode, even when both used PWM 255.

**Investigation:**
- Separate PWM duty from the duration of each movement.
- Continuous shuffle gives the motor time to accelerate; scan mode repeatedly
  starts and stops it.
- The team compared this with a simple standalone test that used PWM 255,
  50 ms ON and 2000 ms OFF, and reported that this motion worked well.
- Direction settings differed between some test sketches, so those tests did
  not isolate timing as the only variable.

**Change:** Iterate the ON/OFF timings and use the supplied final firmware as
the documentation baseline: **80 ms ON, 1000 ms OFF, PWM 255**.
The standalone 50/2000 ms settings and intermediate settings are historical
trials, not the current configuration.

**Result / status:** **Implemented; empirical tuning remains mechanism-dependent.**
PWM 255 is already full duty. A short pulse and a continuously rotating motor
need not reach the same shaft speed. No measured speed or torque improvement
is claimed, and timing changes do not solve slip by themselves.

**Evidence:** Operator feedback on the standalone test and constants in the
final Arduino file.

## D04 - Interface status did not establish that a motor command had executed

**Symptom:** The operator reported that the Processing screen changed state
after `X`, while the motor did not appear to respond. In a separate direct
serial test, Arduino returned `SHUFFLING` but the motors did not rotate.

**Investigation:**
- Distinguish local interface text from a reply actually received from Arduino.
- Check the active window, serial-port ownership, baud rate and matching firmware.
- Direct serial testing established that a command could reach the Arduino;
  a state reply did not establish that the driver, supply or motor had worked.

**Change:** The current Processing controller reads Arduino replies. It sets
`commandWaiting` before writing a start command, clears the flag on
`SCANNING` or `SHUFFLING`, and handles a missing acknowledgement with a stop
request. The target message appears only after Arduino returns `TARGET_DONE`.

**Result / status:** **Resolved in the reported test.** The operator confirmed
that D04 was resolved. Improving Arduino feedback handling and command
acknowledgement addressed the interface/execution-state mismatch: Processing
sets the acknowledgement state before sending a start command and updates
the interface after receiving the Arduino response. Arduino replies confirm
program execution; they are not motor-motion sensor measurements.

**Evidence:** Operator confirmation that D04 is resolved, direct serial feedback
and `readArduino()` / `handleFeedback()` in the current Processing code.

## D05 - Thick stacks slipped instead of feeding

**Symptom:** With a thicker stack, the roller continued to rotate but the
bottom card did not advance reliably.

**Investigation:** The operator confirmed roller motion without corresponding
card motion, distinguishing this symptom from a completely stalled motor.
Possible checks discussed included sleeve-to-core slip, roller-to-card
traction, separator clearance and stack pressure. Their individual effects
were not established in a recorded controlled test.

**Change:** No definitive mechanical correction is recorded in this baseline.
Increasing PWM or pulse duration alone was not accepted as proof of a fix.

**Result / status:** **Open.** Reliable feeding with thicker stacks remains a
mechanical limitation. The exact source of slip or excessive resistance has
not been isolated.

**Evidence:** Operator observation; no before/after success-rate table is
included.

## D06 - One final pulse did not fully deliver the selected card

**Symptom:** Stopping after a single additional pulse could leave the selected
card only partly advanced.

**Investigation:** The team explained that the mechanism typically needs
approximately **three to five transport pulses** to move the next card fully
out. A pulse therefore cannot be treated as a card count.

**Change:** Set `TARGET_PULSE_COUNT = 3`. When `T` arrives, latch detection
once. Do not count an ON pulse already in progress; begin the target sequence
at the next OFF-to-ON transition. Decrement the count only as each target
pulse finishes. After the third, disable both motor outputs and send
`TARGET_DONE`.

**Result / status:** **Implemented; partial-delivery risk remains.** Three
pulses are the current fixed choice, not a guarantee, because the reported
transport range extends to five. Repeated class-2 predictions do not restart
the sequence once the target is latched.

**Evidence:** Operator explanation and the final Arduino target-sequence code.
See also [Why three target pulses?](../README.md#why-three-target-pulses).

## D07 - Staggering shuffle startup

**Symptom / context:** Earlier two-DC testing included a motor that could run
alone but hummed or failed to turn when both were requested together.
That observation alone did not establish the electrical cause.

**Change:** The final firmware starts motor 1 first, then starts motor 2
**600 ms later**. Its code comment identifies reducing simultaneous startup
demand as the intention. It also records the power-board bridge condition used
for this prototype.

**Result / status:** **Implemented; causal benefit not quantified.**
Staggering changes when startup demand occurs; it does not increase the
available supply capacity or prove that the original symptom was caused by
simultaneous startup current. Physical verification is still necessary.

**Evidence:** Earlier operator observations and
`SHUFFLE_STAGGER_MS` / the S-mode branch in the final firmware.

## D08 - Missing communication or camera frames during operation

**Risk addressed:** A running mode should not depend solely on the user
successfully closing a window or sending a manual stop command.

**Change:**
- Processing sends `H` approximately every 500 ms.
- Arduino disables both motor outputs if contact is absent for more than
  3000 ms during an active mode, reporting `FAULT LINK_TIMEOUT`.
- During scanning, Processing requests `X` if no fresh camera frame has been
  received for more than 2000 ms.
- `X` and `Esc` request a stop without waiting for the target pulse sequence.

**Result / status:** **Implemented; not a physical emergency-stop system.**
These protections have finite delays and do not prove that a motor actually
stopped. The final code does not stop normal D-mode pulses merely because
Wekinator stops sending classifications while camera frames and heartbeats
continue. A frozen or misleading classification stream is not equivalent to
a detected camera-frame failure.

**Evidence:** Camera-frame checks, heartbeat transmission and timeout branches
in the supplied source. No measured fault-response timing is reported here.

## Follow-up verification

Record actual results rather than assuming that implemented code has passed
a hardware test:

- Repeat normal feed and final three-pulse transport with several stack sizes.
- Check marker detection and false triggers using held-out camera examples.
- Verify that `X` stops output in S mode, D mode and the target sequence.
- Verify the heartbeat and camera-frame-loss responses in a controlled test.
- Add short videos, console captures and a results table to the relevant entries.

The simulator circuit and power-source representation are documented separately
in [Circuit Wiring and Power Supply](circuit-and-power.md).
