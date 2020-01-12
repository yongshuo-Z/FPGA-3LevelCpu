`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/22 10:01:49
// Design Name: 
// Module Name: DataBus
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


`define UNINTIALIZED 0
`define BOOTING 1
`define READCACHE 2
`define DDR_TO_CACHE 3
`define READ 1'b0
`define WRITE 1'b1
`define NoBusy 1'b0
`define BUSY 1'b1
`define DONE 1'b1
`define UNDONE 1'b0

module Databus(
input clk100mhz,
input rst,
input [31 : 0] cpu_addr,
input cpu_read_write,
output reg bootdone,
output [31 : 0] cpu_data_toCPU,
output reg DataBus_busy,

output reg Databus_done, 
input [31 : 0] cache_data_fromiMEM,
output [31 : 0] cache_addr_toIMEM,
output [31 : 0] cache_data_toIMEM, 
output reg cache_read_write, 
input [31 : 0] ddr_data_fromDDR,
input ddr_busy , 
input ddr_done , 
output [ 31 : 0] ddr_addr_toDDR , 
output [ 31 : 0] ddr_data_toDDR , 
output reg ddr_read_write , 
input ddr_start_ready , 
output reg sd_mem_read_write,
output [31:0] sd_mem_addr,
input [31:0] sd_mem_data_fromSDMEM,
output reg [31 : 0] sd_mem_data_toSDMEM,
input sd_mem_ready
);

reg ready_toBoot;
reg loadData_DDR_TO_CACHEDone;
reg [31 : 0] ddr_to_imem_count;
reg [31 : 0] ddr_boot_block_count;
reg [31 : 0] ddr_boot_inblock_count;
reg [23: 0] cache_status[3:0];
reg [2 : 0] cur_state;
reg is_first_to_imem_count;
reg is_first_to_ddr_count;
reg [31 : 0] bootdone_idle_count;
reg [31 : 0] ddr_to_imem_firstcell_count;

localparam BLOCK_SIZE=128;
localparam DDR_BLOCK_IN_USE=16;
localparam WAIT_IDEL_LOOP_AFTER_BOOTDONE=256;
localparam DDR_TO_IMEM_FIRSTCELL_INSISTLOOP=256;

always @(posedge clk100mhz or posedge rst)
begin
    if(rst)
    begin
    cur_state=`UNINTIALIZED;
    cache_read_write=`READ;
    ddr_to_imem_count=0;
    sd_mem_read_write=`READ;
    ddr_boot_block_count=0;
    ddr_boot_inblock_count=0;
    ready_toBoot=0;
    bootdone=0;
    loadData_DDR_TO_CACHEDone=0;
    cache_status[0][23]=0;
    cache_status[1][23]=0;
    cache_status[2][23]=0;
    cache_status[3][23]=0;
    is_first_to_ddr_count=1'b1;
    is_first_to_imem_count=1'b1;
    bootdone_idle_count=0;
    ddr_to_imem_firstcell_count=0;
    Databus_done=`UNDONE;
    DataBus_busy=`BUSY;
    end
    else
    begin
    case(cur_state)
        `UNINTIALIZED:
        begin
        if(ready_toBoot)
            begin
            ddr_boot_block_count=0;
            ddr_boot_inblock_count=0;
            cur_state=`BOOTING;
            end
        else if(sd_mem_ready&ddr_start_ready)
            begin
            ready_toBoot=1;
            end
        end

        `BOOTING:
        begin
        DataBus_busy=`BUSY;
        Databus_done=`UNDONE;
        if(bootdone)
        begin
            cur_state=`READCACHE;
        end
        else
        begin
            sd_mem_read_write=`READ;
            is_first_to_ddr_count=0;
            if(ddr_boot_block_count<DDR_BLOCK_IN_USE&~is_first_to_ddr_count)
            begin
                if(ddr_done&~ddr_busy)
                begin
                    if(ddr_boot_inblock_count==BLOCK_SIZE-1)
                    begin
                        ddr_boot_inblock_count=0;
                        ddr_boot_block_count=ddr_boot_block_count+1;
                    end
                    else
                    begin
                        ddr_boot_inblock_count=ddr_boot_inblock_count+1;
                    end
                end

            end

        end
        end

        `READCACHE:
        begin
            cache_read_write=`READ;
            //read cache
            if(cache_status[cpu_addr[8:7]][22:0]==cpu_addr[31:9]
                &cache_status[cpu_addr[8:7]][23]==1'b1)
            //cache ����
            begin
                DataBus_busy=`NoBusy;
                Databus_done=`DONE;
                cur_state=`READCACHE;

            end
            else//cache ������
            begin
                cur_state=`DDR_TO_CACHE;
                DataBus_busy=`BUSY;
                Databus_done=`UNDONE;                
            end
        end

        `DDR_TO_CACHE:
        begin
            DataBus_busy=`BUSY;
            Databus_done=`UNDONE;
            if(loadData_DDR_TO_CACHEDone)
            begin
                loadData_DDR_TO_CACHEDone= `UNDONE;
                cache_status[cpu_addr[8:7]][22:0]=cpu_addr[31:9];
                cache_status[cpu_addr[8:7]][23]=1'b1;
                cache_read_write=`READ;
                cur_state=`READCACHE;
                is_first_to_imem_count=1'b1;
                ddr_to_imem_firstcell_count=0;
                ddr_to_imem_count=0;
                
            end
            else//ddr-->cache(imem)
            begin
                cache_read_write=`WRITE;
                ddr_read_write=`READ;
                if(ddr_to_imem_count<=BLOCK_SIZE-1)
                begin
                    if(ddr_to_imem_firstcell_count < DDR_TO_IMEM_FIRSTCELL_INSISTLOOP)
                    begin
                        ddr_to_imem_firstcell_count=ddr_to_imem_firstcell_count+1;
                    end
                    else
                    begin 
                        is_first_to_imem_count=0;
                    end
                   
                end

                
                if(ddr_done&~is_first_to_imem_count&~ddr_busy)
                begin   
                    if(ddr_to_imem_count==BLOCK_SIZE-1)//д����һ����
                    begin
                        loadData_DDR_TO_CACHEDone=`DONE;
                    end
                    else
                    begin
                        ddr_to_imem_count=ddr_to_imem_count+1;
                    end
                end
            end


        end
   
    endcase
end
end

assign ddr_addr_toDDR=
            (cur_state==`BOOTING)?
            ddr_boot_block_count*BLOCK_SIZE+ddr_boot_inblock_count:
            {cpu_addr[31:7],ddr_to_imem_count[6:0]};
assign sd_mem_addr=ddr_boot_block_count*BLOCK_SIZE+ddr_boot_inblock_count;

assign cache_addr_toIMEM=
            (cur_state== `DDR_TO_CACHE)?
            cpu_addr[8:7]*BLOCK_SIZE+ddr_to_imem_count:cpu_addr[8:0];
//cpu_addr [8:7]-���� [6:0]-����λ��
assign cache_data_toIMEM=ddr_data_fromDDR;
assign cpu_data_toCPU=cache_data_fromiMEM;
assign ddr_data_toDDR=sd_mem_data_fromSDMEM;

endmodule
