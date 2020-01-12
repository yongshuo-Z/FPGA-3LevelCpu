// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Sun Dec 15 19:41:27 2019
// Host        : DESKTOP-U8GI32S running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/Desktop/ddr_new/ddr_new.srcs/sources_1/ip/dist_ddrmem_ip/dist_ddrmem_ip_stub.v
// Design      : dist_ddrmem_ip
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "dist_mem_gen_v8_0_12,Vivado 2018.3" *)
module dist_ddrmem_ip(a, d, clk, we, spo)
/* synthesis syn_black_box black_box_pad_pin="a[8:0],d[31:0],clk,we,spo[31:0]" */;
  input [8:0]a;
  input [31:0]d;
  input clk;
  input we;
  output [31:0]spo;
endmodule
