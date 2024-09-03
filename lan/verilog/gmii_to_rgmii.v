// --------------------------------------------------------------------
// Copyright (c) 2022 by MicroPhase Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   MicroPhase grants permission to use and modify this code for use
//   in synthesis for all MicroPhase Development Boards.
//   Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  MicroPhase provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     MicroPhase Technologies Inc
//                     Shanghai, China
//
//                     web: http://www.microphase.cn/   
//                     email: support@microphase.cn
//
// --------------------------------------------------------------------
// --------------------------------------------------------------------
//   
// Major Functions:   
//
// --------------------------------------------------------------------
// --------------------------------------------------------------------
//
//  Revision History    
//  Date          By            Revision    Change Description
//---------------------------------------------------------------------
// 2022.07.26     Ao Guohua     1.0          Original
//                                                      
// --------------------------------------------------------------------
// --------------------------------------------------------------------
//将gmii接口转化为rgmii接口
  module gmii_to_rgmii(
      input                rst         , //复位信号
      input                idelay_clk  ,
      //gmii  接口    
      input                gmii_txc    ,
      input                gmii_tx_dv  ,
      input                gmii_tx_err ,
      input       [7:0]    gmii_td     ,
       //rgmii 接口
      output               rgmii_txc   ,
      output               rgmii_tx_ctl,
      output       [3:0]   rgmii_td    
      );
//  clk_phase_shift clk_phase_shift
//   (
//    // Clock out ports
//    .clk_out1(rgmii_txc),     // output clk_out1
//    // Status and control signals
//    .reset(rst), // input reset
//    .locked(),       // output locked
//   // Clock in ports
//    .clk_in1(gmii_txc));      // input clk_in1
    assign rgmii_txc=gmii_txc;

  //rgmii_rx_ctl
      ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
      .INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
      ) ODDR_inst0(
      .Q(rgmii_tx_ctl), // 1-bit DDR output
      .C(rgmii_txc), // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(gmii_tx_dv), // 1-bit data input (positive edge)
      .D2(gmii_tx_err^gmii_tx_dv), // 1-bit data input (negative edge)
      .R(1'b0), // 1-bit reset
      .S(rst) // 1-bit set
      );
  //rgmii_rd
  generate
      genvar i;
      for (i = 0;i<4 ; i=i+1) begin
         ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
      .INIT(1'b0), // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
      ) ODDR_inst1(
      .Q(rgmii_td[i]), // 1-bit DDR output
      .C(rgmii_txc), // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(gmii_td[i]), // 1-bit data input (positive edge)
      .D2(gmii_td[i+4]), // 1-bit data input (negative edge)
      .R(1'b0), // 1-bit reset
      .S(rst) // 1-bit set
      ); 
          
      end
  endgenerate
  endmodule
