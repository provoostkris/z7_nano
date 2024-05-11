------------------------------------------------------------------------------
--  output serializer deserializer
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_misc.all;

Library UNISIM;
use     UNISIM.vcomponents.all;

entity oserdes is
  port(
    clk1x  : in  std_logic;
    clk5x  : in  std_logic;
    rst    : in  std_logic;
    din    : in  std_logic_vector(9 downto 0);
    dout_p : out std_logic;
    dout_n : out std_logic
  );
end oserdes;

architecture rtl of oserdes is

  signal    dout       : std_logic;
  signal    shift_in1  : std_logic;
  signal    shift_in2  : std_logic;

begin


   -- OBUFDS: Differential Output Buffer
   --         Artix-7
   -- Xilinx HDL Language Template, version 2023.1

   OBUFDS_inst : OBUFDS
   generic map (
      IOSTANDARD => "DEFAULT", -- Specify the output I/O standard
      SLEW => "SLOW")          -- Specify the output slew rate
   port map (
      O => dout_p,     -- Diff_p output (connect directly to top-level port)
      OB => dout_n,    -- Diff_n output (connect directly to top-level port)
      I => dout        -- Buffer input
   );


   -- OSERDESE2: Output SERial/DESerializer with bitslip
   --            Artix-7
   -- Xilinx HDL Language Template, version 2023.1

   OSERDESE2_inst_master : OSERDESE2
   generic map (
      DATA_RATE_OQ => "DDR",   -- DDR, SDR
      DATA_RATE_TQ => "SDR",   -- DDR, BUF, SDR
      DATA_WIDTH => 10,        -- Parallel data width (2-8,10,14)
      INIT_OQ => '0',          -- Initial value of OQ output (1'b0,1'b1)
      INIT_TQ => '0',          -- Initial value of TQ output (1'b0,1'b1)
      SERDES_MODE => "MASTER", -- MASTER, SLAVE
      SRVAL_OQ => '0',         -- OQ output value when SR is used (1'b0,1'b1)
      SRVAL_TQ => '0',         -- TQ output value when SR is used (1'b0,1'b1)
      TBYTE_CTL => "FALSE",    -- Enable tristate byte operation (FALSE, TRUE)
      TBYTE_SRC => "FALSE",    -- Tristate byte source (FALSE, TRUE)
      TRISTATE_WIDTH => 1      -- 3-state converter width (1,4)
   )
   port map (
      OFB => open,             -- 1-bit output: Feedback path for data
      OQ => dout,               -- 1-bit output: Data path output
      -- SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
      SHIFTOUT1 => open,
      SHIFTOUT2 => open,
      TBYTEOUT => open,   -- 1-bit output: Byte group tristate
      TFB => open,             -- 1-bit output: 3-state control
      TQ => open,               -- 1-bit output: 3-state control
      CLK => clk5x,             -- 1-bit input: High speed clock
      CLKDIV => clk1x,       -- 1-bit input: Divided clock
      -- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
      D1 => din(0),
      D2 => din(1),
      D3 => din(2),
      D4 => din(3),
      D5 => din(4),
      D6 => din(5),
      D7 => din(6),
      D8 => din(7),
      OCE => '1',             -- 1-bit input: Output data clock enable
      RST => rst,             -- 1-bit input: Reset
      -- SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
      SHIFTIN1 => shift_in1,
      SHIFTIN2 => shift_in2,
      -- T1 - T4: 1-bit (each) input: Parallel 3-state inputs
      T1 => '0',
      T2 => '0',
      T3 => '0',
      T4 => '0',
      TBYTEIN => '0',     -- 1-bit input: Byte group tristate
      TCE => '0'              -- 1-bit input: 3-state clock enable
   );


   -- OSERDESE2: Output SERial/DESerializer with bitslip
   --            Artix-7
   -- Xilinx HDL Language Template, version 2023.1

   OSERDESE2_inst_slave : OSERDESE2
   generic map (
      DATA_RATE_OQ => "DDR",   -- DDR, SDR
      DATA_RATE_TQ => "SDR",   -- DDR, BUF, SDR
      DATA_WIDTH => 10,        -- Parallel data width (2-8,10,14)
      INIT_OQ => '0',          -- Initial value of OQ output (1'b0,1'b1)
      INIT_TQ => '0',          -- Initial value of TQ output (1'b0,1'b1)
      SERDES_MODE => "SLAVE",  -- MASTER, SLAVE
      SRVAL_OQ => '0',         -- OQ output value when SR is used (1'b0,1'b1)
      SRVAL_TQ => '0',         -- TQ output value when SR is used (1'b0,1'b1)
      TBYTE_CTL => "FALSE",    -- Enable tristate byte operation (FALSE, TRUE)
      TBYTE_SRC => "FALSE",    -- Tristate byte source (FALSE, TRUE)
      TRISTATE_WIDTH => 1      -- 3-state converter width (1,4)
   )
   port map (
      OFB => open,             -- 1-bit output: Feedback path for data
      OQ => open,               -- 1-bit output: Data path output
      -- SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
      SHIFTOUT1 => shift_in1,
      SHIFTOUT2 => shift_in2,
      TBYTEOUT => open,   -- 1-bit output: Byte group tristate
      TFB => open,             -- 1-bit output: 3-state control
      TQ => open,               -- 1-bit output: 3-state control
      CLK => clk5x,             -- 1-bit input: High speed clock
      CLKDIV => clk1x,       -- 1-bit input: Divided clock
      -- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
      D1 => '0',
      D2 => '0',
      D3 => din(8),
      D4 => din(9),
      D5 => '0',
      D6 => '0',
      D7 => '0',
      D8 => '0',
      OCE => '1',             -- 1-bit input: Output data clock enable
      RST => rst,             -- 1-bit input: Reset
      -- SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
      SHIFTIN1 => '0',
      SHIFTIN2 => '0',
      -- T1 - T4: 1-bit (each) input: Parallel 3-state inputs
      T1 => '0',
      T2 => '0',
      T3 => '0',
      T4 => '0',
      TBYTEIN => '0',     -- 1-bit input: Byte group tristate
      TCE => '0'              -- 1-bit input: 3-state clock enable
   );

end rtl;