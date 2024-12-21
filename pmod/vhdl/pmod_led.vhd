------------------------------------------------------------------------------
--  pmod led
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity pmod_led is
  port(
    int           : in  integer range 0 to 2**8-1;
    led           : out std_logic_vector(7 downto 0)
  );
end pmod_led;

architecture rtl of pmod_led is

begin

led <= std_logic_vector(to_unsigned(int,8));

end rtl;