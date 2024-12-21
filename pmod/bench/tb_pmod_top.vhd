------------------------------------------------------------------------------
--  Test Bench for the pmod entities
--  rev. 1.0 : 2024 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
-- just for random functions
use ieee.math_real.all;

entity tb_pmod_top is
	port(
		y        :  out std_logic
	);
end entity tb_pmod_top;

architecture rtl of tb_pmod_top is

constant c_clk_per  : time      := 50 ns ;

signal clk          : std_ulogic :='0';
signal rst_n        : std_ulogic :='0';

signal led     : std_logic_vector(7 downto 0);
signal seg     : std_logic_vector(7 downto 0);


--! procedures
procedure proc_wait_clk
  (constant cycles : in natural) is
begin
   for i in 0 to cycles-1 loop
    wait until rising_edge(clk);
   end loop;
end procedure;

begin

	--! not using TB output now
	y <= '0';
	
--! standard signals
	clk            <= not clk  after c_clk_per/2;

--! dut
dut : entity work.pmod_top
port map (
  clk     => clk,
  reset_n => rst_n,
  led     => led,
  seg     => seg
);


	--! run test bench
	p_run: process

	  procedure proc_reset
	    (constant cycles : in natural) is
	  begin
	     rst_n <= '0';
	     for i in 0 to cycles-1 loop
	      wait until rising_edge(clk);
	     end loop;
	     rst_n <= '1';
	  end procedure;

	begin

	  report " RUN TST.01 ";
	    proc_reset(3);
	    proc_wait_clk(10**2);

	  report " END of test bench" severity failure;

	end process;

end architecture rtl;