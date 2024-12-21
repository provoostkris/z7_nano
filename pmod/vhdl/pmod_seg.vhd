------------------------------------------------------------------------------
--  pmod led
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity pmod_seg is
  port(
    hex           : in  std_logic_vector(3 downto 0);
    seg           : out std_logic_vector(7 downto 0)
  );
end pmod_seg;

architecture rtl of pmod_seg is

begin

with hex select
  seg <= 
    "10000001" when x"0",
    "11001111" when x"1",
    "10010010" when x"2",
    "10000110" when x"3",
    "11001100" when x"4",
    "10100100" when x"5",
    "10100000" when x"6",
    "10001111" when x"7",
    "10000000" when x"8",
    "10000100" when x"9",
    "10000010" when x"A",
    "11100000" when x"B",
    "10110001" when x"C",
    "11000010" when x"D",
    "10110000" when x"E",
    "10111000" when x"F",
    "01111111" when others;

end rtl;