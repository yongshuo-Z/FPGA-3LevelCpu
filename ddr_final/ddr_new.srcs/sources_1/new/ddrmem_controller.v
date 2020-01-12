`timescale 1ns / 1ps

`define NoBusy 1'b0
`define Busy 1'b1
`define DONE 1'b1
`define UNDONE 1'b0
`define READ 1'b0
`define WRITE 1'b1


module ddrmem_controller (
    input rst,
    input clk100mhz_in,
    output [15:0]led,
    input SD_CD, 
    output SD_RESET, 
    output SD_SCK, 
    output SD_CMD, 
    inout [3:0] SD_DAT,

    input ddr_init,
    output ddr_ready,
    input [31:0]ddrmem_addr_ctl,
    output [31:0]ddrmem_data,
    /*************************/
    inout [15:0]            ddr2_dq,
    inout [1:0]             ddr2_dqs_n,
    inout [1:0]             ddr2_dqs_p,
    output [12:0]           ddr2_addr,
    output [2:0]            ddr2_ba,
    output                  ddr2_ras_n,
    output                  ddr2_cas_n,
    output                  ddr2_we_n,
    output                  ddr2_ck_p,
    output                  ddr2_ck_n,
    output                  ddr2_cke,
    output                  ddr2_cs_n,
    output [1:0]            ddr2_dm,
    output [0:0]            ddr2_odt
);

parameter S_IDLE = 0;
parameter S_WRITE_WAIT = 1;//�ȴ�sd��ʼ��
parameter S_WRITE_PRE = 2;
parameter S_WRITE = 3;
parameter S_WAIT = 4;

    

   

reg init_sd;//�����ź�ʹ��sd��ʼ��
wire ready_sd;//sd��ʼ������ź�?
wire [31:0]data_sd;//sd������������
reg [31:0]adr_sdmem;//��ȡsdmem�������õĵ�ַ

wire [15:0]LED;

 wire [1:0] rdqs_n;

    wire [127:0]data_in;
    reg seg7_cs;
    reg [31:0]seg_data_i;
    wire clk200mhz;
    reg Read_Write;
    wire [31:0] out_ddr_data;


    assign ddrmem_data = out_ddr_data;


    wire [31:0]adr_in_ddr;
    wire [127:0]data_from_DDR;
    assign data_in = {96'h0, data_sd};
    wire ddr_busy;
    wire done_ddr;
    reg [31:0]addr_ddr;
    reg [31:0]addr_ddr_mem;
  
    // wire temp_read_write,temp_ack;
    sealedDDR DDR_sealed(
        .clk100mhz(clk100mhz_in),
        .rst(rst),
        .addr_to_DDR(adr_in_ddr),
        .data_to_DDR(data_in),
        .Read_Write(Read_Write),
        .data_from_DDR(data_from_DDR),
        .busy(ddr_busy),
        .done(done_ddr),
        /************************/
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

labkit sdlab(
    .CLK100MHZ(CLK100MHZ), 
    .SD_CD(SD_CD), 
    .SD_RESET(SD_RESET), 
    .SD_SCK(SD_SCK), 
    .SD_CMD(SD_CMD), 
    .SD_DAT(SD_DAT), 
    .LED(LED), 
    .BTNC(BTNC), 
    .adr_sdmem(adr_sdmem), 
    .data_out(data_out), 
    .init_sd(init_sd), 
    .ready_sd(ready_sd)
    );


reg [3:0] state;



reg first_write;
reg [10:0]B_cnt;//2048��

assign adr_in_ddr = (state == S_WAIT)?addr_ddr_mem:addr_ddr;

always @(posedge clk100mhz_in or posedge rst) 
begin
    if (rst) 
    begin
        state <= S_IDLE;
        first_write <= 1;
        adr_sdmem <= 0;
        addr_ddr <= 0;
        B_cnt <= 0;
    end
    else 
    begin
        case(state)
            S_IDLE:
            begin
                if(ddr_init)
                begin
                    init_sd <= 1;
                    state <= S_WRITE_WAIT;
                end
            end
            S_WRITE_WAIT:
            begin
                if (ready_sd) 
                begin
                    state <= S_WRITE;
                    init_sd <= 0;
                end
            end
           
            S_WRITE:
            begin
                if (done_ddr) 
                begin
                    if (first_write) 
                    begin//��һ��дddr��
                        first_write <= 0;
                        adr_sdmem <= 0;
                        Read_Write <= 1;
                        addr_ddr <= 0;
                        state <= S_WRITE;
                        B_cnt <= B_cnt + 1;
                    end
                    else 
                    begin
                        if (B_cnt == 11'd2047) 
                        begin
                            B_cnt <= 0;
                            state <= S_WAIT;
                            Read_Write <= 0;
                            adr_sdmem <= 0;
                            addr_ddr <= 0;
                        end
                        else 
                        begin
                            B_cnt <= B_cnt + 1;
                            state <= S_WRITE;
                            Read_Write <= 1;
                            adr_sdmem <= adr_sdmem + 4;
                            addr_ddr <= addr_ddr + 8;
                        end
                    end
                end
            end
            S_WAIT:
            begin
                state <= S_WAIT;
                addr_ddr<=0;
            end
        endcase
    end
end

reg [3:0]state_ddrmem;

reg we_ddrmem;
reg [31:0]ddrmem_data_in;
reg [31:0]ddrmem_addr;
wire [31:0]ddrmem_adr;
assign  ddrmem_adr = (state_ddrmem == S_WAIT)?ddrmem_addr_ctl:ddrmem_addr;

assign ddr_ready = (state_ddrmem == S_WAIT)?1'b1:1'b0;

reg ddrmem_first_write;

reg [10:0]ddrmem_byte_cnt;//2048

    /*���ݴ洢��*/


always @(posedge clk100mhz_in or posedge rst) 
begin
    if (rst) 
    begin
        ddrmem_addr <= 0;
        state_ddrmem <= S_IDLE;
        ddrmem_first_write <= 1;
        ddrmem_data_in <= 0;
        ddrmem_byte_cnt <= 0;
        addr_ddr_mem <= 0;
        we_ddrmem <= 0;
       
        
    end
    else 
    begin
         case(state_ddrmem)
            S_IDLE:
            begin
                if (state == S_WAIT) 
                begin
                    ddrmem_addr <= 0 - 4;
                    ddrmem_byte_cnt <= 0;
                    state_ddrmem <= S_WRITE;
                    addr_ddr_mem <= 0;
                    
                end
            end
            S_WRITE:
            begin
                if (done_ddr) 
                begin
                    ddrmem_data_in <= data_from_DDR[31:0];
                    if (ddrmem_byte_cnt == 11'd2047) 
                    begin
                        we_ddrmem <= 0;
                        addr_ddr_mem <= 0;
                        state_ddrmem <= S_WAIT;
                        ddrmem_addr <= 0;
                        ddrmem_byte_cnt <= 0;
                    end
                    else 
                    begin
                        ddrmem_addr <= ddrmem_addr + 4;
                        state_ddrmem <= S_WRITE;
                        we_ddrmem <= 1;
                        addr_ddr_mem <= addr_ddr_mem + 8;
                        
                        ddrmem_byte_cnt <= ddrmem_byte_cnt + 1;
                    end
                end
                else 
                    we_ddrmem <= 0;
            end
            S_WAIT:
            begin
                state_ddrmem <= S_WAIT;
                we_ddrmem <= 0;
            end
        endcase

    end
end

dist_ddrmem_ip Cache (
      .a(ddrmem_adr[12:2]),      // input wire [10 : 0] a
      .d(ddrmem_data_in),      // input wire [31 : 0] d
      .clk(clk100mhz_in),  // input wire clk
      .we(we_ddrmem),    // input wire we
      .spo(out_ddr_data)  // output wire [31 : 0] spo
    );

assign led = {LED[15:4], state_ddrmem};

endmodule
//done