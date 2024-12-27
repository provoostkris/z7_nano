# pmod

### Description
Design containing sevaral simple cores to interface zith common PMOD boards>
A PMOD board is a very simplistic interface and some basic function , to add to your FPGA>
PMOD support is forseen for
- [x] PMOD-LEDx8 : [8 LED s](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_LEDx8)
- [x] PMOD-DTx2  : [7 SEG display two digits](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DTx2)
- [ ] PMOD-DVI   : [HDMI interface](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DVI)
- [ ] PMOD-BTNx4 : [4 push button and 4 slide button](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_BTN4%2B4)
- [ ] PMOD-TFCARD: [memory card interface](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_TF-CARD)
- [ ] PMOD-LCD   : [display module](https://www.tindie.com/products/johnnywu/pmod-lcd-096-expansion-board/)
 [driver](https://files.waveshare.com/upload/e/e2/ST7735S_V1.1_20111121.pdf)
 [wiki](https://www.waveshare.com/wiki/0.96inch_LCD_Module)

### [I/O](constraints)
- The PL push button is the reset
- The clock is directly from the on board crystal
PMOD LED
- GPIO connector
PMOD SEG
- GPIO connector
PMOD LCD
- GPIO connector


#### PMOD LCD
Display a picture on the module , that is converted to RGB array, with a free on line tool.
The image should look like
![colors](img/color.jpg)
[initialization](http://w8bh.net/avr/AvrTFT.pdf)