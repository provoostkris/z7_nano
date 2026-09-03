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

entity rmap_to_ahb_bridge is
  port (
    -- Clock and Reset
    clk             : in  std_logic;
    rst_n           : in  std_logic;

    -- RMAP Interface
    rmap_valid      : in  std_logic;
    rmap_is_write   : in  std_logic;
    rmap_address    : in  std_logic_vector(31 downto 0);
    rmap_data_in    : in  std_logic_vector(31 downto 0);
    rmap_data_out   : out std_logic_vector(31 downto 0);
    rmap_ready      : out std_logic;

    -- AHB Master Interface
    haddr           : out std_logic_vector(31 downto 0);
    hwrite          : out std_logic;
    htrans          : out std_logic_vector(1 downto 0);
    hsize           : out std_logic_vector(2 downto 0);
    hburst          : out std_logic_vector(2 downto 0);
    hprot           : out std_logic_vector(3 downto 0);
    hwdata          : out std_logic_vector(31 downto 0);
    hrdata          : in  std_logic_vector(31 downto 0);
    hready          : in  std_logic;
    hresp           : in  std_logic_vector(1 downto 0);

    -- AHB Arbitration
    hbusreq         : out std_logic;
    hgrant          : in  std_logic
  );
end entity;

architecture rtl of rmap_to_ahb_bridge is

  type state_t is (s_idle, s_request, s_access, s_respond);
  signal state : state_t := s_idle;
  signal addr_reg : std_logic_vector(31 downto 0);
  signal data_reg : std_logic_vector(31 downto 0);

begin

  process(clk, rst_n)
  begin
    if rst_n = '0' then
      state       <= s_idle;
      htrans      <= "00"; -- IDLE
      hwrite      <= '0';
      hbusreq     <= '0';
      rmap_ready  <= '0';
    elsif rising_edge(clk) then
      case state is

        when s_idle =>
          rmap_ready <= '0';
          if rmap_valid = '1' then
            addr_reg  <= rmap_address;
            data_reg  <= rmap_data_in;
            hbusreq   <= '1';
            state     <= s_request;
          end if;

        when s_request =>
          if hgrant = '1' then
            haddr   <= addr_reg;
            hwrite  <= rmap_is_write;
            htrans  <= "10"; -- NONSEQ
            hsize   <= "010"; -- 32-bit
            hburst  <= "000"; -- SINGLE
            hprot   <= "0011"; -- default
            hwdata  <= data_reg;
            hbusreq <= '0';
            state   <= s_access;
          end if;

        when s_access =>
          if hready = '1' then
            if rmap_is_write = '0' then
              rmap_data_out <= hrdata;
            end if;
            state <= s_respond;
          end if;

        when s_respond =>
          rmap_ready <= '1';
          state <= s_idle;

        when others =>
          state <= s_idle;

      end case;
    end if;
  end process;

end architecture;
