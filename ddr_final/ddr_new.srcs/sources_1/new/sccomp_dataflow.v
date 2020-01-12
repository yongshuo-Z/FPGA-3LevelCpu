`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/20 20:52:06
// Design Name: 
// Module Name: sccomp_dataflow
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sccomp_dataflow(
    input clk_in,
    input reset,
    input [15:0] sw,
    output [7:0] o_seg,
    output [7:0] o_sel,


    input SD_CD, 
    output SD_RESET, 
    output SD_SCK, 
    output SD_CMD, 
    inout [3:0] SD_DAT, 
    output [15:0] LED,

    inout [15:0]            ddr2_dq,
    inout [1:0]             ddr2_dqs_n,
    inout [1:0]             ddr2_dqs_p,
    output [12:0]           ddr2_addr,
    output [2:0]            ddr2_ba,
    output                  ddr2_ras_n,
    output                  ddr2_cas_n,
    output                  ddr2_we_n,
    output [0:0]            ddr2_ck_p,
    output [0:0]            ddr2_ck_n,
    output [0:0]            ddr2_cke,
    output [0:0]            ddr2_cs_n,
    output [1:0]            ddr2_dm,
    output [0:0]            ddr2_odt
    );


wire [15:0]led;

wire locked;
wire exc;
wire [31:0]status;
   
wire [31:0]rdata;
wire [31:0]wdata;
wire IM_R,DM_CS,DM_R,DM_W;
wire [31:0]inst,pc,addr;
wire inta,intr;

wire [31:0]data_fmem;

wire [31:0]ip_in;
wire seg7_cs,switch_cs;

assign ip_in = pc-32'h00400000;

assign intr = 0;



wire  clk100mhz;
wire db_rst;
wire [31 : 0] cpu_addr;
wire cpu_read_write;
wire bootdone;
wire  [31 : 0] cpu_data_toCPU;
wire DataBus_busy;
wire Databus_done; 
wire [31 : 0] cache_data_fromiMEM;
wire  [31 : 0] cache_addr_toIMEM;
wire  [31 : 0] cache_data_toIMEM; 
wire cache_read_write; 
wire [31 : 0] ddr_data_fromDDR;
wire ddr_busy ; 
wire ddr_done ; 
wire  [ 31 : 0] ddr_addr_toDDR ; 
wire  [ 31 : 0] ddr_data_toDDR ; 
wire ddr_read_write ; 
wire ddr_start_ready ; 
wire sd_mem_read_write;
wire  [31:0] sd_mem_addr;
wire [31:0] sd_mem_data_fromSDMEM;
wire [31 : 0] sd_mem_data_toSDMEM;
wire sd_mem_ready;


Databus DB(  
  clk100mhz,
 db_rst,
  cpu_addr,
 cpu_read_write,
bootdone,
 cpu_data_toCPU,
DataBus_busy,
Databus_done, 
 cache_data_fromiMEM,
  cache_addr_toIMEM,
  cache_data_toIMEM, 
cache_read_write, 
  ddr_data_fromDDR,
 ddr_busy , 
 ddr_done , 
 ddr_addr_toDDR , 
 ddr_data_toDDR , 
ddr_read_write , 
 ddr_start_ready , 
sd_mem_read_write,
   sd_mem_addr,
 sd_mem_data_fromSDMEM,
 sd_mem_data_toSDMEM,
sd_mem_ready
);



// wire clk = clk_in;
// wire rst=reset;

wire clk;
wire rst=reset|~locked;

////--------------------debug-------------------------------
clk_wiz_1 clk_inst
  (
  
   .clk_out1(clk),     // output clk_out1

   .reset(reset), // input reset
   .locked(locked),       // output locked
  // Clock in ports
   .clk_in1(clk_in)
   ); 
   
wire imem_stuck;
wire imem_ready;
//rdata ��dmem�ж�ȡ��������
static_cpu sccpu(clk,reset,inst,rdata,pc,addr,wdata,IM_R,DM_CS,DM_R,DM_W,intr,inta, imem_stuck, imem_ready);



assign LED={led[15:7], ip_in[6:2], imem_stuck, imem_ready};




    
    
ddrmem_controller ddr_ctrl(
    .rst(rst),
    .clk100mhz_in(clk_in),
    .led(led),
    .SD_CD(SD_CD), 
    .SD_RESET(SD_RESET), 
    .SD_SCK(SD_SCK), 
    .SD_CMD(SD_CMD), 
    .SD_DAT(SD_DAT),

    .ddr_init(imem_stuck),
    .ddr_ready(imem_ready),
    .ddrmem_addr_ctl(ip_in),
    .ddrmem_data(inst),
    /*************************/
        .ddr2_dq(ddr2_dq),
        .ddr2_dqs_n(ddr2_dqs_n),
        .ddr2_dqs_p(ddr2_dqs_p),
        .ddr2_addr(ddr2_addr),
        .ddr2_ba(ddr2_ba),
        .ddr2_ras_n(ddr2_ras_n),
        .ddr2_cas_n(ddr2_cas_n),
        .ddr2_we_n(ddr2_we_n),
        .ddr2_ck_p(ddr2_ck_p),
        .ddr2_ck_n(ddr2_ck_n),
        .ddr2_cke(ddr2_cke),
        .ddr2_cs_n(ddr2_cs_n),
        .ddr2_dm(ddr2_dm),
        .ddr2_odt(ddr2_odt)
);

    
wire [31:0]addr_in=addr-32'h10010000;

/*���ݴ洢��*/
dist_dmem_ip DMEM (
  .a(addr_in[12:2]),      // input wire [10 : 0] a
  .d(wdata),      // input wire [31 : 0] d
  .clk(clk),  // input wire clk
  .we(DM_W),    // input wire we
  .spo(data_fmem)  // output wire [31 : 0] spo
);


/*��ַ����*/


seg7x16 seg7(clk, reset, 1'b1, wdata, o_seg, o_sel);

sw_mem_sel sw_mem(switch_cs, sw, data_fmem, rdata);
   
endmodule
