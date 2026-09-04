-- ============================================================================
-- Title       : RMAP to AHB Bridge (Single Transfer)
-- File        : rmap_to_ahb_bridge.vhd
-- Author      : Kris Provoost
-- Description : Translates RMAP read/write requests into single-beat AMBA AHB 2.0 transactions.
--               Supports bus arbitration via HBUSREQ/HGRANT.
-- ============================================================================
-- Dependencies: AHB arbiter must drive HGRANT signal
-- Verification: Self-checking testbench with scoreboard and waveform checklist
-- ============================================================================
-- Revision History:
--   2025-10-08 : FSM states renamed with s_ prefix
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.amba.all;

entity rmap_to_ahb_bridge is
  port (
    -- Clock and Reset
    clk             : in  std_logic;
    rst_n           : in  std_logic;

    -- general purpose User Interface
    rmap_valid      : in  std_logic;
    rmap_is_write   : in  std_logic;
    rmap_address    : in  std_logic_vector(31 downto 0);
    rmap_data_in    : in  std_logic_vector(31 downto 0);
    rmap_data_out   : out std_logic_vector(31 downto 0);
    rmap_ready      : out std_logic;

    -- AHB master interface
    ahbi            : in  ahb_mst_in_type;
    ahbo            : out ahb_mst_out_type
  );
end entity;

architecture rtl of rmap_to_ahb_bridge is

  type state_t is ( s_idle,
                    s_request
                  );
  signal s_bridge_state : state_t := s_idle;

  signal dmai_i : ahb_dma_in_type;
  signal dmao_i : ahb_dma_out_type;

begin

  process(clk, rst_n)
  begin
    if rst_n = '0' then
      s_bridge_state <=   s_idle;
      rmap_ready     <=   '0';
      dmai_i         <=  c_rst_ahb_dma_in;
    elsif rising_edge(clk) then
      case s_bridge_state is

        when s_idle =>
          rmap_ready <= '0';
          if rmap_valid = '1' then

            dmai_i.address <=  rmap_address;
            dmai_i.wdata   <=  rmap_data_in;
            dmai_i.start   <=  '1';
            dmai_i.burst   <=  '0';
            dmai_i.write   <=  rmap_is_write;
            dmai_i.busy    <=  '0';
            dmai_i.irq     <=  '0';
            dmai_i.size    <=  HSIZE_WORD;

            s_bridge_state          <=  s_request;
          end if;

        when s_request =>
          if dmao_i.ready = '1' then
            dmai_i         <=   c_rst_ahb_dma_in;
            rmap_ready     <=  '1';
            rmap_data_out  <=  dmao_i.rdata;
            s_bridge_state <=  s_idle;
          end if;

        when others =>
          s_bridge_state <= s_idle;

      end case;
    end if;
  end process;

i_ahbmst: entity work.ahbmst
   port map(
      rst  => rst_n ,
      clk  => clk ,
      dmai => dmai_i,
      dmao => dmao_i,
      ahbi => ahbi,
      ahbo => ahbo
      );

end architecture;
