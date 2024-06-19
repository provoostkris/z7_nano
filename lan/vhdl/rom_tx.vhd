------------------------------------------------------------------------------
--  rom for dummy frame transmission
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.lan_pkg.all;
-------------------------------------------------------------------------------
entity rom_tx is

  port (
    clk           : in  std_logic;
    rst_n         : in  std_logic;

    m_dat_tready  : in  std_logic;
    m_dat_tdata   : out std_logic_vector(7 downto 0);
    m_dat_tlast   : out std_logic;
    m_dat_tvalid  : out std_logic
    );

end entity rom_tx;
-------------------------------------------------------------------------------
architecture rtl of rom_tx is

begin

  --! send some dummy data , collected from a dummy frame
  process(rst_n, clk) is
    variable v_idx : integer range 0 to c_pkg_dummy_eth'length;
  begin
      if rst_n='0' then
        v_idx         := 0;
        m_dat_tdata   <= ( others => '0');
        m_dat_tlast   <= '0';
        m_dat_tvalid  <= '0';
      elsif rising_edge(clk) then
        if m_dat_tready = '1' then
          m_dat_tdata   <= c_pkg_dummy_eth(v_idx);
          m_dat_tvalid  <= '1';
          if v_idx = c_pkg_dummy_eth'high then
            m_dat_tlast   <= '1';
            v_idx         := 0;
          else
            m_dat_tlast   <= '0';
            v_idx         := v_idx + 1 ;
          end if;
        else
          m_dat_tdata   <= ( others => '0');
          m_dat_tlast   <= '0';
          m_dat_tvalid  <= '0';
        end if;
      end if;
  end process;

end architecture rtl;