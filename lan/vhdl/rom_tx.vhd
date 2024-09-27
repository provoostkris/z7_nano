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
    m_dat_tdata   : out std_logic_vector(31 downto 0);
    m_dat_tlast   : out std_logic;
    m_dat_tvalid  : out std_logic
    );

end entity rom_tx;
-------------------------------------------------------------------------------
architecture rtl of rom_tx is

  signal collect    : std_logic;
  signal data_valid : std_logic;

begin

  collect       <=  m_dat_tready and not data_valid;
  m_dat_tvalid  <=  data_valid;

  --! send some dummy data , collected from a dummy frame
  process(rst_n, clk) is
    variable v_idx : integer range 0 to c_pkg_dummy_eth'length;
  begin
      if rst_n='0' then
        v_idx         := 0;
        m_dat_tdata   <= ( others => '0');
        m_dat_tlast   <= '0';
        data_valid    <= '0';
      elsif rising_edge(clk) then
        if collect = '1' then
          m_dat_tdata(8*1-1 downto 8*0)   <= c_pkg_dummy_eth(v_idx+0);
          m_dat_tdata(8*2-1 downto 8*1)   <= c_pkg_dummy_eth(v_idx+1);
          m_dat_tdata(8*3-1 downto 8*2)   <= c_pkg_dummy_eth(v_idx+2);
          m_dat_tdata(8*4-1 downto 8*3)   <= c_pkg_dummy_eth(v_idx+3);
          if v_idx > c_pkg_dummy_eth'high-4 then
            m_dat_tlast   <= '1';
            v_idx         := 0;
          else
            m_dat_tlast   <= '0';
            v_idx         := v_idx + 4 ;
          end if;
        end if;
        data_valid <= collect;
      end if;
  end process;

end architecture rtl;