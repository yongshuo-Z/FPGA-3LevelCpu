`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/15 10:17:25
// Design Name: 
// Module Name: CP0
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


module CP0(
input clk,
input rst, 
input mfc0,            // CPU instruction is Mfc0
input mtc0,            // CPU instruction is Mtc0 
input [31:0]pc, 
input [4:0] Rd,        // Specifies Cp0 register 
input [31:0] wdata,    // Data from GP register to replace CP0 register
input exception, 
input eret,            // Instruction is ERET (Exception Return) 
input [4:0]cause, 
input intr, 
output [31:0] rdata,      // Data from CP0 register for GP register 
output [31:0] status, 
output reg timer_int, 
output [31:0]exc_addr    // Address for PC at the beginning of an exception 
); 

//syscall>break>teq>eret
reg [31:0]CP0_array_reg[31:0];
assign status=CP0_array_reg[12];
assign exc_addr=eret?CP0_array_reg[14]:32'd4;
assign rdata=mfc0?CP0_array_reg[Rd]:32'b0;


wire syscall =(cause==5'b01000)?1'b1:1'b0;
wire break =(cause==5'b01001)?1'b1:1'b0;
wire teq =(cause==5'b01101)?1'b1:1'b0;

wire exception_excute= exception & CP0_array_reg[12][0] & ((CP0_array_reg[12][1] & syscall) | (CP0_array_reg[12][2] & break) | (CP0_array_reg[12][3] & teq));
reg sll_5;

integer i,j;
always @(negedge clk or posedge rst) begin
  if (rst) begin
    for(i=0;i<12;i=i+1)begin
      CP0_array_reg[i]<=32'b0;
    end
    for(j=13;j<32;j=j+1)begin
      CP0_array_reg[j]<=32'b0;
    end
    CP0_array_reg[12]<=32'h0000000f;
    sll_5<=1'b0;
  end
  else begin
    if (exception_excute & (~sll_5))begin
      CP0_array_reg[12]<=CP0_array_reg[12]<<5;
      CP0_array_reg[13][6:2]<=cause;
      // CP0_array_reg[14]<=pc;
      CP0_array_reg[14]<=pc + 4;//为了兼容流水线 在id阶段判断，此时IF中的值为pc + 4, 因此下一条指令应该是pc + 8 .  但是测试测序中会在eret之前给[14]加4
      sll_5<=1'b1;
    end
    if(eret & sll_5)begin
      CP0_array_reg[12]<=CP0_array_reg[12]>>5;
      sll_5<=1'b0;
    end
    if (mtc0) begin
      CP0_array_reg[Rd]<=wdata;
    end   
  end
end

endmodule
