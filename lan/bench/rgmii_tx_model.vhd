------------------------------------------------------------------------------
--  simplified model of RGMII transmitter
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
entity rgmii_tx_model is
  generic (
    g_speed     : integer range 100 to 1000;
    g_size      : integer range  64 to 1500
  );
  port (
    rst_n       : in  std_logic;

    header      : t_ethernet_header;                  -- header record
    payload     : t_slv_arr(0 to g_size)(7 downto 0); -- packet payload
    tx_ena      : in  std_logic;

    rgmii_txc   : in  std_logic;
    rgmii_tx_ctl: out std_logic;
    rgmii_td    : out std_logic_vector(3 downto 0)
    );

end entity rgmii_tx_model;

architecture sim of rgmii_tx_model is

  constant c_tx_ena      : std_logic := '1';
  constant c_tx_err      : std_logic := '0';
  constant c_ipg_len     : natural   := 12 ;

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
  p_rgmii_tx_model: process
    variable v_len     : natural ;
    variable v_eth_pkt : t_slv_arr(0 to g_size + 64)(7 downto 0); -- byte array
    variable txt : line;
  begin
    rgmii_td     <= ( others => '0');
    rgmii_tx_ctl <= '0';
    wait until rst_n = '1';
    while rst_n = '1' loop
      proc_wait_clk_edge(rgmii_txc, '1');
      wait until tx_ena = '1' ;
      -- dynamically create the packet
      v_len                                 := f_eth_create_pkt_len(header, payload);           -- calculate total packet length
      v_eth_pkt(0 to v_len - 1)             := f_eth_create_pkt(header, payload);               -- create the packet
      v_eth_pkt(0 to v_len + 7)             := f_concat(C_ETH_PREAMBLE, v_eth_pkt(0 to v_len - 1)); -- add preamble
      -- start transmitter
 	    for i in 0 to v_len + 7 loop
        -- first nibble
        proc_wait_clk_edge(rgmii_txc, '1');
        rgmii_td     <= v_eth_pkt(i)(3 downto 0);
        rgmii_tx_ctl <= c_tx_ena;
        proc_wait_clk_edge(rgmii_txc, '0');
        rgmii_td     <= v_eth_pkt(i)(7 downto 4);
        rgmii_tx_ctl <= c_tx_ena xor c_tx_err;
      end loop;

      -- followed by the IPG
      for i in 0 to c_ipg_len-1 loop
        -- first nibble
        proc_wait_clk_edge(rgmii_txc, '1');
        rgmii_td     <= ( others => '1');
        rgmii_tx_ctl <= not c_tx_ena;
        proc_wait_clk_edge(rgmii_txc, '0');
        rgmii_td     <= ( others => '1');
        rgmii_tx_ctl <= not c_tx_ena xor c_tx_err;
      end loop;

      proc_wait_clk_edge(rgmii_txc, '1');
      rgmii_tx_ctl <= '0';
      rgmii_td     <= ( others => '0');
      
      -- put on the screen the data recieved
        write(txt,"Transmitted new ETH frame :" & LF);
        writeline(output,txt);
        for i in 0 to v_len + 7 + c_ipg_len loop
          hwrite (txt,v_eth_pkt(i));
        end loop;
        writeline(output,txt);
    end loop;
  end process;
end generate gen_fast;

gen_slow: if g_speed = 100 generate
end generate gen_slow;

end architecture sim;