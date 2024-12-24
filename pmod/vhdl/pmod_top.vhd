------------------------------------------------------------------------------
--  top level for pmod entities
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity pmod_top is
  port(
    clk           : in  std_logic;  --system clock
    reset_n       : in  std_logic;  --active low reset

    -- PMOD LED
    led           : out std_logic_vector(7 downto 0);
    -- PMOD SEG
    seg           : out std_logic_vector(7 downto 0);
    -- PMOD LCD
    cs            : out std_logic;
    sda           : out std_logic;
    sck           : out std_logic;
    rst           : out std_logic
  );
end pmod_top;

architecture rtl of pmod_top is

  constant c_led : integer := 6;
  constant c_hex : std_logic_vector(3 downto 0) := x"B";

begin

--! pmod_led
  i_pmod_led : entity work.pmod_led
  port    map (c_led,led);

--! pmod_seg
  i_pmod_seg : entity work.pmod_seg
  port    map (c_hex,seg);

--! pmod_lcd
  i_pmod_lcd : entity work.pmod_lcd
  port map (
    clk     => clk,
    reset_n => reset_n,
    cs      => cs,
    sda     => sda,
    sck     => sck,
    rst     => rst
  );


end rtl;