library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------
package pmod_lcd_pkg is

  -- factor for the clock divider , to reduce the SPI clock from the system clock
  constant c_clk_reduce             : integer := 3;
  -- proper reset time
  -- 1 clk = 20 ns ==> 1 us = 50x
  constant c_clk_per_us             : integer :=     50 ; -- clock cycles for 1 us
  constant c_rst_time_act           : integer :=      20 * c_clk_per_us ; -- $9.17   minimum      10 us
  constant c_rst_time_hld           : integer := 125_000 * c_clk_per_us ; -- $9.17   minimum 120_000 us
  constant c_sleep_out              : integer := 155_000 * c_clk_per_us ; -- $9.19.2 minimum 150_000 us

  -- constants found in the LCD controller datasheet
  constant c_bits_565         : integer := 5+6+5;
  constant c_bits_666         : integer := 8+8+8;
  constant c_bits             : integer := c_bits_666;

  -- display area
  -- the memory is X:132 x Y:162
  -- The 80  center pixels are used for X axis
  -- The 160 center pixels are used for Y axis
  constant c_ras_xs           : integer := (132-80)/2 + 00; --! RAS Xstart
  constant c_ras_xe           : integer := (132-80)/2 + 79; --! RAS Xend
  constant c_cas_ys           : integer := 1;               --! CAS Ystart
  constant c_cas_ye           : integer := 160;             --! CAS Yend

  constant c_hori             : integer := 132;     --! X amount memory
  constant c_vert             : integer := 162;     --! Y amount memory
  constant c_pixl             : integer := c_hori * c_vert;       --! total amount of memories

  constant c_SLPOUT           : std_logic_vector(7 downto 0) := x"11";  --! sleep out
  constant c_DISPINV          : std_logic_vector(7 downto 0) := x"21";  --! display inversion
  constant c_DISPOFF          : std_logic_vector(7 downto 0) := x"28";  --! display off
  constant c_DISPON           : std_logic_vector(7 downto 0) := x"29";  --! display on
  constant c_CASET            : std_logic_vector(7 downto 0) := x"2A";  --! column address set
  constant c_RASET            : std_logic_vector(7 downto 0) := x"2B";  --! row address set
  constant c_RAMWR            : std_logic_vector(7 downto 0) := x"2C";  --! RAM write
  constant c_MADCTL           : std_logic_vector(7 downto 0) := x"36";  --! axis control
  constant c_COLMOD           : std_logic_vector(7 downto 0) := x"3A";  --! color mode

  -- just some random values to driver the display for testing
  constant c_r_color       : std_logic_vector(24-1 downto 0) :=  "11111111" & "00000000" & "00000000" ;
  constant c_g_color       : std_logic_vector(24-1 downto 0) :=  "00000000" & "11111111" & "00000000" ;
  constant c_b_color       : std_logic_vector(24-1 downto 0) :=  "00000000" & "00000000" & "11111111" ;

  -- create arrays for pixel map stores
  type t_raw_arr  is array (integer range <>) of std_logic_vector(24-1 downto 0);     -- raw pixel map
  type t_rgb_arr  is array (integer range <>) of integer range 0 to 255;              -- rgb array
  type t_clr_arr  is array (integer range <>) of t_rgb_arr( 0 to 2);                  -- color array
  type t_cnt_arr  is array (integer range <>) of integer range 0 to c_bits-1;         -- counter array

  constant c_color_map : t_clr_arr( 0 to c_pixl-1) :=
  -- manually modified the first three pixels to be fixed for r & g & b to check the timing and alignment
  (others => (255, 127, 63));


end package pmod_lcd_pkg;
-------------------------------------------------------------------------------
package body pmod_lcd_pkg is

end package body pmod_lcd_pkg;