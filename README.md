# Card Magic An Interactive Machine Learning Card Machine

## Files and navigation

- [Complete machine models and structural drawings](mechanical/full-machine/README.md)

- [Mechanical STL models and model notes](mechanical/models/README.md)

- [Final Arduino source](arduino/TwoDC/TwoDC.ino)
- [Final Processing source](processing/ExternalCamera_Control_v2/ExternalCamera_Control_v2.pde)
- [Wekinator project](wekinator/WekinatorProject/WekinatorProject.wekproj)
- [Runtime quick guide](docs/final-runtime.md)
- [Download current source and resources](https://github.com/robbie-stevens/-cps-card-magic/archive/refs/heads/main.zip)
- [Physical object and construction](#14-physical-object-and-construction)
- [Mechanical design](#2-mechanical-design)
- [Hardware design](#3-hardware-design)
- [Software design](#4-software-design)
- [Machine learning](#5-machine-learning-design-and-training)
- [Debugging and iteration](#6-debugging-and-iteration)
- [Limitations](#7-limitations)
- [Installation and operation](#8-software-installation-and-operation)

> **Current runtime:** One Arduino Uno R3 controls the two DC motors and the 1602 LCD. Processing handles camera capture, Wekinator classification results, keyboard input and serial communication. Use the linked current source files or download the main branch, following the [runtime guide](docs/final-runtime.md). Earlier packages are isolated in the historical archive.

## 1 Project Overview

Card Magic is an interactive card magic installation combining mechanical feeding, computer vision and machine learning. Two DC motors provide shuffling and intermittent card feeding. A camera captures images, and Wekinator detects an all-black marker card. The machine locates the user’s selected card through its adjacency to the marker card.

The project does not attempt to recognise all 52 playing cards. After detecting the marker, the system performs additional feeding to deliver the selected card and displays “this is your card” on the computer.

| Key | Mode | Action |
| --- | --- | --- |
| S | Shuffle | Both motors run continuously, feeding both stacks towards the centre |
| D | Recognition | Only the left motor feeds intermittently; the camera and Wekinator perform recognition |
| X | Stop | Stop both motors and end the current run |

### 1.1 Design Objectives and User Experience

The objectives are to make a conventional shuffling mechanism computer-controlled; combine continuous shuffling and intermittent recognition in one system; support the trick through binary classification rather than full card identification; connect machine learning results to actuators in real time; and establish a repeatable selection, cutting and reveal sequence.

The interaction consists of shuffling, selection and revelation. The user watches the machine shuffle, selects a card, returns it and cuts the deck, then watches the machine locate it. Machine learning detects only the marker, not the identity of the selected card. This division reduces training work and hides the technical process within a simple magic interaction.

Ordinary cards share similar backgrounds, layouts and suit features; the all-black card has a more distinct overall brightness. The final model assigns ordinary cards to class 1 and the all-black marker to class 2. Class 1 maintains feeding. Class 2 latches the detection event, after which the machine completes its final feeding sequence and stops.

### 1.2 Complete User Journey

1. Divide the deck into two stacks and place them in the left and right hoppers.

2. Press S to shuffle. When finished, press X, remove the cards and square the deck.

3. Arrange the order so that the all-black marker will be at the bottom of the remaining deck after card selection.

4. Deal cards and let the user call stop at their chosen point to select a card.

5. Ask the user to place the selected card at the bottom of the remaining deck, adjacent to the marker.

6. Ask the user to “cut the deck”.

7. Place the entire deck in the left hopper, check the camera image and press D.

8. The left motor feeds intermittently while the camera continuously captures images.

9. Wekinator outputs class 2, and the system records the marker event.

10. Beginning with the next complete feeding pulse, execute three additional pulses, then stop.

11. Arduino returns TARGET_DONE, and the computer displays “this is your card”.

The method depends on adjacency and the actual feeding direction. After selection, the user cuts the deck rather than interleaving the cards in another shuffle.

### 1.3 Materials Fabrication and Aesthetic Expression

Card Magic combines the familiar form of a card shuffler with hidden visual recognition. Symmetrical loading areas and a central collection space make it clear where cards enter and are retrieved. Behind this familiar operation, the camera, classification software and motor control produce the effect of finding the user’s card. The appearance and structure present a complex technical process as a clear, coherent magic experience.

A compact gear train transfers motor motion to the feeding mechanism. Repeated structures on the two sides create visual order and reflect their shared role during shuffling. Recognition uses the same loading and transport structure, avoiding an additional mechanical operation for the user to learn.

The enclosure does more than cover the mechanism: it organises visual information by separating circuitry and wiring from the user’s operating area. Attention is directed towards card entry, movement and the final reveal. Concealing the internal control process also strengthens the impression that the machine somehow knows the user’s selection.

Fabrication combines mechanical assembly, enclosure construction and programmable control. The structure and controls are tested separately before integration, allowing feeding rhythm to support camera recognition and revelation. Continuous movement during shuffling contrasts with intermittent feeding during recognition, distinguishing the functions and creating a progression from preparation through anticipation to the reveal.

The aesthetic expression therefore comes not only from static appearance, but also from spatial arrangement, the concealment of technology, and the coordination of movement with on-screen feedback. Materials and fabrication serve the central concept: turning machine learning and physical control into a participatory card magic experience that creates surprise.

### 1.4 Physical Object and Construction

![Final assembled Card Magic machine, front view](docs/images/physical-object/final-assembled-machine.jpg)

Figure P0. Final assembled physical object. The front view shows the black base and paired card-loading areas, the central collection opening, and the rounded white enclosure with the integrated 1602 LCD displaying “Stopped”. The closed enclosure conceals the wiring shown in the construction photographs below.

The photographs below document the physical prototype and its construction. The black printed base provides mounting areas for the card-feeding mechanisms and electronics, bringing the mechanical and control components together in one assembly.

![Updated physical wiring with the Uno, Power Board, two DC motors, camera and LCD](docs/images/physical-object/assembled-wiring.jpg)

Figure P1 Updated physical circuit integration during construction. The open black base exposes the Uno controller, breadboard, school-supplied Power Board, jumper wiring and two DC motor-driven gear modules. The white enclosure carries the camera and the connected 1602 LCD, shown displaying “Thank you!”. This photograph records the assembly and wiring layout with the card-loading structure removed for access.

![Construction-stage assembly showing two DC motors, gear modules and the electronics compartment](docs/images/physical-object/construction-stage.jpg)

Figure P2 Construction-stage view with the outer shuffling structure removed. Two DC motors and their gear modules are positioned in the printed base, beside the breadboard and Power Board. This view records component mounting and wiring during assembly rather than a fully enclosed finished object.

![Physical construction with the camera mounted in the white enclosure above the card shuffler](docs/images/physical-object/enclosure-camera-assembly.jpg)

Figure P3 Physical construction with the white enclosure and camera installed above the card-shuffling unit. The open base shows the Uno controller, breadboard, Power Board and wiring during integration. The upper rectangular opening is visible above the camera.

## 2 Mechanical Design

### 2.1 Overall Structure and Modifications

The final prototype uses two DC motors, each driving a separate gear module. The left hopper holds part of the deck during shuffling and the full deck during recognition; the right hopper is used for shuffling. Rollers and pushing components move cards towards the central drop area. The camera observes the recognition area, while the enclosure houses the mechanism and circuitry.

Modifications include programmable motor control, continuous and intermittent operation, computer communication, camera and machine learning integration, and a rebuilt enclosure. The focus is to incorporate the feeding action into a software-coordinated interaction.

### 2.2 Single Side Gearbox and Components

The two gearboxes are mirrored about the machine’s centre plane. Each is driven by one DC motor, with gears supported by three steel shafts between two plastic side plates. The complete machine contains two motors, six main gear components, six steel shafts and four side plates.

| ID | Component | Structure and function | Total quantity |
| --- | --- | --- | --- |
| M / Z0 | Motor and pinion | 8-tooth motor pinion enters the gearbox through a side-plate opening | 2 |
| C | Compound gear | 43-tooth Z1 and 11-tooth Z2 integrated with the sector pusher | 2 |
| B | Idler gear | 60 teeth; connects the compound gear to the feed-roller pinion | 2 |
| A / Z4 | Feed roller | 10-tooth pinion connected to a straight-knurled roller body for friction feeding | 2 |
| S | Steel shaft | 2 mm diameter; both ends supported in side-plate holes | 6 |
| P1-L / P1-R | Motor side plates | Motor mounting, location of three shafts and fixing posts | 1 each |
| P2-L / P2-R | Outer side plates | Support and enclose each module with its motor side plate | 1 each |

Figures M1 and M2 were generated from the supplied single-side STL models and show the internal gear layout and complete assembly. The model includes feed roller A, idler gear B, compound gear C, two support plates, steel shafts and a motor envelope reference.

![Report figure 1](docs/images/final-report/figure-01.png)

Figure M1 Single-side gear module with the outer plate removed to show the internal transmission.

![Report figure 2](docs/images/final-report/figure-02.png)

Figure M2 Complete single-side gear module. Colours distinguish components; the motor is an envelope reference.

### 2.3 Power Path and Three Layer Layout

Motor pinion Z0 drives Z1 on compound gear C. At C, power follows two paths: one rotates the coaxial sector-shaped pusher; the other drives feed roller A through Z2, idler gear B and Z4.

Power path: motor Z0 → Z1 on C; Z2 on C → B → Z4 on A. The sector pusher rotates with C.

![Report figure 3](docs/images/final-report/figure-03.png)

Figure M3 Power branching diagram from the supplementary mechanical report.

| Axial layer | Components | Function |
| --- | --- | --- |
| Layer 1 near P1 | Z0 and Z1 | Motor input and first reduction stage |
| Layer 2 | Z2, B and Z4 | Transfer motion to the feed roller |
| Layer 3 | Sector pusher and roller body | Push and friction-feed cards |

Z1, Z2, the hub and the sector pusher form one integral component C, with no relative rotation between them. The supplementary report labels the sector Z3 and records 18 fine teeth along its 90° arc. This arc does not mesh with another gear; it projects beyond the housing during rotation to help push cards. The rim of feed roller A extends beyond the side plate outline and contacts cards through its knurled surface.

### 2.4 Reduction Ratios and Rotation Directions

The following tooth counts and dimensions are recorded in the supplementary report. The overall reduction ratio to the feed roller is:

iA = (43 ÷ 8) × (60 ÷ 11) × (10 ÷ 60) = 4.89

The tooth count of idler B cancels from the overall ratio. Its main functions are to transfer motion, bridge the shaft spacing and change rotation direction. The sector rotates with Z1, giving a reduction ratio of:

iC = 43 ÷ 8 = 5.38

| Stage | Driver and driven gear | Teeth | Reduction ratio |
| --- | --- | --- | --- |
| 1 | Z0 → Z1 | 8 → 43 | 5.38 |
| 2 | Z2 → B | 11 → 60 | 5.45 |
| 3 | B → Z4 | 60 → 10 | 0.17 speed-increasing stage |
| Motor to feed roller | Three stages combined | — | 4.89 |
| Motor to sector | Coaxial with Z1 | — | 5.38 |

Viewed from the motor side, clockwise motor rotation produces anticlockwise rotation of the compound gear and sector, clockwise rotation of idler B, and anticlockwise rotation of feed roller A. The roller and sector therefore rotate in the same direction.

The report derives a module of 0.6 from the outside diameters and tooth counts. Z1 has 43 teeth and a 27 mm outside diameter, giving m = 27 ÷ (43 + 2) = 0.6. The recorded outside diameter of Z4 is 8 mm, greater than the standard 7.2 mm for a 10-tooth, module 0.6 gear. The report suggests positive profile shift as an explanation; the tooth profile should be checked before replacing or manufacturing this pinion.

| Shaft pair | Nominal centre distance from module and tooth counts |
| --- | --- |
| Motor and C | 15.3 mm |
| C and B | 21.3 mm |
| B and A | 21.0 mm |

These centre distances are nominal calculated values from the report. Profile corrections and actual mounting-hole distances should be checked against the drawings when replacing gears.

### 2.5 Mirrored Layout and Coordination

The left and right modules use the same A, B and C gear structures with mirrored side plates. Their rotation directions must correspond to the mirrored layout so that both feed towards the centre. Two independent drive channels control the actual directions.

DC motor speed varies with load and manufacturing differences. Equal PWM settings do not imply exact mechanical phase synchronisation. The current prototype uses time-based control without position feedback or phase synchronisation.

![Report figure 4](docs/images/final-report/figure-04.png)

Figure M4 Mirrored modules and central card drop area from the supplementary mechanical report.

### 2.6 Support and Assembly

The report specifies 2 mm steel shafts and a 16.5 mm internal spacing between the side plates. Plastic shaft holes support both ends as plain bearings. Hub end faces and support bosses restrict axial movement. There are no rolling bearings or circlips. The motor mounts outside P1; its fixing-hole spacing is recorded as 9 mm.

Assembly sequence:

1. Fix the motor outside P1 with Z0 projecting into the gearbox.

2. Place P1 inner face upwards and install compound gear C so that Z1 meshes with Z0.

3. Install idler B so that it meshes with Z2.

4. Install feed roller A so that Z4 meshes with B and its rim extends beyond the plate outline.

5. Align P2 with the opposite ends of the three shafts, close the plates and secure them.

6. Turn the roller by hand to check smooth gear and sector motion and clearance from the plates.

7. Assemble the other side using mirrored plates and check its actual feeding direction.

### 2.7 Feeding Rhythm and Final Pulses

Shuffling uses continuous drive. During recognition, the left motor runs for 80 ms and stops for 1000 ms, providing time for image capture and classification.

Practical testing showed that one additional pulse was insufficient to deliver the next card completely; three to five pulses were sometimes needed. The current configuration does not extend the pulse already in progress after detection. Instead, it executes three complete pulses beginning with the next pulse, then stops. These pulses provide feeding distance, not a count of three cards.

Card displacement depends on friction, stack thickness, roller contact and resistance. A fixed duration does not correspond to a fixed number of cards.

### 2.8 Design Features and Mechanical Risks

Two side plates support three shafts in a compact multilayer layout. The compound gear integrates the input gear, pinion and pusher, reducing separate parts. Recesses in the idler reduce its mass, and the projecting roller contacts cards directly.

Risks include wear in plastic shaft holes, friction and backlash from additional gear meshes, phase drift between motors, and slipping under thick stacks. The sector’s stopping position depends on when the motor stops; position sensing could improve this in future.

### 2.9 Drawing Notes

The drawings below combine five updated CM component sheets with two explicit GX right-hand plate drawings. All dimensions are in millimetres and use first-angle projection. Parenthesized dimensions retain the source's photographic-reference notation. Screen or page scaling is not a manufacturing scale.

| Figure | Drawing | Component |
| --- | --- | --- |
| 5 | CM-P08 | Feed roller A |
| 6 | CM-P07 | Idler gear B |
| 7 | CM-P06 | Compound gear C |
| 8 | CM-P04 | Motor side plate P1; opposite side mirrored |
| 9 | CM-P05 | Outer side plate P2; opposite side mirrored |
| 10 | GX-06 | Explicit right-hand motor side plate P1-R |
| 11 | GX-07 | Explicit right-hand outer side plate P2-R |

### 2.10 Mechanical Component Engineering Drawings

The complete [19-page structural component drawing document](mechanical/full-machine/Card-Shuffler-Structure-Drawings.pdf) includes the general assembly, exploded view, component lists, base layout, structural description and individual part drawings. Selected sheets are reproduced below with their dimensions and technical notes. Page scaling does not preserve the original print scale; use the stated dimensions for manufacturing.

#### CM-P08 Feed Roller A

![CM-P08 Feed Roller A, structural drawing sheet 18](docs/images/final-report/figure-05.png)

Source: complete structural drawing document, page 18. Dimensions in mm; parenthesized dimensions retain the source reference notation.

#### CM-P07 Idler Gear B

![CM-P07 Idler Gear B, structural drawing sheet 17](docs/images/final-report/figure-06.png)

Source: complete structural drawing document, page 17. Dimensions in mm; parenthesized dimensions retain the source reference notation.

#### CM-P06 Compound Gear C

![CM-P06 Compound Gear C, structural drawing sheet 16](docs/images/final-report/figure-07.png)

Source: complete structural drawing document, page 16. Dimensions in mm; parenthesized dimensions retain the source reference notation.

#### CM-P04 Motor Side Plate P1

![CM-P04 Motor Side Plate P1, structural drawing sheet 14](docs/images/final-report/figure-08.png)

Source: complete structural drawing document, page 14. Dimensions in mm; parenthesized dimensions retain the source reference notation. The source specifies the left-hand part as drawn and the right-hand part mirrored.

#### CM-P05 Outer Side Plate P2

![CM-P05 Outer Side Plate P2, structural drawing sheet 15](docs/images/final-report/figure-09.png)

Source: complete structural drawing document, page 15. Dimensions in mm; parenthesized dimensions retain the source reference notation. The source specifies the left-hand part as drawn and the right-hand part mirrored.

The following right-hand plate drawings are retained from the supplementary gearbox report to show the right-side geometry explicitly.

#### GX-06 Motor Side Plate P1-R

![Right-hand motor side plate P1-R](docs/images/final-report/figure-10.png)

Dimensions in mm. Read stated dimensions rather than measuring the scaled page.

#### GX-07 Outer Side Plate P2-R

![Right-hand outer side plate P2-R](docs/images/final-report/figure-11.png)

Dimensions in mm. Read stated dimensions rather than measuring the scaled page.

### 2.11 Complete Machine Layout and Enclosure

The general assembly drawing defines a model envelope of **206.68 mm wide by 247.39 mm deep by 140.15 mm high**. Z = 0 is the underside of the base, +Y points towards the card-shuffling front and -Y towards the electronics. The two gearboxes are mirrored about X = 10.98 mm.

![CM-00 general assembly with front, side and top views and overall dimensions](docs/images/full-machine/general-assembly.png)

Figure M5. General assembly, CM-00 (PDF page 1). Orthographic views establish the overall envelope and module positions; the transparent front casing exposes the card-feeding mechanisms.

| Module | Arrangement | Design purpose |
| --- | --- | --- |
| Base | Shared printed floor, raised gearbox pads, mounting bosses and electronics locators | Establishes repeatable positions for the mechanisms and electronics |
| A: two gearboxes | Front bay; shafts along Y and motors towards the rear | Provides inward feeding from both stacks during shuffling and one stack during recognition |
| B: electronics casing | Rounded rear shell with internal partition and front apertures | Separates wiring from the card-handling area and integrates the camera/display interface |
| C: shuffler casing | Paired trays over the gearboxes and a central collection chamber | Positions cards over the rollers and provides a familiar loading and retrieval arrangement |
| D: electronics | Breadboard and Power Board in base locators | Organises the control circuit without placing it in the gear path |

The black printed base visually anchors the mechanism, while the white printed shell gives the camera and LCD a distinct interface surface. The rounded upper edges soften the technical enclosure. Printing the support and shell as separate parts permits access to wiring and mechanisms during integration, rather than enclosing them permanently. These choices connect fabrication and appearance to the concept described in Section 1.3.

#### Structural Part Schedule

This schedule consolidates PDF pages 3-4 rather than reproducing their lists as additional images. Gear details remain in Section 2.2; electrical component selection is documented in Section 3.1.

| Structural item | Quantity | Fabrication or assembly role | Drawing |
| --- | --- | --- | --- |
| Black base | 1 | 3D-printed support with gearbox pads and electronics locators | CM-P01 |
| White electronics shell | 1 | 3D-printed enclosure with mounting posts and interface openings | CM-P02 |
| Shuffler casing | 1 | Card trays and collection chamber; supplied model is a simplified envelope | CM-P03 |
| Motor-side and outer support plates | 2 of each type | Left/right mirrored pairs supporting the shafts | CM-P04, CM-P05 |
| Compound gear, idler, roller and motor pinion | 2 of each | One transmission set per side | CM-P06 to CM-P09 |
| Steel shafts | 6 | Two each for compound gear, idler and roller; 2 mm diameter | CM-03 |
| Motor fixing screws | 4 | Two per motor; select to match the motor face | CM-03 |
| Shell-to-base screws | 4 | Inserted from below into shell posts | CM-03, CM-04 |
| Gearbox fixing locations | 4 | Two per raised pad; fasteners must suit the assembled joint | CM-03, CM-04 |

The shaft lengths recorded in CM-03 are 21.0 mm for C, 18.1 mm for B and 16.5 mm for A. Keep the gears free to turn when closing their support plates. The complete source schedule and individual-part sheets remain available in the [structural drawing PDF](mechanical/full-machine/Card-Shuffler-Structure-Drawings.pdf).

### 2.12 Card Path and Structural Interfaces

#### Gearbox-to-Tray Alignment

![CM-10 single-side gearbox assembly with gear and shaft locations](docs/images/full-machine/gearbox-assembly.png)

Figure M6. Gearbox assembly, CM-10 (PDF page 8). The views relate motor, compound-gear, idler and roller axes to the support plates. The power path and ratios are explained once in Sections 2.3-2.4.

Each roller projects 0.7 mm above the tray deck through a 9 by 16 mm window. The sector pusher passes through a 36 by 16 mm outer window. Roller axes are 86.0 mm apart; sector pivots are 157.6 mm apart. The roller provides frictional transport and the sector assists pushing towards the central chamber. During S mode both sides operate; during D mode only the left feeds. This geometry does not provide mechanical phase synchronisation between the independent motors.

![CM-30 shuffler casing showing tray windows and central access opening](docs/images/full-machine/shuffler-casing.png)

Figure M7. Card-handling casing, CM-30 (PDF page 10). The approximately 67 by 47 mm front opening gives access to the central collection chamber, illustrated as approximately 80 mm deep. Parenthesized values and tray-window dimensions are photographic estimates in the source drawing.

#### Base Fixing and Electronics Location

![CM-04 base mounting holes, gearbox pads and electronics locators](docs/images/full-machine/base-hole-layout.png)

Figure M8. Base hole layout, CM-04 (PDF page 5). B1-B4 locate the electronics shell, B5-B6 serve the front casing, and P1-P4 identify gearbox-pad bosses. The drawing defines its own front-left datum O for the coordinate table.

The raised pads establish gearbox height relative to the trays. Locators organise the rear electronics, and the 3.6 mm divider separates it from the front mechanism bay. Underside access to the shell screws allows the enclosure to be removed for wiring and maintenance. The base geometry locates components; secure routing and strain relief are still required for wires, as discussed in Section 3.4.

| Interface | Drawing specification |
| --- | --- |
| Base envelope | 205.68 by 246.89 by 17.8 mm in assembly orientation |
| Floor and walls | 1.8 mm floor and outer walls; 3.6 mm divider |
| Gearbox pads | 51.85 by 23.70 mm; top Z = 17.65 mm; two 6.15 mm diameter bosses each |
| Shell fixing | Four 3.0 mm base holes with 5.55 mm underside counterbores, aligned to shell posts with 2.45 mm pilot holes |
| Breadboard locator L1 | 168.0 by 57.0 mm internal clearance for a 165 by 55 mm breadboard |

#### Electronics Shell and User Interface

![CM-20 electronics casing with interface apertures and internal supports](docs/images/full-machine/electronics-casing.png)

Figure M9. Electronics casing, CM-20 (PDF page 9). The shell drawing shows the display aperture, rounded slot, internal partition and fixing posts. The original “to be confirmed” LCD fit note is a drawing-stage annotation, not an outstanding documentation task. Physical photograph P1 shows the installed, connected display, whose operation is included in the current runtime.

The shell measures 206.68 by 151.69 by 130.0 mm, with 1.8 mm walls and 44.5 mm upper-edge radii. Its 73.0 by 26.0 mm display opening has an 82.0 by 38.0 mm internal frame. An 85.85 by 35.0 mm rounded slot and two 10.0 mm holes complete the front-face openings. Physical photographs show how the camera and LCD were integrated; the CAD shell is a structural reference rather than a complete electronic assembly.

### 2.13 Complete Machine Assembly Sequence

![CM-01 labelled exploded assembly of base, mechanisms, casings and electronics](docs/images/full-machine/exploded-modules.png)

Figure M10. Labelled exploded assembly, CM-01 (PDF page 2). A identifies each gearbox, B the electronics shell, C the shuffler casing and D the electronics references. Separation distances illustrate assembly relationships, not installation travel.

1. Place the base on the bench. Seat the breadboard and Power Board in the rear locators, keeping the front mechanism bay clear.
2. Mount gearbox L on the +X pad and gearbox R on the -X pad, with motors towards -Y. The drawing's L/R labels refer to its coordinate system, not the viewer's screen position.
3. Check gear freedom by hand with power disconnected, then fit the front casing so the rollers and sectors align with their windows through a complete cycle.
4. Route cables clear of gears and card paths, connect the interface components, and seat the rear shell on the base walls. Secure its four posts from below with screws appropriate to the joint thickness.
5. Check inward feeding directions with no cards, then test with a small stack. Adjust the feeding parameters against actual card transport before increasing the stack.

This sequence separates alignment checks from powered testing and keeps the shell removable during debugging. It does not imply that one gear revolution or motor pulse always transports exactly one card; feeding limitations are discussed in Section 7.

### 2.14 Complete Model and Drawing Resources

The [complete STL package](mechanical/full-machine/Card-Machine-3D-STL.zip) contains 22 STL files in millimetres and assembly coordinates. `00_complete_assembly.stl` is an assembled scene, not a print-in-place part. Files 01 and 02 are the base and electronics shell. File 03 is a simplified shuffler envelope; files 07 and 08 are electronics clearance blocks. Motor and shaft reference meshes do not replace the physical components.

The [single-side gearbox directory](mechanical/models/README.md) covers transmission parts; the [complete-machine directory](mechanical/full-machine/README.md) covers their placement, support and enclosure. These are different scopes, not competing runtime versions.

| PDF pages / drawing identifiers | Where explained |
| --- | --- |
| 1-2: CM-00, CM-01 | Overall layout and assembly in Sections 2.11 and 2.13 |
| 3-4: CM-02, CM-03 | Consolidated structural schedule in Section 2.11; electrical choices in Section 3 |
| 5-6: CM-04, CM-05 | Mounting and card path in Section 2.12; power transmission in Sections 2.3-2.4 |
| 7: CM-06 | Alternative rendered views, available in the PDF without duplicating the assembly illustrations |
| 8-10: CM-10, CM-20, CM-30 | Gearbox, shell and card-path interfaces in Section 2.12 |
| 11-13: CM-P01 to CM-P03 | Individual base, shell and casing-envelope sheets retained in the PDF; key dimensions consolidated above |
| 14-19: CM-P04 to CM-P09 | Detailed component sheets; selected drawings reproduced in Section 2.10 |

[Open the complete 19-page structural drawing document](mechanical/full-machine/Card-Shuffler-Structure-Drawings.pdf). Read stated dimensions, not screen measurements. The modelled pinions use profile shifts of +0.5 for Z0 and +0.67 for Z4; dimensional reference notes remain on the source sheets.

## 3 Hardware Design

### 3.1 Component Selection and Rationale

Hardware selection addresses two tasks: continuous operation of both sides during shuffling, and intermittent single-side feeding during recognition followed by final feeding in response to classification. The design connects the mechanical structure, school-supplied power equipment and computer-based recognition workflow.

| Component | System role | Selection rationale |
| --- | --- | --- |
| Arduino Uno R3 | Receive computer commands; control motor on/off states, PWM and timing | Provides the digital pins, PWM outputs and USB serial interface required; communicates with Processing while managing timing locally |
| Two DC motors | Drive the left and right feeding mechanisms | Continuous rotation with driver-based on/off and PWM control; independent channels support two-sided shuffling and single-sided recognition |
| L293D motor driver | Interface Arduino control signals with the motors | Two H-bridges control two DC motors independently, keeping motor current out of Arduino output pins and supporting direction and enable control |
| Two single-side gear modules | Transfer motor rotation to the feeding mechanism | Compact transmission fits the two side spaces; independent modules simplify assembly and testing |
| Feed contact wheels and surfaces | Use friction to move cards towards the centre | Convert rotation into linear feeding through card contact; contact, separator clearance and stack pressure must be tuned together |
| 1602 character LCD | Display welcome, operating and reveal states | Provides local feedback on the same Uno, so users can see the machine state without relying only on the computer window |
| Camera | Capture images of cards in the recognition area | Non-contact visual input without electronics attached to ordinary cards; the computer processes images to distinguish ordinary cards from the marker |
| All-black marker card | Provide a distinct recognition target | Strong visual contrast simplifies the task to two classes; adjacency locates the selected card without identifying every card |
| School-supplied Power Board | Introduce and distribute USB power | Provides accessible supply connections and a power switch for prototyping and staged testing |
| ANSMANN power bank 1700-0132 | Supply the motor power branch | Portable and rechargeable for desktop demonstrations; labelled 5V, maximum 2.1A per USB output, compatible with the Power Board USB input |
| Breadboard and connecting wires | Connect controller, driver and supply branches | Allow inspection, changes and component replacement during prototyping; secure wiring and prevent mechanical strain before demonstration |
| Computer and USB connection | Run Processing and Wekinator and communicate with Arduino | Combine image processing, training, keyboard input and feedback on one platform, reducing extra display and input hardware |
| Enclosure and mounting base | Fix relative positions of mechanism, circuitry and camera | Maintain the relationship between feeding and capture areas, organise wiring and separate user access from internal mechanisms |

Motor and Driver Tradeoffs

Continuous DC motor rotation suits shuffling, while intermittent operation provides time to observe cards during recognition. Changing on and off durations creates the two movement rhythms without changing motors.

This approach measures neither actual motor angle nor card displacement. Feeding distance therefore depends on stack thickness, friction and mechanical resistance as well as the program. Control parameters must be calibrated on the assembled mechanism.

One L293D can control both motors, keeping the circuit relatively compact. However, its voltage drop reduces the voltage applied to the motors. Loaded performance must therefore be tested with the complete power and transmission system rather than inferred from PWM settings alone.

Separating Power and Control

The motors draw power through the driver from the motor supply branch; Arduino output pins provide only control signals. Arduino GND, driver GND and the motor supply negative are connected to establish a common signal reference.

The power bank supplies the motor branch through the Power Board, while Arduino connects to the computer by USB. The 9V battery symbol in the diagrams substitutes for the school Power Board and power bank, which were unavailable in the simulator. The physical machine uses the USB power equipment described here.

How the Hardware Supports the Concept

The dual-motor layout supports familiar two-sided shuffling and single-sided recognition feeding. The camera and all-black marker provide hidden recognition, and Arduino converts the classification event into physical motor action. Together, the hardware supports the interaction from shuffling and selection to revealing the user’s card.

### 3.2 Pin Mapping

| Arduino | L293D | Function |
| --- | --- | --- |
| D5 | 1 EN1 | Motor 1 PWM |
| D4 | 2 IN1 | Motor 1 direction |
| D3 | 7 IN2 | Motor 1 direction |
| D6 | 9 EN2 | Motor 2 PWM |
| D7 | 10 IN3 | Motor 2 direction |
| D8 | 15 IN4 | Motor 2 direction |
| 5V | 16 VCC1 | Logic supply |
| GND | 4, 5, 12, 13 | Common ground |

L293D pins 3 and 6 connect to motor 1; pins 11 and 14 connect to motor 2. Pin 8 connects to the positive external motor supply. The supply negative shares ground with Arduino GND.

#### LCD Display Interface

The 1602 LCD is the 16-column, 2-row display mounted in the white enclosure, separate from the L293D motor driver. The same Uno controls both motors and the display. The final wiring uses the 4-bit parallel interface configured by `LiquidCrystal lcd(12, 11, 9, 10, 13, 2)`.

| LCD pin | Signal | Connection |
| --- | --- | --- |
| 1 | VSS | Common GND |
| 2 | VDD | 5V logic supply |
| 3 | VO | Display contrast connection |
| 4 | RS | Uno D12 |
| 5 | RW | Common GND for write-only operation |
| 6 | E | Uno D11 |
| 7-10 | D0-D3 | Unconnected in 4-bit mode |
| 11 | D4 | Uno D9 |
| 12 | D5 | Uno D10 |
| 13 | D6 | Uno D13 |
| 14 | D7 | Uno D2 |
| 15 | A | Backlight positive supply with appropriate current limiting |
| 16 | K | Common GND |

LCD D4-D7 are the display's data-signal names, not the Uno pin numbers. The LCD and L293D share the Uno ground reference. VO sets display contrast; the backlight connections power the illumination independently of the six control/data signals. Photograph P1 shows the integrated physical display. Figures H3-H4 document the motor circuit; the table above specifies the LCD interface.

When stopped, C displays “Enjoy the / magic trick”. S displays “shuffle”, D displays “Wizadry”, and final feeding completion displays “Your Card!” followed by “Thank you!” after five seconds. X displays “Stopped”.

### 3.3 Power Supply and Circuit Diagrams

The physical prototype uses the school Power Board and an ANSMANN power bank. The 9V battery in the simulator is only an external-supply placeholder, not an actual 9V supply. The Power Board is labelled with USB-C, 5V, 3.3V, a power switch and 0.6A / 2A current-limit settings.

| Power bank item | Label specification |
| --- | --- |
| Brand and model | ANSMANN 1700-0132 |
| Battery | Li-Po, 10000mAh / 37Wh |
| USB-C input | 5V, 2A |
| Micro-USB input | 5V, 2A |
| USB 1 output | 5V, maximum 2.1A |
| USB 2 output | 5V, maximum 2.1A |

![Report figure 12](docs/images/final-report/figure-12.jpeg)

Figure H1 School-supplied Power Board.

![Report figure 13](docs/images/final-report/figure-13.jpeg)

Figure H2 Specifications of the power bank used.

![Report figure 14](docs/images/final-report/figure-14.png)

Figure H3 Dual DC motor control schematic. The 9V battery is a simulator placeholder; the physical machine uses the Power Board and power bank.

![Report figure 15](docs/images/final-report/figure-15.png)

Figure H4 Dual DC motor breadboard wiring. The 9V battery symbol is a power-supply placeholder only.

### 3.4 Safety and Reliability

Disconnect power before changing wiring and keep the power switch accessible. A software stop is not a physical emergency stop: use the power switch to stop the actuators if the computer, serial connection or program fails. Check the final assembly for wires near gears, unsecured boards or cables, abnormal heating and repeated resets. Section 1.4 documents the physical wiring layout and construction stage.

### 3.5 Supply Capacity and Operating Requirements

The rated maximum output power of one USB port is P = 5V × 2.1A = 10.5W. This describes port capacity, not measured whole-machine consumption.

In S mode, both motors run continuously, with the second starting after 600 ms. In D mode, only motor 1 operates intermittently. Its on-time duty cycle is 80 ÷ (80 + 1000) × 100% ≈ 7.4%. This describes timing, not the machine’s power-consumption ratio. Three final feeding pulses follow a marker event.

## 4 Software Design

### 4.1 Software Architecture and Rationale

Camera → Processing image features → Wekinator classification → Processing control logic → Arduino → motors.

The project uses a layered Processing + Wekinator + Arduino architecture, assigning image capture, machine learning and motor control to suitable platforms. Visual recognition and mechanical control can be tested independently, while explicit communication interfaces connect them into one system.

| Software | Main responsibilities | Selection rationale |
| --- | --- | --- |
| Processing | Capture images, extract brightness inputs, receive predictions, handle keyboard input and display feedback | Combines imagery, interaction and communication on the computer for observing recognition and testing motion |
| Wekinator | Train and run the ordinary-card versus black-marker classifier | Interactive recording, training and immediate testing make it straightforward to add examples in response to results |
| Arduino | Execute shuffling, intermittent feeding, final feeding and stopping | Manages motor pins and timing locally without a separate computer command for every on/off transition |

Why Vision Runs on the Computer

Camera capture and image classification run on the computer. Arduino receives only short control commands, not full images. This reduces transmitted data and avoids assigning image processing to the Arduino Uno R3.

Processing converts images into 400 brightness values and sends them to Wekinator over OSC. Wekinator returns a class number. Processing decides whether to convert it into an Arduino command according to the current mode, so predictions cannot start motors independently of machine state.

Why OSC and Serial Communication Are Used

Processing and Wekinator use OSC, which carries continuously updated numerical inputs and classification outputs and matches Wekinator’s communication interface.

Processing and Arduino use USB serial for short mode, stop and marker-trigger commands. Giving each interface a specific role makes the links between camera, classifier and motor control easier to inspect and debug.

Why Action Timing Runs on Arduino

One Arduino sketch manages both operating modes, avoiding repeated uploads to demonstrate different features:

S shuffle mode: both motors run continuously; classification does not control feeding.

D recognition mode: only the left motor feeds intermittently; class 1 maintains the cycle, while class 2 triggers final feeding.

X stop: motor outputs are stopped.

After marker detection, Arduino completes the configured additional pulses and then stops. Keeping timing on Arduino reduces the influence of computer message arrival times on movement rhythm. Multiple final pulses provide the displacement needed to deliver the selected card; they do not represent multiple cards.

Why Modes and a One Shot Trigger Are Used

Wekinator continuously outputs predictions, so one marker may be detected across many frames. Restarting final feeding on every prediction could keep extending motion. The D-mode program therefore accepts the marker trigger once, completes final feeding and stops. S mode ignores classification triggers.

This converts continuous machine learning output into one defined physical event, separates shuffling from recognition, and prevents repeated detections from repeatedly executing the action.

Architectural Benefits and Boundaries

The layered design allows camera input, predictions, serial communication and motor actions to be checked separately. A camera or classifier can later be changed without rewriting all motor control. Interface feedback and Arduino responses help locate faults, but a displayed command is not a measurement of physical movement.

Visual classification influences physical action, but feeding distance remains time- and pulse-based without card-position feedback. The architecture connects recognition to actuation; slipping and jams still require mechanical improvements or later sensor feedback.

### 4.2 Image and Communication Parameters

The final version samples brightness at the centres of a 20 × 20 grid to produce 400 inputs, transmitting up to approximately 10 times per second when new frames are available. These coarse features are computationally lightweight but sensitive to lighting, background and position.

| Communication item | Setting |
| --- | --- |
| Image input | /wek/inputs, port 6448, 400 numerical values |
| Classification output | /wek/outputs, localhost, port 12000 |
| Output configuration | 1 output, 2 classes; 1 ordinary card, 2 marker |
| Arduino serial | 9600 baud |

### 4.3 Operating Logic

S mode starts motor 1, starts motor 2 after 600 ms, and continues until X or a timeout. Staggering avoids simultaneous startup; its improvement in stability has not been quantified.

In D mode, motor 2 is off and motor 1 cycles through 80 ms on and 1000 ms off. Class 1 leaves the cycle unchanged. Class 2 latches one detection and, starting with the next complete pulse, executes three additional pulses, stops and returns TARGET_DONE.

X stops both motors and clears the current sequence without automatic resumption. The interface displays “this is your card” after receiving completion feedback.

### 4.4 Fault Handling

A dedicated serial worker sends H every 500 ms and receives PONG with the Arduino mode. After 2 seconds without valid board replies, Processing requests a stop and reopens the serial connection. Arduino retains its 3-second contact watchdog. A host control-loop stall longer than 2.5 seconds also requests a stop. Recovery requires a confirmed STOPPED and a new user start command; motion never resumes automatically. Camera-frame freshness alone no longer stops motion. Missing classification results reset detection candidates but do not alone stop feeding.

## 5 Machine Learning Design and Training

### 5.1 Three Stages of Iteration

| Stage | Inputs | Outputs | Classes | Design focus |
| --- | --- | --- | --- | --- |
| 1 | 1600 | 1 | 54 | Retain more image information to distinguish cards |
| 2 | 400 | 1 | 54 | Reduce input dimensions and focus on black-card detection |
| 3 | 400 | 1 | 2 | Distinguish only black markers from ordinary cards |

Initially, ordinary cards differed only subtly. Sampling was increased to 1600 inputs to retain more detail, with 54 classes. Practical trials still produced confusion, and multiclass training required substantial work.

![Report figure 16](docs/images/final-report/figure-16.png)

Figure W1 Stage 1 settings: 1600 inputs, 1 output and 54 classes.

Stage 2 introduced the all-black card with its stronger overall brightness contrast. Inputs were reduced to 400, but 54 classes were temporarily retained. The design began to focus on marker detection, although classification work unrelated to the final task remained.

![Report figure 17](docs/images/final-report/figure-17.png)

Figure W2 Stage 2 settings: 400 inputs, 1 output and 54 classes.

Stage 3 retained 400 inputs and reduced the number of classes to two. All ordinary cards belong to class 1 and the black marker to class 2. The model detects only the marker, the control program handles feeding, and card order locates the selected card. This removes unnecessary labelling and training.

![Report figure 18](docs/images/final-report/figure-18.png)

Figure W3 Final settings: 400 inputs, 1 output and 2 classes.

All three stages use /wek/inputs on port 6448 and /wek/outputs at localhost:12000.

### 5.2 Training Data and Model Configuration

The final model uses Wekinator’s k-Nearest Neighbor classifier (kNN), with the number of neighbours set to **k = 1**. Processing samples the camera image as a 20 × 20 grid and extracts **400 brightness values** as inputs. The model has one classification output with two classes:

- **Class 1: ordinary playing cards**, with 2,313 training examples.
- **Class 2: the all-black marker card**, with 2,692 training examples.

The training set contains **5,005 examples** in total. Each example represents the brightness features captured from one camera image, rather than a different playing card. Multiple training examples can be collected continuously from the same card.

During training, the corresponding class is selected, ordinary cards or the all-black marker are presented within the camera’s recognition area, and **Start Recording** is clicked to record examples. After collecting data for both classes, **Train** is clicked to train the model, followed by **Run** to produce classification results in real time. Further examples are added and the model is retrained in response to misclassifications observed during testing.

In D mode, class 1 allows the machine to continue feeding cards. Class 2 triggers the final feeding sequence only after Processing confirms at least five consecutive class-2 results over a period of at least 400 milliseconds. This confirmation mechanism reduces false triggers caused by brief classification fluctuations; it does not change the classification results produced by the Wekinator model itself.

![Report figure 19](docs/images/final-report/figure-19.png)

Figure W4 Wekinator training interface containing 5,005 training examples and two classification classes. Model execution was stopped when the screenshot was taken.

![Report figure 20](docs/images/final-report/figure-20.png)

Figure W5 kNN settings with the number of neighbours set to k = 1.

### 5.3 Future Improvements

The current all-black marker is visually distinctive and easy to detect, but users may notice it while handling the deck, weakening the illusion.

With more time and resources, we would replace it with a normal card such as a Joker. Detecting the Joker would still use its adjacency to the selected card to trigger feeding and revelation.

We would collect more Joker and ordinary-card images. Ordinary examples would cover suits, ranks and face cards; Joker examples would vary position, angle and lighting. These data would train a Joker-versus-other-cards classifier, evaluated on independent images for missed Jokers and false detections.

Removing the conspicuous black card would make the deck and interaction more natural. Binary classification would remain sufficient; individual ordinary cards would not need to be identified.

Jokers differ less strongly from ordinary cards than the black marker does, so occlusion, motion blur, lighting and deck artwork would remain limitations. Better recognition alone would not resolve mechanical slipping or disruption of card order.

### 5.4 Machine Learning Performance Evaluation

The trained binary classifier was evaluated in 60 independent validation trials under practical operating conditions. These 60 trials are evaluation presentations, not the 5,005 feature-vector examples used for training. It uses 400 brightness inputs and kNN with k = 1, assigning class 1 to ordinary cards and class 2 to the all-black marker.

#### Test Method

Testing used new images not included in training, with the camera positioned as in the demonstration. Motors were disabled and only predictions were recorded, separating classifier performance from mechanical feeding problems.

Three conditions were tested, each with 10 ordinary-card presentations and 10 all-black-marker presentations, for 60 trials in total.

| Test condition | Ordinary cards | All-black marker |
| --- | --- | --- |
| Normal position and lighting | 10 trials | 10 trials |
| Slight translation or rotation | 10 trials | 10 trials |
| Changed lighting | 10 trials | 10 trials |
| Total | 30 trials | 30 trials |

Ordinary-card trials covered different suits, ranks and face cards. Cards were repositioned for each trial, with one prediction recorded after the card had remained still for one second. Consecutive video frames were not counted as independent trials. No training examples were added and the model was not retrained during testing.

#### Evaluation Metrics and Results

Overall accuracy is correct predictions divided by all trials. Marker recall is correctly detected markers divided by marker trials. The ordinary-card false-positive rate is ordinary cards predicted as class 2 divided by ordinary-card trials.

| Test condition | Ordinary cards correct | Markers correct | Overall accuracy |
| --- | --- | --- | --- |
| Normal position and lighting | 10/10 | 10/10 | 100% |
| Slight translation or rotation | 10/10 | 10/10 | 100% |
| Changed lighting | 10/10 | 9/10 | 95% |
| Total | 30/30 | 29/30 | 98.33% |

| Key metric | Calculation | Result |
| --- | --- | --- |
| Overall accuracy | 59 ÷ 60 | 98.33% |
| Marker recall | 29 ÷ 30 | 96.67% |
| Ordinary-card false-positive rate | 0 ÷ 30 | 0% |
| Marker miss rate | 1 ÷ 30 | 3.33% |

#### Confusion Matrix

| Actual class | Predicted ordinary | Predicted marker |
| --- | --- | --- |
| Ordinary card | 30 | 0 |
| All-black marker | 1 | 29 |

#### Results Analysis

The model correctly classified 59 of 60 independent presentations, giving 98.33% overall accuracy. It achieved 20/20 under normal position and lighting and 20/20 with slight translation or rotation. Under changed lighting it achieved 19/20, or 95% overall accuracy. Marker-only accuracy in that condition was 90% (9/10), distinct from the combined 95%.

All 30 ordinary-card trials were correct, with no ordinary card classified as a marker, giving an observed false-positive rate of 0%. Of 30 marker trials, 29 were correctly detected, giving 96.67% recall. The only error occurred under changed lighting, where a marker was classified as an ordinary card.

Within the tested range, the model consistently distinguished ordinary cards from the all-black marker and tolerated the slight position changes tested. The missed marker under changed lighting suggests prioritising additional marker examples across brightness, exposure and shadow conditions, then validating improvement with new independent tests. The results support this direction but do not establish the specific cause of the error.

For machine control, an ordinary-card false positive would start final feeding too early; a missed marker could allow feeding to continue beyond the intended reveal position. No instance of the former was observed, but one instance of the latter occurred. Overall accuracy alone therefore does not describe the control risks.

This was a small evaluation with only 10 trials per class in each condition. An observed 0% false-positive rate does not guarantee no false triggers in every real setting, and 100% within a condition does not guarantee performance across all positions or lighting. With motors disabled, 98.33% describes image classification, not the success rate of locating and completely delivering the selected card. Slipping, stack thickness and jams require separate end-to-end evaluation.

## 6 Debugging and Iteration

The project was tested in stages: individual motors first, followed by dual-motor operation, computer control, camera input and Wekinator integration, and finally the coordination of predictions with feeding. This sequence helped separate mechanical, electrical, communication and classification problems rather than changing several parts of the system at once.

### 6.1 Motor Control and Mechanical Feeding

Motor Direction Did Not Match the Required Feeding Direction

Both mechanisms must feed towards the centre, so motor-shaft rotation alone was not enough to establish the correct wiring. Each side was run separately, its actual feeding motion was observed, and the corresponding direction signals were adjusted.

After adjustment, both sides operated in the required directions. These verified direction settings were retained during later speed and timing changes to avoid confusing direction faults with insufficient feeding force.

Motors Ran Unloaded but Hummed or Failed to Start with the Gears Connected

Early tests included motors that ran unloaded but could not start the gear train, and differences between individual and simultaneous operation. The motor was disengaged from the gears to check whether the remaining transmission turned freely by hand. Motors and driver channels were then tested separately.

This separated motor output from mechanical resistance. Startup and running parameters were also adjusted separately, rather than attributing every failure to software. The final shuffle mode starts motor 1 first and motor 2 after 600 ms, avoiding simultaneous startup.

Short Recognition Pulses Produced Insufficient Movement

Continuous running and short bursts produced different results. Even at the same PWM setting, a motor that stops soon after each start does not necessarily achieve the feeding displacement seen during continuous operation.

On-time, off-time and output settings were adjusted incrementally and compared against actual card movement. The final version uses 80 ms on and 1000 ms off, balancing movement with camera observation time for the current demonstration.

Rollers Turned but Cards Did Not Move under a Thick Stack

With a thicker stack, the rollers sometimes continued turning while cards remained pressed in place or slipped. Control signals and motor motion were present, but motion was not reliably transferred to the cards.

Increasing software run time alone could not resolve this. Investigation therefore focused on stack pressure, card-to-roller contact and resistance at the separator opening. This exposed a central limitation: executing a feeding action does not confirm that the card has moved the intended distance.

One Additional Pulse Did Not Fully Deliver the Selected Card

Testing showed that one extra pulse after marker detection often left the next selected card only partly delivered. Three to five pulses were sometimes needed.

The final program therefore separates marker detection from final feeding. The detection event is latched once without extending the pulse already in progress. Starting with the next complete pulse, three additional pulses are executed before stopping. These pulses provide feeding distance; they do not represent three cards.

### 6.2 Computer Control and Serial Communication

The Interface Updated but the Motors Did Not Respond

The interface can update immediately after a key press, but this confirms only that the computer handled the input. It does not prove that Arduino received the command or that a motor moved.

The communication chain was checked in separate steps:

1. Confirm that Arduino receives commands and returns feedback.

2. Check the actual serial port and baud rate used by Processing.

3. Close other programs occupying the serial port.

4. Compare Arduino responses with observed motor actions.

The final interface displays “this is your card” only after receiving TARGET_DONE, not immediately after the computer sends the detection command. This response confirms completion of the programmed feeding sequence, not a card-position sensor measurement.

The Serial Port Was Occupied by Another Program

A Resource busy error occurred during testing. Arduino Serial Monitor and the computer control program cannot use the same port simultaneously. Serial Monitor must therefore be closed after uploads or serial tests before Processing is started.

This step was added to the startup instructions so that port contention would not be mistaken for a motor or recognition fault.

Software Stopping and Communication Loss

During normal operation, X stops both motors and clears the current sequence. Heartbeat communication was also added: Processing sends a heartbeat every 500 ms, and Arduino stops motor outputs after more than 3 seconds without contact.

This reduces the risk of continued operation after the computer program exits or communication is lost, but does not replace physical power isolation. The power switch remains accessible during testing so actuator power can be cut if an abnormal condition occurs.

### 6.3 Camera and Machine Learning Integration

The Camera Was Listed but Produced No Images

During external-camera testing, the device name appeared in the list but frames did not update, and an Internal data stream error occurred.

Machine learning and motor integration were temporarily removed from the test. A camera-only preview was used to check device selection and capture settings. Brightness sampling and OSC transmission were reintroduced after images became available. This separated image-acquisition failure from classification error.

An OSC Value Reading Method Was Misspelled

Processing failed to compile when the nonexistent sintValue() method was used. It was corrected to intValue() for integer arguments, after which the output address and data type were checked.

This fault was in prediction reception, not training quality. Communication code had to be corrected before recognition performance could be assessed.

Continuous Predictions Could Repeatedly Trigger Final Feeding

Wekinator continuously outputs predictions. A marker remaining in view can therefore generate class 2 across multiple frames. Restarting final feeding on every result could repeatedly extend motion.

The final program uses a one-shot latch. After the first accepted marker event in D mode, further identical results do not restart or extend final feeding. S mode does not use predictions to trigger actions. On completion, the machine stops and waits for the user to start another run.

Multiclass Recognition Was Reduced to Binary Classification

Early trials attempted to distinguish individual cards, increasing inputs to 1600 and setting 54 classes. Similarities between ordinary cards caused confusion and increased training work.

An all-black marker was introduced, and the task was ultimately reduced to two classes: ordinary cards and the marker, using 400 brightness inputs. Machine learning detects the marker; card order and subsequent feeding locate the selected card.

This was a change to the task design, not only to model parameters. The system detects the event needed for the trick rather than identifying every card. Section 5.4 records the independent evaluation of the final binary classifier.

### 6.4 Integration Outcome and Remaining Work

The complete control chain is operational, linking image capture and classification to Arduino commands and motor actions. Mechanical execution limitations, including double feeds, jams and incomplete delivery, are discussed in Section 7. Control-sequence completion and successful physical delivery are evaluated separately.

## 7 Limitations

The project links the computer, Wekinator and Arduino and can execute shuffling, intermittent feeding, marker-triggered final feeding and stopping. However, software completion, correct classification and successful physical card delivery are different outcomes. The current prototype has the following limitations.

### 7.1 Control Actions Can Differ from Actual Feeding Outcomes

Executing the programmed actuator motion does not guarantee the intended card delivery. The mechanism sometimes feeds two cards together, jams, or leaves a card only partly delivered.

These deviations affect the reveal. Even when marker detection and all commands are correct, a double feed can advance the physical card sequence beyond the expected position, while a jam can prevent the selected card from being presented completely. Completing the control sequence is therefore not equivalent to completing the magic effect successfully.

### 7.2 Time Based Feeding Has No Card Feedback

Feeding is controlled through motor on-time, off-time and pulse counts, without direct sensing of card quantity, position or departure. The program cannot confirm that one action fed exactly one card or determine whether a card is stuck.

The three additional pulses after marker detection are an empirical configuration for the current mechanism. They do not represent three cards and cannot guarantee equal displacement under every load. TARGET_DONE confirms that the programmed final sequence has ended, not that the selected card has physically emerged.

### 7.3 Mechanical Performance Depends on Stack and Contact Conditions

Friction-based transport depends on stack thickness, roller contact, card surface condition and separator resistance. A thick stack can increase resistance on the bottom card, allowing the roller to turn without moving it. Unsuitable contact or separation conditions can also move several cards together.

The two DC motors vary with load and individual characteristics. Equal PWM values do not imply equal speed or mechanical phase. Without speed or phase feedback, the system cannot guarantee exact synchronisation. Gear backlash and wear in plastic shaft holes can also affect consistency over time.

### 7.4 Visual Classification Is Sensitive to Environmental Changes

The final model uses 400 brightness inputs and kNN with k = 1. These features suit the contrast between ordinary cards and an all-black marker, but are affected by lighting, shadows, background, card position, occlusion and motion blur.

The only classification error in Section 5.4 occurred under changed lighting: a marker was classified as an ordinary card. This suggests adding examples under varied lighting, although the test alone does not establish the specific cause of that error.

With k = 1, the nearest training example directly determines the output. Sample coverage and labelling quality therefore matter. The final Processing code uses multiframe confirmation rather than triggering from a single prediction. Detection is first armed by at least three consecutive class-1 results spanning at least 200 ms. Once armed, a marker requires at least five consecutive class-2 results spanning at least 400 ms, with no result gap above 250 ms. A class-1 result or an excessive gap resets the marker candidate. Accepted detection is latched once per scan, preventing repeated predictions from restarting final feeding. This filters brief fluctuations, but a sustained incorrect class-2 output can still satisfy the conditions and trigger an early reveal.

### 7.5 The Trick Depends on Card Order

The machine does not identify the selected card itself. It relies on adjacency between that card and the marker. The user must return the card as instructed and then cut the deck rather than interleave it in another shuffle.

If adjacency is broken, correct marker detection cannot locate the selected card. The boundary case in which cutting separates the marker and selected card between the top and bottom of the stack is not currently handled.

The black marker also looks different from normal cards and may be noticed, weakening the illusion. Section 5.3 proposes replacing it with a Joker, but that approach requires retraining and validation.

### 7.6 The Performance Evaluation Has a Limited Scope

The classification evaluation contains 60 independent presentations, with 10 ordinary-card and 10 marker trials in each condition. The reported 98.33% accuracy describes image classification under those tested conditions.

Motors were disabled during testing. The results do not include moving cards, double feeds, jams or timing errors between recognition and actuation, and therefore are not a whole-machine success rate.

Likewise, an observed ordinary-card false-positive rate of 0% does not guarantee no false triggers in all settings. This evaluation measures classifier performance only; it does not provide an end-to-end machine success rate incorporating card delivery, double feeds or jams.

### 7.7 Communication Protection Does Not Replace Physical Stopping

The system relies on the computer for image capture, Wekinator and Processing, with a serial connection to Arduino. Heartbeat-timeout stopping, bidirectional reply monitoring and serial reconnection cover some faults, but not all.

For example, if camera and serial communication remain active while Wekinator stops producing predictions, missing classification output alone does not currently stop the machine. Software stopping also does not replace physical power isolation; the power switch must remain accessible.

In summary, recognition and actuator control are integrated, but whole-machine reliability remains limited primarily by single-card separation, feeding consistency and missing physical feedback. Further work should prioritise mechanical feeding stability, supported by broader visual data and state feedback to reduce the gap between commanded actions and actual outcomes.

## 8 Software Installation and Operation

This section describes software preparation, startup and operation for the final dual DC motor version. One Arduino sketch supports both modes, selected through keyboard input in Processing; changing modes does not require another upload.

### 8.1 Software and Runtime Requirements

| Software or resource | Purpose |
| --- | --- |
| Arduino IDE | Upload the control sketch to the Arduino Uno R3 |
| Processing | Run camera capture, communication, keyboard control and feedback |
| Processing Video library | Capture camera images |
| Processing oscP5 library | Exchange OSC messages with Wekinator |
| Processing Serial library | Communicate with Arduino over USB serial |
| Wekinator | Run the ordinary-card versus black-marker classifier |
| Final Arduino and Processing code | Execute machine control and recognition integration |
| Trained Wekinator project | Provide the classifier, or retrain using Section 5.2 |

Install Video and oscP5 using Processing’s library manager. Serial is supplied with Processing. Allow camera access when requested on first use.

### 8.2 Upload the Arduino Sketch

1. Connect the Arduino Uno R3 to the computer by USB.

2. Open the final control sketch in Arduino IDE.

3. Select Arduino Uno as the board and choose the corresponding serial port.

4. Upload the sketch and confirm that the upload succeeds.

5. Close Serial Monitor before starting the Processing control program.

Only one program can use the serial port at a time. If Resource busy appears, close Serial Monitor or other serial control programs and retry.

### 8.3 Configure Processing and Wekinator

Set Processing to the serial port currently assigned to Arduino on the computer, at 9600 baud. Port names can change with the USB socket or connected device, so do not reuse another computer’s port name without checking.

Select the camera actually in use and ensure that its image covers the recognition area. Camera position, background and lighting should remain as close as possible to the training setup.

| Wekinator setting | Value |
| --- | --- |
| Input OSC address | /wek/inputs |
| Input port | 6448 |
| Number of inputs | 400 |
| Output OSC address | /wek/outputs |
| Output host | localhost |
| Output port | 12000 |
| Number of outputs | 1 |
| Number of classes | 2 |
| Class 1 | Ordinary cards |
| Class 2 | All-black marker |
| Classifier | k-Nearest Neighbor, k = 1 |

The 400 inputs correspond to the brightness values sampled from a 20 × 20 grid in Processing. Input count, OSC addresses and ports must match the code.

### 8.4 Startup and Pre Run Checks

1. Check the motor, display, supply and common-ground wiring. Keep cables clear of gears and leave the actuator power switch accessible.
2. Upload the final Arduino sketch if needed, then close Serial Monitor and any other serial-control program.
3. Open the supplied trained Wekinator project. Check the serial port and camera index in Processing as described in Section 8.3.
4. Run Processing and wait for **Connected** and a confirmed **STOPPED** state. Check the live preview to ensure it is the intended camera.
5. Focus the Processing window and press **C**. At least one camera frame must have arrived; C confirms the preview for recognition mode and sends the LCD welcome command when the controller is ready and stopped.
6. Click **Run** in Wekinator. While motors remain stopped, show ordinary cards and the black marker separately to check classes 1 and 2.
7. Return focus to Processing. On first connection or after wiring changes, perform an unloaded check, followed by a small-stack feeding test.

S and D are accepted only when the connection is ready, STOPPED has been confirmed, and no command acknowledgement is pending. D additionally requires camera confirmation with C. Reconnection never resumes motion automatically.

### 8.5 Keyboard Controls

| Key | Function | Machine behaviour |
| --- | --- | --- |
| C | Confirm live camera / welcome | Confirms a received camera image; when ready and stopped, LCD shows “Enjoy the / magic trick” |
| S | Start shuffling | Motor 1 starts immediately, motor 2 after 600 ms; both continue |
| D | Start recognition | Left motor ON 80 ms / OFF 1000 ms; right motor remains off; requires C confirmation |
| X / Esc | Request stop | Stops outputs and clears the sequence; wait for STOPPED before restarting |
| R | Reconnect | Requests a stop and reopens serial; requires a new user start after synchronisation |

Use the computer keyboard with the Processing window focused. There is no keyboard T simulation; T is an internal marker command sent by Processing.

To switch modes, press X, wait for STOPPED, then press S or D. X clears progress rather than preserving a paused sequence. If acknowledgement is missing, the interface locks motion and attempts reconnection. Use the physical power switch if software cannot stop the machine.

### 8.6 Shuffling

1. Divide the deck into two stacks and place them in the left and right hoppers.

2. Press S in the Processing window.

3. Check that cards on both sides feed towards the centre.

4. Press X when shuffling is complete.

5. Wait for the mechanism to stop before removing and squaring the cards.

Shuffle mode does not use predictions to trigger final feeding. If double feeding, a jam or abnormal noise occurs, stop the machine before adjusting cards. Do not reach into a running mechanism.

### 8.7 Recognition and Revelation

Complete selection, return and cutting as described in Section 1.2, maintaining adjacency between the selected card and marker. Then:

1. Place the full deck in the left hopper, leaving the right empty.
2. Wait for Connected and STOPPED, check the live camera preview, and press C if it has not been confirmed in this Processing session. Ensure Wekinator is running.
3. Focus Processing and press D. Arduino replies SCANNING; the left motor begins its 80 ms on / 1000 ms off cycle and the LCD displays “Wizadry”.
4. Stable ordinary-card output arms marker detection: at least three consecutive class-1 results spanning 200 ms. Until then, class 2 does not trigger final feeding.
5. Once armed, at least five consecutive class-2 results spanning 400 ms confirm the marker, provided no interval exceeds 250 ms. Class 1 or an excessive gap resets the marker candidate.
6. Processing sends T once. Arduino finishes any pulse already in progress without counting it, then executes three new complete feeding pulses starting at the next OFF-to-ON transition.
7. After the third pulse, Arduino disables both motors, sends TARGET_DONE and displays “Your Card!” on the LCD. Processing displays “this is your card”; after five seconds the LCD changes to “Thank you!”.

The message reports completion of the programmed sequence, not measured card delivery. Observe the actual selected card; stop and reorganise the deck if double feeding or a jam occurs. Press X to clear a run before starting another mode.

### 8.8 Stopping and Shutdown

Press X for a normal stop. Before restarting, check the mechanism and card state, then begin the relevant procedure again.

If the keyboard or interface cannot stop the motors, use the power switch to disconnect actuator power. At shutdown, stop the motors and turn off actuator power before exiting Processing, stopping Wekinator and disconnecting equipment.

Processing sends regular heartbeats and monitors PONG replies; Arduino stops outputs after more than 3 seconds without contact. Processing requests a stop and reconnects after missing board replies, and requires a new user start after recovery. These protections do not replace a directly accessible power switch.

## 9 Project Files and Digital Resources

The GitHub repository provides a single entry point for the project. README.md introduces the design concept, operation and technical structure, with links to source code, mechanical resources, circuit diagrams and test records. Resources are organised by function to help readers understand the system, run the software and trace its design and debugging process.

### 9.1 Documentation Entry Point

[README.md](README.md) is the entry point for the [project repository](https://github.com/robbie-stevens/-cps-card-magic). It contains the project concept, user journey, mechanical and hardware design, software architecture, machine learning training and evaluation, debugging record, limitations, operating instructions and individual contributions.

The navigation links connect the report to the current source files, runtime guide, mechanical models, drawings and photographs. The supplementary Markdown pages provide runtime instructions and model-specific notes; the circuit and debug index pages link back to the corresponding report sections.

### 9.2 Source Code and Runtime Resources

The current Arduino and Processing source files are stored in the repository alongside the Wekinator project. The source files are available through the links below.

[Open Arduino source](arduino/TwoDC/TwoDC.ino)

[Open Processing source](processing/ExternalCamera_Control_v2/ExternalCamera_Control_v2.pde)

[Open Wekinator project](wekinator/WekinatorProject/WekinatorProject.wekproj)

[Open current runtime guide](docs/final-runtime.md)

The source links above open the current repository files. For offline use, download the current repository through GitHub's Code → Download ZIP. Older packages are separated under [Historical resources](docs/history/README.md) and are excluded from current-code download instructions. Links open files; they do not start the machine.

Arduino entry point: arduino/TwoDC/TwoDC.ino. Upload this sketch to Arduino Uno R3. It controls both DC motors through the L293D at 9600 baud. Motor 1 uses PWM D5 and direction D4/D3; motor 2 uses PWM D6 and direction D7/D8.

Processing entry point: processing/ExternalCamera_Control_v2/ExternalCamera_Control_v2.pde. This single sketch captures the camera image, extracts a 20 by 20 grid of 400 brightness values, sends OSC inputs to Wekinator, receives predictions, handles keyboard controls and communicates with Arduino. It requires Video and oscP5, plus the supplied Serial library.

Wekinator entry point: wekinator/WekinatorProject/WekinatorProject.wekproj. Keep inputConfig.xml, outputConfig.xml and the current subfolder together. The supplied project also includes current/models/model0.xml and current/currentData.arff. These are runtime model and training resources, not Arduino or Processing source files.

Before starting, change ARDUINO_PORT in Processing to the port shown on the current computer. The supplied value is /dev/cu.usbmodem21201. CAMERA_INDEX is currently 1 and selects the AVFoundation device index through a macOS capture pipeline. Check the live preview rather than assuming this index identifies the same camera on every computer.

Open TwoDC.ino and upload it, then close Arduino Serial Monitor. Open the Wekinator project. Run the Processing sketch, wait for the Arduino READY handshake and an updating camera preview, and press C to confirm the selected camera. Click Run in Wekinator, then focus the Processing window for keyboard control.

S starts shuffling: motor 1 starts immediately and motor 2 starts 600 ms later. Both continue until X or a communication timeout. D starts left-only recognition feeding: motor 1 runs for 80 ms and stops for 1000 ms repeatedly; motor 2 remains off. Both modes use PWM 255. Press X and wait for STOPPED before changing modes. X or Esc requests a stop and clears the current sequence.

Wekinator receives /wek/inputs on port 6448 and sends one classification value through /wek/outputs to localhost port 12000. Class 1 represents ordinary cards and leaves D-mode feeding unchanged. Class 2 represents the all-black marker. Detection is armed after at least three consecutive class-1 results spanning 200 ms. A marker then requires at least five consecutive class-2 results spanning 400 ms, with no gap above 250 ms. The keyboard T simulation has been removed; T remains the internal serial marker command. R requests serial reconnection without automatic motion restart.

For an accepted marker event, Processing sends T once. Arduino does not count or extend a pulse already in progress. Starting with the next OFF-to-ON transition, it executes three new complete 80 ms pulses, separated by the normal off-time, then disables the motors and sends TARGET_DONE. Only then does Processing display “this is your card”. Three pulses provide feed distance and do not mean three cards.

Processing sends heartbeat H every 500 ms and Arduino replies PONG. Arduino stops after more than 3000 ms without contact. Processing requests a stop and reconnects after 2000 ms without valid replies; it also requests a stop if its main control loop is unresponsive for more than 2500 ms. Camera-frame loss alone does not stop the machine. These functions do not confirm physical card movement or replace the accessible power switch.

The Arduino sketch sends TARGET_PULSE 1/3, 2/3 and 3/3, followed by TARGET_DONE. The single Uno also controls the LCD: C displays “Enjoy the / magic trick”, S displays “shuffle”, D displays “Wizadry”, and completion displays “Your Card!” followed by “Thank you!” after 5 seconds. LCD signal pins are RS D12, E D11, D4 D9, D5 D10, D6 D13 and D7 D2. 

### 9.3 Mechanical and Circuit Resources

The mechanical resources include the [single-side gearbox models](mechanical/models/README.md), [complete-machine models and structural drawings](mechanical/full-machine/README.md), assembly renders and individual component engineering sheets. Section 2 explains their dimensions, transmission, structural interfaces and assembly sequence. The drawings retain their reference-dimension notation; stated dimensions and technical notes define the geometry rather than measurements from a scaled page.

The circuit resources include the dual DC motor schematic, breadboard wiring diagram, Arduino-to-L293D pin mapping, LCD signal mapping, and Power Board and power bank information in Section 3. The 9V battery symbol in the simulator is an external-supply placeholder only. The physical machine uses the school-supplied Power Board and ANSMANN power bank, not a 9V battery.

The physical photographs in Section 1.4 show the completed enclosure and the circuit and mechanism integration during construction.

### 9.4 Testing and Debugging Records

Section 5.4 records 60 independent classifier-validation trials, including the test conditions, prediction counts, confusion matrix, calculated metrics and results analysis. These validation trials are distinct from the 5,005 recorded training examples and from physical card-delivery outcomes.

Section 6 documents observed faults, investigations and changes involving motors, feeding, serial communication, camera capture and classification integration. Section 7 records the remaining mechanical, recognition and communication limitations, including the distinction between completion of a control sequence and successful delivery of the selected card.

### 9.5 File Organisation and Version Consistency

The repository separates current runtime files, supporting documentation and mechanical resources by function:

| Location | Contents |
| --- | --- |
| `README.md` | Main project report and navigation |
| `arduino/TwoDC/` | Current Uno motor and LCD control sketch |
| `processing/ExternalCamera_Control_v2/` | Current camera, classification, keyboard and serial-control sketch |
| `wekinator/WekinatorProject/` | Wekinator project, configuration, training data and model |
| `docs/final-runtime.md` | Current startup and operating guide |
| `docs/images/` | Report figures, engineering sheets and physical photographs |
| `mechanical/models/` | Detailed single-side gearbox resources |
| `mechanical/full-machine/` | Complete-machine model package and structural drawing set |
| `docs/history/` | Archived earlier package, excluded from current runtime instructions |

Current source and operating instructions describe the dual-DC-motor Uno version with the integrated LCD. Repository-relative links connect the report to its supporting files. Section 10 lists the software, library, hardware and project-mechanical references.

The homepage links and current runtime guide identify the active source files. The earlier package is explicitly labelled as historical and is not the current-code download.

## 10 Group Contributions and References

### 10.1 Individual Contributions

#### Christina Ren

Christina developed the control code for both prototypes, trained the Wekinator model, and integrated Wekinator, Processing and Arduino so that camera-based classification could trigger actuator actions. She refined the control logic, feeding durations and operating parameters through testing to support the shuffling and recognition modes.

She created physical structure models and carried out 3D printing for both prototypes. She assembled Prototype 2 and connected its circuitry, integrating the mechanical structure, actuators and control system.

Christina tested and debugged both prototypes, checking the relationship between software commands and physical behaviour and documenting operational issues. She completed the project documentation, covering the design process, system architecture, mechanical and circuit descriptions, machine learning training and evaluation, debugging records and project limitations.

#### Albert Phillips

Albert designed and modelled components for the original card-shuffling machine and carried out 3D printing of the housing, base and other assembly parts. He also helped build the second prototype, modelled by Christina, and prepared a component register and assembly guide to support printing and construction.

Albert learned the fundamentals of Arduino and the electronic components, then connected and programmed an LCD screen using an Elegoo Uno R3 for the original design. Through Christina’s explanations of Wekinator training and the Processing code, he developed a better understanding of how software controlled the physical mechanisms and applied this knowledge when assisting with assembly and integration.

#### Robbie Stevens

Robbie adapted the commercial card-shuffling mechanism and developed the initial motor-control code. Robbie also contributed to assembling the prototype and soldering the circuit components. He contributed to the machine learning work.

### 10.2 Software and Hardware References

No external application code was adapted for this project. The references below identify the software tools, libraries and hardware documentation relevant to the implementation; citing a library does not imply that its example code was copied or adapted.

1. Arduino. [Arduino UNO R3 documentation](https://docs.arduino.cc/hardware/uno-rev3/). Board specifications, pinout and controller reference.
2. Arduino. [analogWrite reference](https://docs.arduino.cc/language-reference/en/functions/analog-io/analogWrite/). PWM output used for motor-enable control.
3. Processing Foundation. [Video library reference](https://processing.org/reference/libraries/video/). Camera capture and the Capture class.
4. Processing Foundation. [Serial library reference](https://processing.org/reference/libraries/serial/). Serial-port selection and communication between Processing and Arduino.
5. Andreas Schlegel. [oscP5 library documentation](https://sojamo.de/libraries/oscP5/). OSC messages and network communication between Processing and Wekinator.
6. Rebecca Fiebrink. [Wekinator official source repository](https://github.com/fiebrink1/wekinator). Software reference for the interactive classification and model-training environment.
7. Texas Instruments. [L293x Quadruple Half-H Drivers datasheet, revision D](https://www.ti.com/lit/ds/symlink/l293.pdf). L293D pin functions, separate logic and motor supplies, enable inputs and electrical specifications.

Online references checked on 10 November 2026.

### 10.3 Project Mechanical Resources

- Card-Feed Gearbox: Mechanical Structure Report, 9 November 2026, credited to Christina. This project report provides tooth counts, dimensions, transmission analysis, assembly instructions and drawings GX-01 to GX-07. Reference-dimension notation is retained in the documentation.
- [Card Shuffler Structure Drawings](mechanical/full-machine/Card-Shuffler-Structure-Drawings.pdf), 19 sheets, 9 November 2026. The drawing set documents the complete assembly, structural interfaces and individual components.
- [Complete machine model package](mechanical/full-machine/Card-Machine-3D-STL.zip) and [single-side gearbox models](mechanical/models/README.md).
- [Project repository](https://github.com/robbie-stevens/-cps-card-magic).
