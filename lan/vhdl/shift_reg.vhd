------------------------------------------------------------------------------
--!  simple shift register
--!  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.std_logic_misc.all;

entity shift_reg is
  generic(
    g_del         : in  positive range 1 to 128   --! amount of clk cycles for shift
  );
  port(
    clk           : in  std_logic;  --! system clock
    reset_n       : in  std_logic;  --! active low reset

    shift_d       : in  std_logic;
    shift_q       : out std_logic
  );
end shift_reg;

architecture rtl of shift_reg is

  --! array storage
  signal shift : std_logic_vector(g_del-1 downto 0);

begin


--! for vectors
gen_slv: if g_del > 1 generate
  process(reset_n, clk) is
  begin
      if reset_n='0' then
        shift  <= ( others => '0');
      elsif rising_edge(clk) then
        shift <= shift(shift'high-1 downto 0) & shift_d;
      end if;
  end process;

  shift_q <= shift(g_del-1);

end generate gen_slv;

--! for bits
gen_std: if g_del = 1 generate
  process(reset_n, clk) is
  begin
      if reset_n='0' then
        shift_q  <= '0';
      elsif rising_edge(clk) then
        shift_q <=  shift_d;
      end if;
  end process;
end generate gen_std;

end rtl;