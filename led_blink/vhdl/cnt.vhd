------------------------------------------------------------------------------
--  on-off counter
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_misc.all;

entity cnt is
  generic(
    g_cnt         : in  positive range 8 to 32  := 26 -- power of two for counter
  );
  port(
    clk           : in  std_logic;  --system clock
    reset_n       : in  std_logic;  --active low reset

    led           : out std_logic
  );
end cnt;

architecture rtl of cnt is

  signal cntr : unsigned(g_cnt-1 downto 0);

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

  led <= cntr(cntr'high);

end rtl;