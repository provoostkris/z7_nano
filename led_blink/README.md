# led_blink

### Description
Design contains various modes to blink an LED.
The board only has one LED , therefore a generic is used to select the mode prior to synthesis
The generic can be set as :
- mode = 1 : on/off
- mode = 2 : dimmed
- mode = 3 : beat

### I/O(/constraints)
The output is mapped on the PL LED
The PL push button is the reset
The clock is directly from the on board crystal
