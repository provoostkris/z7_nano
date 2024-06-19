------------------------------------------------------------------------------
--  ehternet frame fifo
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------


library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library unisim;
use     unisim.vcomponents.all;

library unimacro;
use     unimacro.vcomponents.all;

-------------------------------------------------------------------------------
entity eth_rx_fifo is

  port (
    -- interface from rgmii phy
    s_clk         : in  std_logic;
    s_rst_n       : in  std_logic;
    s_sof         : in  std_logic;
    s_eof         : in  std_logic;
    s_rxdata      : in  std_logic_vector(7 downto 0);
    s_rxdv        : in  std_logic;

    -- axis interface to user logic
    m_clk         : in  std_logic;
    m_rst_n       : in  std_logic;
    m_dat_tready  : in  std_logic;
    m_dat_tdata   : out std_logic_vector(7 downto 0);
    m_dat_tlast   : out std_logic;
    m_dat_tvalid  : out std_logic
    );

end entity eth_rx_fifo;
-------------------------------------------------------------------------------
architecture rtl of eth_rx_fifo is

  type t_state is ( idle,
                    stream
                  );
  signal s_ctrl                     : t_state;
  attribute syn_encoding            : string;
  attribute syn_encoding of t_state : type is "safe,onehot";

  signal s_rst        : std_logic;
  signal fifo_empty   : std_logic;
  signal fifo_a_full  : std_logic;
  signal fifo_di      : std_logic_vector(8 downto 0);
  signal fifo_do      : std_logic_vector(8 downto 0);
  signal fifo_rden    : std_logic;

begin

-- signal assignments
  s_rst         <= not s_rst_n;
  fifo_di       <= s_eof & s_rxdata;
  fifo_rden     <= m_dat_tready and not fifo_empty;

   -- FIFO_DUALCLOCK_MACRO: Dual-Clock First-In, First-Out (FIFO) RAM Buffer
   --                       Artix-7
   -- Xilinx HDL Language Template, version 2023.1

   FIFO_DUALCLOCK_MACRO_inst : FIFO_DUALCLOCK_MACRO
   generic map (
      DEVICE => "7SERIES",            -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES"
      ALMOST_FULL_OFFSET => X"0080",  -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
      DATA_WIDTH => 9,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE => "18Kb",            -- Target BRAM, "18Kb" or "36Kb"
      FIRST_WORD_FALL_THROUGH => false) -- Sets the FIFO FWFT to TRUE or FALSE
   port map (
      ALMOSTEMPTY => open,   -- 1-bit output almost empty
      ALMOSTFULL => fifo_a_full,     -- 1-bit output almost full
      DO => fifo_do,                     -- Output data, width defined by DATA_WIDTH parameter
      EMPTY => fifo_empty,               -- 1-bit output empty
      FULL => open,                 -- 1-bit output full
      RDCOUNT => open,           -- Output read count, width determined by FIFO depth
      RDERR => open,               -- 1-bit output read error
      WRCOUNT => open,           -- Output write count, width determined by FIFO depth
      WRERR => open,               -- 1-bit output write error
      DI => fifo_di,                     -- Input data, width defined by DATA_WIDTH parameter
      RDCLK => m_clk,               -- 1-bit input read clock
      RDEN => fifo_rden,                 -- 1-bit input read enable
      RST => s_rst,                   -- 1-bit input reset
      WRCLK => s_clk,               -- 1-bit input write clock
      WREN => s_rxdv                  -- 1-bit input write enable
   );
   -- End of FIFO_DUALCLOCK_MACRO_inst instantiation


  --! data flow controller
  process(m_rst_n, m_clk) is
  begin
      if m_rst_n='0' then
        s_ctrl     <= idle;
        m_dat_tdata   <= ( others => '0');
        m_dat_tlast   <= '0';
        m_dat_tvalid  <= '0';
      elsif rising_edge(m_clk) then
        case s_ctrl is
          when idle =>
            m_dat_tdata   <= ( others => '0');
            m_dat_tlast   <= '0';
            m_dat_tvalid  <= '0';

            if fifo_empty = '0' then
              s_ctrl     <= stream;
            end if;

          when stream =>
            if m_dat_tready = '1' then
              m_dat_tdata   <= fifo_do(7 downto 0);
              m_dat_tlast   <= fifo_do(8);
              m_dat_tvalid  <= '1';
            else
              m_dat_tdata   <= ( others => '0');
              m_dat_tlast   <= '0';
              m_dat_tvalid  <= '0';
            end if;

            if fifo_do(8) = '1' then
              s_ctrl     <= idle;
            end if;
        end case;
      end if;
  end process;

end architecture rtl;