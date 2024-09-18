--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
--Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2023.1 (win64) Build 3865809 Sun May  7 15:05:29 MDT 2023
--Date        : Wed Sep 18 20:24:42 2024
--Host        : vivobook running 64-bit major release  (build 9200)
--Command     : generate_target bd_base_wrapper.bd
--Design      : bd_base_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity bd_base_wrapper is
  port (
    AXI_STR_RXD_0_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI_STR_RXD_0_tlast : in STD_LOGIC;
    AXI_STR_RXD_0_tready : out STD_LOGIC;
    AXI_STR_RXD_0_tvalid : in STD_LOGIC;
    AXI_STR_TXD_0_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI_STR_TXD_0_tlast : out STD_LOGIC;
    AXI_STR_TXD_0_tready : in STD_LOGIC;
    AXI_STR_TXD_0_tvalid : out STD_LOGIC;
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    FCLK_CLK0_0 : out STD_LOGIC;
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    interrupt_0 : out STD_LOGIC;
    mm2s_prmry_reset_out_n_0 : out STD_LOGIC;
    s2mm_prmry_reset_out_n_0 : out STD_LOGIC
  );
end bd_base_wrapper;

architecture STRUCTURE of bd_base_wrapper is
  component bd_base is
  port (
    DDR_cas_n : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    AXI_STR_TXD_0_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI_STR_TXD_0_tlast : out STD_LOGIC;
    AXI_STR_TXD_0_tready : in STD_LOGIC;
    AXI_STR_TXD_0_tvalid : out STD_LOGIC;
    AXI_STR_RXD_0_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI_STR_RXD_0_tlast : in STD_LOGIC;
    AXI_STR_RXD_0_tready : out STD_LOGIC;
    AXI_STR_RXD_0_tvalid : in STD_LOGIC;
    interrupt_0 : out STD_LOGIC;
    mm2s_prmry_reset_out_n_0 : out STD_LOGIC;
    s2mm_prmry_reset_out_n_0 : out STD_LOGIC;
    FCLK_CLK0_0 : out STD_LOGIC
  );
  end component bd_base;
begin
bd_base_i: component bd_base
     port map (
      AXI_STR_RXD_0_tdata(31 downto 0) => AXI_STR_RXD_0_tdata(31 downto 0),
      AXI_STR_RXD_0_tlast => AXI_STR_RXD_0_tlast,
      AXI_STR_RXD_0_tready => AXI_STR_RXD_0_tready,
      AXI_STR_RXD_0_tvalid => AXI_STR_RXD_0_tvalid,
      AXI_STR_TXD_0_tdata(31 downto 0) => AXI_STR_TXD_0_tdata(31 downto 0),
      AXI_STR_TXD_0_tlast => AXI_STR_TXD_0_tlast,
      AXI_STR_TXD_0_tready => AXI_STR_TXD_0_tready,
      AXI_STR_TXD_0_tvalid => AXI_STR_TXD_0_tvalid,
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FCLK_CLK0_0 => FCLK_CLK0_0,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      interrupt_0 => interrupt_0,
      mm2s_prmry_reset_out_n_0 => mm2s_prmry_reset_out_n_0,
      s2mm_prmry_reset_out_n_0 => s2mm_prmry_reset_out_n_0
    );
end STRUCTURE;
