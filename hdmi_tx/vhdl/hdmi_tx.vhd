------------------------------------------------------------------------------
--  HDMI transmitter
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_misc.all;

Library UNISIM;
use     UNISIM.vcomponents.all;

entity hdmi_tx is
  port(
    clk               : in  std_logic;  --system clock
    reset_n           : in  std_logic;  --active low reset

    hdmi_tx_clk_n	    : out std_logic;
    hdmi_tx_clk_p	    : out std_logic;
    hdmi_tx_chn_r_n	  : out std_logic;
    hdmi_tx_chn_r_p	  : out std_logic;
    hdmi_tx_chn_g_n	  : out std_logic;
    hdmi_tx_chn_g_p	  : out std_logic;
    hdmi_tx_chn_b_n	  : out std_logic;
    hdmi_tx_chn_b_p	  : out std_logic;

    led               : out std_logic
  );
end hdmi_tx;

architecture rtl of hdmi_tx is

  signal  locked 	    : std_logic;
  signal  rst 		    : std_logic;
  signal  reset  	    : std_logic;
  signal  clk1x 	    : std_logic;    --! 148.5 MHz
  signal  clk5x 	    : std_logic;    --! 742.5 MHz
  signal  clkfb 	    : std_logic;
  signal  rgb_r       : std_logic_vector(7 downto 0);
  signal  rgb_g       : std_logic_vector(7 downto 0);
  signal  rgb_b       : std_logic_vector(7 downto 0);
  signal  vpg_de 	    : std_logic;
  signal  vpg_hs    	: std_logic;
  signal  vpg_vs 	    : std_logic;

begin

  reset    <= not reset_n;
  rst      <= not locked;
  led      <= rst ;

--! we need a PLL to make 148.5 and 742.5 MHz from the 50 MHz
--! that ratio is 14.85 , PLL needs a number that is with a granularity off 0.125


   --! device macro for a PLL
