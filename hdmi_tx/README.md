# hdmi_tx

### Description
The design include a VGA timing controller and a HDMI encoder for showing some pattern on a display
Primitives are used :
- PLL : Correct clock frequencies are derived from the local crystal with a fractional PLL
- OSERDES : output serializer for driving the TDMS pins ( differential)

### [I/O](constraints)
HDMI connector
LED : off = reset
      on  = active
RESET button
