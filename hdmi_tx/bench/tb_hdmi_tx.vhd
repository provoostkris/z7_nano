------------------------------------------------------------------------------
--  Test Bench for the HDMI TX
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
-- just for random functions
use ieee.math_real.all;

entity tb_hdmi_tx is
	port(
		y        :  out std_logic
	);
end entity tb_hdmi_tx;

architecture rtl of tb_hdmi_tx is

constant c_clk_per  : time      := 50 ns ;

signal clk          : std_ulogic :='0';
signal rst_n        : std_ulogic :='0';

--! procedures
procedure proc_wait_clk
  (constant cycles : in natural) is
begin
   for i in 0 to cycles-1 loop
    wait until rising_edge(clk);
   end loop;
end procedure;

begin

--! standard signals
	clk            <= not clk  after c_clk_per/2;

--! dut
dut: entity work.hdmi_tx(rtl)
  port map (
    clk               => clk,
    reset_n           => rst_n,

    hdmi_tx_clk_n	    => open,
    hdmi_tx_clk_p	    => open,
    hdmi_tx_chn_r_n	  => open,
    hdmi_tx_chn_r_p	  => open,
    hdmi_tx_chn_g_n	  => open,
    hdmi_tx_chn_g_p	  => open,
    hdmi_tx_chn_b_n	  => open,
    hdmi_tx_chn_b_p	  => open,

    led               => y
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
	    proc_wait_clk(10**7);

	  report " END of test bench" severity failure;

	end process;

end architecture rtl;