--   PLLE2_BASE_inst : PLLE2_BASE
--   generic map (
--      BANDWIDTH       => "OPTIMIZED",  -- OPTIMIZED, HIGH, LOW
--      CLKFBOUT_MULT   => 30,        -- Multiply value for all CLKOUT, (2-64)
--      CLKFBOUT_PHASE  => 0.0,       -- Phase offset in degrees of CLKFB, (-360.000-360.000).
--      CLKIN1_PERIOD   => 0.0,       -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
--      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
--      CLKOUT0_DIVIDE => 10,
--      CLKOUT1_DIVIDE => 2,
--      CLKOUT2_DIVIDE => 1,
--      CLKOUT3_DIVIDE => 1,
--      CLKOUT4_DIVIDE => 1,
--      CLKOUT5_DIVIDE => 1,
--      -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
--      CLKOUT0_DUTY_CYCLE => 0.5,
--      CLKOUT1_DUTY_CYCLE => 0.5,
--      CLKOUT2_DUTY_CYCLE => 0.5,
--      CLKOUT3_DUTY_CYCLE => 0.5,
--      CLKOUT4_DUTY_CYCLE => 0.5,
--      CLKOUT5_DUTY_CYCLE => 0.5,
--      -- CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
--      CLKOUT0_PHASE => 0.0,
--      CLKOUT1_PHASE => 0.0,
--      CLKOUT2_PHASE => 0.0,
--      CLKOUT3_PHASE => 0.0,
--      CLKOUT4_PHASE => 0.0,
--      CLKOUT5_PHASE => 0.0,
--      DIVCLK_DIVIDE => 1,           -- Master division value, (1-56)
--      REF_JITTER1   => 0.0,         -- Reference input jitter in UI, (0.000-0.999).
--      STARTUP_WAIT  => "FALSE"      -- Delay DONE until PLL Locks, ("TRUE"/"FALSE")
--   )
--   port map (
--      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
--      CLKOUT0 => clk1x,  -- 1-bit output: CLKOUT0
--      CLKOUT1 => clk5x,  -- 1-bit output: CLKOUT1
--      CLKOUT2 => open,   -- 1-bit output: CLKOUT2
--      CLKOUT3 => open,   -- 1-bit output: CLKOUT3
--      CLKOUT4 => open,   -- 1-bit output: CLKOUT4
--      CLKOUT5 => open,   -- 1-bit output: CLKOUT5
--      -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
--      CLKFBOUT=> clkfb,  -- 1-bit output: Feedback clock
--      LOCKED  => locked,     -- 1-bit output: LOCK
--      CLKIN1  => clk,        -- 1-bit input: Input clock
--      -- Control Ports: 1-bit (each) input: PLL control ports
--      PWRDWN  => '0',        -- 1-bit input: Power-down
--      RST     => reset,      -- 1-bit input: Reset
--      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
--      CLKFBIN => clkfb      -- 1-bit input: Feedback clock
--   );


   -- MMCME2_BASE: Base Mixed Mode Clock Manager
   --              Artix-7
   -- Xilinx HDL Language Template, version 2023.1

   MMCME2_BASE_inst : MMCME2_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",  -- Jitter programming (OPTIMIZED, HIGH, LOW)
      CLKFBOUT_MULT_F => 14.875,    -- Multiply value for all CLKOUT (2.000-64.000).
      CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB (-360.000-360.000).
      CLKIN1_PERIOD => 0.0,      -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      CLKOUT1_DIVIDE => 5,
      CLKOUT2_DIVIDE => 1,
      CLKOUT3_DIVIDE => 1,
      CLKOUT4_DIVIDE => 1,
      CLKOUT5_DIVIDE => 1,
      CLKOUT6_DIVIDE => 1,
      CLKOUT0_DIVIDE_F => 1.0,   -- Divide amount for CLKOUT0 (1.000-128.000).
      -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT6_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 0.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      CLKOUT6_PHASE => 0.0,
      CLKOUT4_CASCADE => FALSE,  -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      DIVCLK_DIVIDE => 1,        -- Master division value (1-106)
      REF_JITTER1 => 0.0,        -- Reference input jitter in UI (0.000-0.999).
      STARTUP_WAIT => FALSE      -- Delays DONE until MMCM is locked (FALSE, TRUE)
   )
   port map (
      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
      CLKOUT0 => clk5x,     -- 1-bit output: CLKOUT0
      CLKOUT0B => open,   -- 1-bit output: Inverted CLKOUT0
      CLKOUT1 => clk1x,     -- 1-bit output: CLKOUT1
      CLKOUT1B => open,   -- 1-bit output: Inverted CLKOUT1
      CLKOUT2 => open,     -- 1-bit output: CLKOUT2
      CLKOUT2B => open,   -- 1-bit output: Inverted CLKOUT2
      CLKOUT3 => open,     -- 1-bit output: CLKOUT3
      CLKOUT3B => open,   -- 1-bit output: Inverted CLKOUT3
      CLKOUT4 => open,     -- 1-bit output: CLKOUT4
      CLKOUT5 => open,     -- 1-bit output: CLKOUT5
      CLKOUT6 => open,     -- 1-bit output: CLKOUT6
      -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
      CLKFBOUT => clkfb,   -- 1-bit output: Feedback clock
      CLKFBOUTB => open, -- 1-bit output: Inverted CLKFBOUT
      -- Status Ports: 1-bit (each) output: MMCM status ports
      LOCKED => locked,       -- 1-bit output: LOCK
      -- Clock Inputs: 1-bit (each) input: Clock input
      CLKIN1 => clk,       -- 1-bit input: Clock
      -- Control Ports: 1-bit (each) input: MMCM control ports
      PWRDWN => '0',       -- 1-bit input: Power-down
      RST => reset,             -- 1-bit input: Reset
      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
      CLKFBIN => clkfb      -- 1-bit input: Feedback clock
   );

					

  -- generate some dummy color pattern
	i_vga_shift: entity work.vga_shift
    port map(
      rst      => rst,
			vpg_pclk => clk1x,
			vpg_de   => vpg_de,
			vpg_hs   => vpg_hs,
			vpg_vs   => vpg_vs,
			rgb_r    => rgb_r,
			rgb_g    => rgb_g,
			rgb_b    => rgb_b
		);

  -- drive the HDMI signals
	i_hdmi_trans: entity work.hdmi_trans
    port map(
			clk1x           => clk1x,
			clk5x           => clk5x,
			rst             => rst,
			image_r         => rgb_r,
			image_g         => rgb_g,
			image_b         => rgb_b,
			vsync           => vpg_vs,
			hsync           => vpg_hs,
			de              => vpg_de,
			hdmi_tx_clk_n   => hdmi_tx_clk_n,
			hdmi_tx_clk_p   => hdmi_tx_clk_p,
			hdmi_tx_chn_r_n => hdmi_tx_chn_r_n,
			hdmi_tx_chn_r_p => hdmi_tx_chn_r_p,
			hdmi_tx_chn_g_n => hdmi_tx_chn_g_n,
			hdmi_tx_chn_g_p => hdmi_tx_chn_g_p,
			hdmi_tx_chn_b_n => hdmi_tx_chn_b_n,
			hdmi_tx_chn_b_p => hdmi_tx_chn_b_p
		);

end rtl;