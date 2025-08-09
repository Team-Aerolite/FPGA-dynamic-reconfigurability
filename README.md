# FPGA-dynamic-reconfigurability
To demonstrate the reconfiguration capability of the FPGA component of the HA-FPGA system, a simple logic function is dynamically reconfigured with a microcontroller over SPI, which acts as the reconfiguration handler.

# Demonstration goals
The primary objective of this demonstration is to illustrate the system's capability to dynamically reconfigure the interconnections among the FPGA's logical elements, enabling the desired outputs across various scenarios. This process occurs without necessitating full system reprogramming or firmware flashing, as is typically required with MCUs, thereby allowing internal hardware structures to adapt efficiently in real time.
In this demonstration, 4 logic functions are reconfigured on the fly by remapping the data flow based on the commands provided by the reconfiguration handler microcontroller unit. The following functionalities can be observed in this demonstration.

* Dynamically select one of four 2-bit-wide logic functions implemented inside the FPGA (AND, OR, XOR, NAND).
* Configure 2-bit FPGA input values A and B in real time from Arduino.
* Compute bit-wise logic outputs entirely in FPGA hardware using these configurable inputs/functions.
* Display:
  * The current logic function codes on LEDs.
  * The computed 2-bit result on LEDs.
* Read the 2-bit output result back from the FPGA SPI and display it on the Arduino Serial Monitor.
* Allow interactive command input on the Arduino Serial Monitor to reconfigure FPGA behavior on the fly.

# Hardware Setup
* FPGA: Intel Altera Cyclone IV FPGA Development Board
* Microcontroller: Arduino Uno
* Communication protocol: SPI (Serial Peripheral Interface)
* Peripheral I/O: 4 onboard user LEDs for status display, Reset button
