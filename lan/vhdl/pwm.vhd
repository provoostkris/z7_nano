------------------------------------------------------------------------------
--!  on off pwm
--!  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_misc.all;

entity pwm is
  port(
    clk           : in  std_logic;  --system clock
    reset_n       : in  std_logic;  --active low reset

    led           : out std_logic
  );
end pwm;

architecture rtl of pwm is

  constant c_cnt  : positive := 14;

  signal cntr     : unsigned(c_cnt-1 downto 0);
  signal beat     : unsigned(c_cnt-1 downto 0);

begin

  --! simple counter for PWM driver
  process(reset_n, clk) is
  begin
      if reset_n='0' then
        cntr  <= ( others => '0');
      elsif rising_edge(clk) then
        cntr <= cntr + to_unsigned(1,cntr'length);
      end if;
  end process;

  --! up down counter for beat controller
  process(reset_n, clk) is
  begin
      if reset_n='0' then
        beat  <= ( others => '0');
      elsif rising_edge(clk) then
      if or_reduce(std_logic_vector(cntr)) = '0' then
        beat  <= beat + to_unsigned(1,beat'length);
      end if;
      end if;
  end process;

  led <= '1' when cntr > beat else '0' ;

end rtl;