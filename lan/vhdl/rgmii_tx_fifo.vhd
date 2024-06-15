------------------------------------------------------------------------------
--  rgmii interfqce fifo with dual clock domain
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

Library UNISIM;
use     UNISIM.vcomponents.all;

Library UNIMACRO;
use     UNIMACRO.vcomponents.all;

-------------------------------------------------------------------------------
entity rgmii_tx_fifo is

  port (
    -- axis interface from user logic
    s_clk         : in  std_logic;
    s_rst_n       : in  std_logic;
    s_dat_tready  : out std_logic;
    s_dat_tdata   : in  std_logic_vector(7 downto 0);
    s_dat_tlast   : in  std_logic;
    s_dat_tvalid  : in  std_logic;

    -- interface to rgmii phy
    m_clk         : in  std_logic;
    m_rst_n       : in  std_logic;
    m_txdata      : out std_logic_vector(7 downto 0);
    m_sof         : in  std_logic;
    m_eof         : out std_logic;
    m_genframe    : out std_logic;
    m_genframeack : in  std_logic
    );

end entity rgmii_tx_fifo;
-------------------------------------------------------------------------------
architecture rtl of rgmii_tx_fifo is

  type t_state is ( tx_frame_req,
                    tx_frame_ack,
                    tx_frame_sof,
                    tx_frame_data
                  );
  signal s_ctrl                      : t_state;
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
  fifo_di       <= s_dat_tlast & s_dat_tdata;


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
      FIRST_WORD_FALL_THROUGH => true) -- Sets the FIFO FWFT to TRUE or FALSE
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
      WREN => s_dat_tvalid                  -- 1-bit input write enable
   );
   -- End of FIFO_DUALCLOCK_MACRO_inst instantiation

  --! RGMII flow controller
  process(m_rst_n, m_clk) is
  begin
      if m_rst_n='0' then
        fifo_rden  <= '0';
        m_genframe <= '0';
        m_txdata   <= ( others => '0');
        m_eof      <= '0';
      elsif rising_edge(m_clk) then
        case s_ctrl is
          when tx_frame_req =>
            m_txdata   <= ( others => '0');
            m_eof      <= '0';
            if fifo_empty = '0' then
              m_genframe <= '1';
              s_ctrl     <= tx_frame_ack;
            end if;
          when tx_frame_ack =>
            if m_genframeack = '1' then
              m_genframe <= '0';
              s_ctrl     <= tx_frame_sof;
            end if;
          when tx_frame_sof =>
            if m_sof = '1' then
              s_ctrl     <= tx_frame_data;
              fifo_rden  <= '1';
            end if;
          when tx_frame_data =>
            if fifo_do(8) = '1' then
              s_ctrl     <= tx_frame_req;
              fifo_rden  <= '0';
            end if;
            m_txdata    <= fifo_do(7 downto 0);
            m_eof       <= fifo_do(8);
        end case;
      end if;
  end process;


  --! slave flow control
  process(s_rst_n, s_clk) is
  begin
      if s_rst_n='0' then
        s_dat_tready  <= '0';
      elsif rising_edge(s_clk) then
        s_dat_tready  <= not fifo_a_full;
      end if;
  end process;

end architecture rtl;
