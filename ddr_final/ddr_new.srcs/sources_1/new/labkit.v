`timescale 1ns / 1ps

module labkit(
    input CLK100MHZ, 
    input SD_CD, 
    output SD_RESET, 
    output SD_SCK, 
    output SD_CMD, 
    inout [3:0] SD_DAT, 
    output [15:0] LED, 
    input BTNC, 
    input [31:0] adr_sdmem, 
    output [31:0] data_out, 
    input init_sd, 
    output ready_sd
    );
  

    wire rst = BTNC;
    wire spiClk;
    wire spiMiso;
    wire spiMosi;
    wire spiCS;

    // Clock the SD card at 25 MHz.
    wire clk_100mhz = CLK100MHZ;
    wire clk_50mhz;
    wire clk_25mhz;
    clock_divider clk_div1(clk_100mhz, clk_50mhz);
    clock_divider clk_div2(clk_50mhz, clk_25mhz);

    

    // MicroSD SPI/SD Mode/Nexys 4
    // 1: Unused / DAT2 / SD_DAT[2]
    // 2: CS / DAT3 / SD_DAT[3]
    // 3: MOSI / CMD / SD_CMD
    // 4: VDD / VDD / ~SD_RESET
    // 5: SCLK / SCLK / SD_SCK
    // 6: GND / GND / - 
    // 7: MISO / DAT0 / SD_DAT[0]
    // 8: UNUSED / DAT1 / SD_DAT[1]
    assign SD_DAT[2] = 1;
    assign SD_DAT[3] = spiCS;
    assign SD_CMD = spiMosi;
    assign SD_RESET = 0;
    assign SD_SCK = spiClk;
    assign spiMiso = SD_DAT[0];
    assign SD_DAT[1] = 1;
    
    reg rd = 0;
    wire ready;
    reg [7:0] din = 0;  
    wire ready_for_next_byte;
    reg [31:0] adr; 
    reg wr_enable = 0;
    wire [7:0] dout;
    reg [31:0] bytes = 0;
    reg [1:0] bytes_read = 0;
    wire byte_available;
 
    
    wire [4:0] state;
    
    parameter S_INIT = 0;
    parameter S_START = 1;
    parameter S_WRITE = 2;
    parameter S_READ = 3;
    parameter S_START_READ = 4;
    parameter S_WAIT = 5;

    reg [2:0] test_state = S_INIT; 
    assign LED = {state, ready, test_state, bytes[15:9]};
    
    sd_controller sdcont(
        .cs(spiCS), 
        .mosi(spiMosi), 
        .miso(spiMiso),
        .sclk(spiClk),
        .rd(rd), 
        .wr_enable(wr_enable), 
        .reset(rst),
        .din(din), 
        .dout(dout), 
        .byte_available(byte_available),
        .ready(ready), 
        .address(adr), 
        .ready_for_next_byte(ready_for_next_byte), 
        .clk(clk_25mhz), 
        .status(state));
    


    reg next_byte;
    reg read_bytes_ready;//����4�ֽ�
    reg write_bytes_next;//��Ҫ��һ��4�ֽ�
    wire [31:0]write_bytes;//����ͽ�����?4�ֽ�
    reg [1:0]byte_cnt;

    reg [4:0]sector_cnt;//16��
    reg [4:0]sector_cnt_rd_sd;//16��

//-------------------------------------------------------------------
    reg [31:0]addr_sdmem;
    reg we;
    reg we_first;
    reg sd_write_nxt_first;


    reg only_one;
    reg flag_rd_adr_ready;
    reg flag_srd_adr_ready;
    reg flag_wr_adr_ready;

    always @(posedge clk_100mhz or posedge rst) 
    begin
        if (rst) 
        begin
            we <= 0;
            we_first <= 1;
        end
        else if (read_bytes_ready && we_first) 
        begin
            we <= 1;
            we_first <= 0;
        end
        else if (read_bytes_ready == 0)
        begin
            we_first <= 1;
            we <= 0;
        end
        else 
            we <= 0;
    end

    always @(posedge clk_100mhz or posedge rst) 
    begin
        if (rst) 
            addr_sdmem <= 4;
        else if (rd && sector_cnt_rd_sd == 0) //sdȡ��������mem
            addr_sdmem <= 0 - 4;
        else if (wr_enable && sector_cnt == 0) 
            addr_sdmem <= 32'd18192;
        else if (write_bytes_next && sd_write_nxt_first) 
            addr_sdmem <= addr_sdmem + 4;
        else if (read_bytes_ready && we_first) 
            addr_sdmem <= addr_sdmem + 4;
       
        else if (test_state == S_WAIT)
            addr_sdmem <= adr_sdmem;
    end


    always @(posedge clk_100mhz or posedge rst) 
    begin
        if (rst) 
            sd_write_nxt_first <= 1;            
        else if (write_bytes_next && sd_write_nxt_first)
            sd_write_nxt_first <= 0;
        else if (write_bytes_next == 0) 
            sd_write_nxt_first <= 1;
    end
   

    wire seg7_cs = (test_state == S_INIT||test_state == S_READ)?1:0;
    wire [31:0]seg_data = (test_state == S_INIT)?write_bytes:bytes;

   
wire [31:0]addr_sdmem_in;
assign addr_sdmem_in = (test_state == S_WAIT)?adr_sdmem:addr_sdmem;
assign data_out = write_bytes;
assign ready_sd = (test_state == S_WAIT)?1:0;

    /*���ݴ洢��*/
    dist_sdmem_ip SDMEM (
      .a(addr_sdmem_in[12:2]),      // input wire [10 : 0] a
      .d(bytes),      // input wire [31 : 0] d
      .clk(clk_100mhz),  // input wire clk
      .we(we),    // input wire we
      .spo(write_bytes)  // output wire [31 : 0] spo
    );
//---------------------------------------------------------------







    always @(posedge clk_25mhz or posedge rst) 
    begin
        if(rst) 
        begin
            bytes <= 32'h12_34_56_78;
            bytes_read <= 0;
            din <= 0;
           wr_enable <= 0;
            rd <= 0;
            next_byte <= 0;
            write_bytes_next <= 0;
            byte_cnt <=0;
            test_state <= S_INIT; 
            only_one <= 1;
            read_bytes_ready <= 0;          
            sector_cnt <= 0;
            // adr = 32'h00_01_FA_00; //02_00�ǵڶ�������
            adr = 32'h00_00_00_00; //02_00�ǵڶ�������
            flag_wr_adr_ready <= 0;
            flag_srd_adr_ready <= 0;
            sector_cnt_rd_sd <= 0;
            flag_rd_adr_ready <= 0;
            
        end
        else 
        begin
            case (test_state)
                S_INIT: 
                begin
                    adr <= 32'h00_00_47_10;//18192d
                    if(ready && init_sd ) 
                    begin
                        test_state <= S_START_READ;
                        rd <= 1;
                        only_one <= 0;

                    end
                end
                S_START_READ: 
                begin
                    if(ready == 0) 
                        test_state <= S_READ;
                end

                S_READ: 
                begin
                    if(ready) 
                    begin                    
                       
                        if (sector_cnt_rd_sd == 15) 
                        begin
                            test_state <= S_WAIT;
                            sector_cnt_rd_sd <= 0;
                        end
                        else 
                        begin
                            if (flag_srd_adr_ready == 0) 
                            begin
                                adr <= adr + 32'h00_00_02_00;
                                flag_srd_adr_ready <= 1;
                            end
                            begin
                                rd <= 1;
                                test_state <= S_START_READ;
                                sector_cnt_rd_sd <= sector_cnt_rd_sd + 1;
                                flag_srd_adr_ready <= 0;
                            end

                        end

                    end
                    if(byte_available) 
                    begin
                        rd <= 0;
                        if(bytes_read == 0) 
                        begin
                            bytes_read <= 1;
                            bytes[31:24] <= dout;
                        end
                        else if(bytes_read == 1) 
                        begin
                            bytes_read <= 2;
                            bytes[23:16] <= dout;                  
                        end
                        else if(bytes_read == 2)
                        begin
                            bytes_read <= 3;
                            bytes[15:8] <= dout;
                        end
                        else if(bytes_read == 3) 
                        begin
                            bytes_read <= 4;
                            bytes[7:0] <= dout;
                            read_bytes_ready <= 1; //����4�ֽڣ���ddr�����źţ���֮�ɶ�
                        end
                        else 
                            read_bytes_ready <= 0;
                    end
                    else 
                        read_bytes_ready <= 0;
                end

                S_WAIT:
                    test_state <= S_WAIT;
            endcase
        end
    end
endmodule
//DONE