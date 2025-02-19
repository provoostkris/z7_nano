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
- [x] PMOD-LCD   : [display module](https://www.tindie.com/products/johnnywu/pmod-lcd-096-expansion-board/)

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
The PMOD LCD can display a 80 width x 160 height images.
The module is build with the  [ST7735](https://files.waveshare.com/upload/e/e2/ST7735S_V1.1_20111121.pdf) controller chip (or something very similar)
The ST7735 can be used with various sizes of displays, therefore it is needed to configure the controller first, before sending images.

The configuration of the controller is done with the control FSM, and performs consecutively these steps :
- [x] s_idle : pull the reset pin of the screen
- [x] s_reset : wait to recover from reset
- [x] s_sleep : send the 'sleep out'command to the display
- [x] s_wake : wait to recover from sleep
- [ ] s_invctr_cmd : invert row vs column
- [ ] s_invctr_p0 : parameter list
- [ ] s_gmctrp_cmd : positive gamma correction
- [ ] s_gmctrp_p0 : parameter list
- [ ] s_gmctrn_cmd : negative gamma correction
- [ ] s_gmctrn_p0 : parameter list
- [ ] s_mad_cmd : swap RGB vs BGR
- [ ] s_mad_p0 : parameter list
- [ ] s_inv : invert RGB values
- [x] s_on : turn on the display
- [ ] s_cas_cmd : set region for writing columns
- [ ] s_cas_p0 : parameter list
- [ ] s_cas_p1 : parameter list
- [ ] s_ras_cmd : set region for writing rows
- [ ] s_ras_p0 : parameter list
- [ ] s_ras_p1 : parameter list
- [x] s_ramwr : start write to pixel memory cells command
- [x] s_send_req : send pixel data

The bare essential commands are ticked , to be able to see some content on the screen.
however it is highly likely, the size, color , orientation , etc will not be correct.
Therefore the optional commands are added.

The goals for the controller are
- [x]  to display a picture on the module
- [x]  to display a character on the module
- [ ]  to display a text on the module
- [ ]  to display a text and image on the module

#### For image display
A random picture is converted to RGB array, with a free on line tool.
Below is a comparison of the different images.
It is difficult to see on the picture what is the benefit of gamma correction, since you can almost see every pixel.
However in reality, from a distance the gamma correction allows more accurate colors.
- image 1 : original used for RGB array creation
- image 2 : displayed , with RGB reference bars , no gamma correction
- image 3 : image with gamma correction

![color](img/color.bmp)

![color_no_gamma](img/color_no_gamma.bmp)

![color_do_gamma](img/color_do_gamma.bmp)


#### For character display
a file {ascii_pkg.vhd} that contains many ASCII characters coded in logic vectors is used to lookup the black or white value for a pixel in that character.
A character is 16hx8w , and a corresponding window is opened in the screen controller, then the pixels are send.

##### Credits

Getting started and connection diagrams are explained in the wiki :
[wiki](https://www.waveshare.com/wiki/0.96inch_LCD_Module)

The code for the bare minimum was inspired by a note from Bruce E. Hall, W8BH , who has done a great job in explaining how to get the module up and running
[initialization](http://w8bh.net/avr/AvrTFT.pdf)

A dummy image was converted to a RGB array, that is used in the VHDL files by a free tool :
[free image converter](https://onlinetools.com/image/convert-image-to-rgb-values)