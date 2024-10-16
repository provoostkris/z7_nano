------------------------------------------------------------------------------
--  simplified model of RGMII reciever
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

use     std.textio.all;


-- this bench relies on the https://github.com/provoostkris/netwiz
library nw_util;
context nw_util.nw_util_context;
library nw_ethernet;
use     nw_ethernet.nw_ethernet_pkg.all;

-------------------------------------------------------------------------------
entity rgmii_rx_model is
  generic (
    g_speed     : integer range 100 to 1000;
    g_size      : integer range  64 to 1500
  );
  port (
    rst_n       : in  std_logic;

    rgmii_rxc   : in  std_logic;
    rgmii_rx_ctl: in  std_logic;
    rgmii_rd    : in  std_logic_vector(3 downto 0)
    );

end entity rgmii_rx_model;

architecture sim of rgmii_rx_model is

  signal eth_pkt   : t_slv_arr(0 to g_size)(7 downto 0);

--! procedures
procedure proc_wait_clk_edge  (
  signal    clk    : in std_logic ;
  constant  edge   : in std_logic
  ) is
begin
    wait until clk'event and clk = edge;
end procedure;

begin

gen_fast: if g_speed = 1000 generate
  p_rgmii_rx_model: process
    variable idx   : integer ;
    variable txt : line;
  begin
    wait until rst_n = '1';
    while rst_n = '1' loop
      wait until rgmii_rx_ctl = '1' ;
      idx := 0;
      while rgmii_rx_ctl = '1' loop
        proc_wait_clk_edge(rgmii_rxc, '1');
        eth_pkt(idx)(3 downto 0) <= rgmii_rd;
        proc_wait_clk_edge(rgmii_rxc, '0');
        eth_pkt(idx)(7 downto 4) <= rgmii_rd;
        idx := idx + 1 ;
      end loop;
      -- put on the screen the data recieved
        write(txt,"Recieved new ETH frame :" & LF);
        writeline(output,txt);
        for i in 7 to idx-1 loop
          hwrite (txt,eth_pkt(i));
        end loop;
        writeline(output,txt);
    end loop;
  end process;
end generate gen_fast;

gen_slow: if g_speed = 100 generate
  p_rgmii_rx_model: process
    variable idx   : integer ;
    variable txt : line;
  begin
    wait until rst_n = '1';
    while rst_n = '1' loop
      wait until rgmii_rx_ctl = '1' ;
      idx := 0;
      while rgmii_rx_ctl = '1' loop
          proc_wait_clk_edge(rgmii_rxc, '1');
          eth_pkt(idx)(3 downto 0) <= rgmii_rd;
          proc_wait_clk_edge(rgmii_rxc, '1');
          eth_pkt(idx)(7 downto 4) <= rgmii_rd;
          idx := idx + 1 ;
      end loop;
      -- put on the screen the data recieved
        write(txt,"Recieved new ETH frame :" & LF);
        writeline(output,txt);
        for i in 8 to idx-1 loop
          hwrite (txt,eth_pkt(i));
        end loop;
        writeline(output,txt);
    end loop;
  end process;
end generate gen_slow;

end architecture sim;