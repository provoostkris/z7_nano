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

    led           : out std_logic;
    -- PMOD LED
    leds          : out std_logic_vector(7 downto 0);
    -- PMOD SEG
    seg           : out std_logic_vector(7 downto 0);
    -- PMOD LCD
    cs            : out std_logic;
    dc            : out std_logic;
    sda           : out std_logic;
    sck           : out std_logic;
    rst           : out std_logic
  );
end pmod_top;

architecture rtl of pmod_top is

  constant c_led : integer := 6;
  constant c_hex : std_logic_vector(3 downto 0) := x"B";


  attribute MARK_DEBUG : string;
  attribute MARK_DEBUG of  cs  : signal is "TRUE";
  attribute MARK_DEBUG of  dc  : signal is "TRUE";
  attribute MARK_DEBUG of  sda : signal is "TRUE";
  attribute MARK_DEBUG of  sck : signal is "TRUE";
  attribute MARK_DEBUG of  rst : signal is "TRUE";

begin
--! just glow the led
  led <= clk and not reset_n;

--! pmod_led
  i_pmod_led : entity work.pmod_led
  port    map (c_led,leds);

--! pmod_seg
  i_pmod_seg : entity work.pmod_seg
  port    map (c_hex,seg);

--! pmod_lcd
  i_pmod_lcd : entity work.pmod_lcd
  port map (
    clk     => clk,
    reset_n => reset_n,
    cs      => cs,
    dc      => dc,
    sda     => sda,
    sck     => sck,
    rst     => rst
  );


end rtl;