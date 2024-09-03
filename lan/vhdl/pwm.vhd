------------------------------------------------------------------------------
--  on off pwm
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_misc.all;

entity pwm is
  generic(
    g_pwm         : in  positive range 1 to 255 := 50 -- pwm value
  );
  port(
    clk           : in  std_logic;  --system clock
    reset_n       : in  std_logic;  --active low reset

    led           : out std_logic
  );
end pwm;

architecture rtl of pwm is

  signal cntr : unsigned( 7 downto 0);

begin

  -- siple counter to bring led in visible frequency
  process(reset_n, clk) is
  begin
      if reset_n='0' then
        cntr  <= ( others => '0');
      elsif rising_edge(clk) then
        cntr <= cntr + to_unsigned(1,cntr'length);
      end if;
  end process;

  led <= '1' when cntr > g_pwm else '0' ;

end rtl;