`timescale 1ns / 1ps
/* SPI MODE */
module sd_controller(
    output reg cs, // Connect to SD_DAT[3].
    output mosi, // Connect to SD_CMD.
    input miso, // Connect to SD_DAT[0].
    output sclk, // Connect to SD_SCK.
                // For SPI mode, SD_DAT[2] and SD_DAT[1] should be held HIGH. 
                // SD_RESET should be held LOW.

    input rd,   // Read-enable. When [ready] is HIGH, asseting [rd] will 
                // begin a 512-byte READ operation at [address]. 
                // [byte_available] will transition HIGH as a new byte has been
                // read from the SD card. The byte is presented on [dout].
    output reg [7:0] dout, // Data output for READ operation.
    output reg byte_available, // A new byte has been presented on [dout].

    input wr_enable,   // Write-enable. When [ready] is HIGH, asserting [wr_enable] will
                // begin a 512-byte WRITE operation at [address].
                // [ready_for_next_byte] will transition HIGH to request that
                // the next byte to be written should be presentaed on [din].
    input [7:0] din, // Data input for WRITE operation.
    output reg ready_for_next_byte, // A new byte should be presented on [din].

    input reset, // Resets controller on assertion.
    output ready, // HIGH if the SD card is ready for a read or write operation.
    input [31:0] address,   // Memory address for read/write operation. This MUST 
                            // be a multiple of 512 bytes, due to SD sectoring.
    input clk,  // 25 MHz clock.
    output [4:0] status 
);

    parameter RESET = 0;
    parameter INIT = 1;
    parameter CMD0 = 2;
    parameter CMD55 = 3;
    parameter CMD41 = 4;
    parameter POLL_CMD = 5;
    
    parameter IDLE = 6;
    parameter READ_BLK = 7;
    parameter READ_BLK_WAIT = 8;
    parameter READ_BLK_DATA = 9;
    parameter READ_BLK_CRC = 10;
    parameter SEND_CMD = 11;
    parameter RECEIVE_BYTE_WAIT = 12;
    parameter RECEIVE_BYTE = 13;
    parameter WRITE_BLK_CMD = 14;
    parameter WRITE_BLK_INIT = 15;
    parameter WRITE_BLK_DATA = 16;
    parameter WRITE_BLK_BYTE = 17;
    parameter WRITE_BLK_WAIT = 18;
    
    parameter WRITE_DATA_SIZE = 515;
    
    reg [4:0] state = RESET;
    assign status = state;
    reg [4:0] state_rtn;
    reg [7:0] data_recv;
    reg mode_cmd = 1;
    reg sig_sclk = 0;
    reg [55:0] out_cmd;
   
    reg [7:0] sig_data = 8'hFF;
    
    reg [9:0] B_cnt;
    reg [9:0] bit_cnt;
    
    reg [26:0] boot_counter = 27'd100_000_000;

    always @(posedge clk) 
    begin
        if(reset == 1) 
        begin
            state <= RESET;
            sig_sclk <= 0;
            boot_counter <= 27'd100_000_000;
        end
        else 
        begin
            case(state)
                RESET: 
                begin
                    if(boot_counter == 0) 
                    begin
                        sig_sclk <= 0;
                        out_cmd <= {56{1'b1}};
                        B_cnt <= 0;
                        byte_available <= 0;
                        ready_for_next_byte <= 0;
                        mode_cmd <= 1;
                        bit_cnt <= 160;
                        cs <= 1;
                        state <= INIT;
                    end
                    else 
                        boot_counter <= boot_counter - 1;
                end
                INIT: 
                begin
                    if(bit_cnt == 0) 
                    begin
                        cs <= 0;
                        state <= CMD0;
                    end
                    else 
                    begin
                        bit_cnt <= bit_cnt - 1;
                        sig_sclk <= ~sig_sclk;
                    end
                end
                CMD0: 
                begin
                    out_cmd <= 56'hFF_40_00_00_00_00_95;
                    bit_cnt <= 55;
                    state_rtn <= CMD55;
                    state <= SEND_CMD;
                end
                CMD55: 
                begin
                    out_cmd <= 56'hFF_77_00_00_00_00_01;
                    bit_cnt <= 55;
                    state_rtn <= CMD41;
                    state <= SEND_CMD;
                end
                CMD41: 
                begin
                    out_cmd <= 56'hFF_69_00_00_00_00_01;
                    bit_cnt <= 55;
                    state_rtn <= POLL_CMD;
                    state <= SEND_CMD;
                end
                POLL_CMD: 
                begin
                    if(data_recv[0] == 0) 
                        state <= IDLE;
                    else 
                        state <= CMD55;
                end
                IDLE:
                begin
                    if(rd == 1) 
                        state <= READ_BLK;
                    else if(wr_enable == 1) 
                        state <= WRITE_BLK_CMD;
                    else 
                        state <= IDLE;
                end
                READ_BLK: 
                begin
                    out_cmd <= {16'hFF_51, address, 8'hFF};
                    bit_cnt <= 55;
                    state_rtn <= READ_BLK_WAIT;
                    state <= SEND_CMD;
                end
                READ_BLK_WAIT: 
                begin
                    if(sig_sclk == 1 && miso == 0) 
                    begin
                        B_cnt <= 511;
                        bit_cnt <= 7;
                        state_rtn <= READ_BLK_DATA;
                        state <= RECEIVE_BYTE;
                    end
                    sig_sclk <= ~sig_sclk;
                end
                READ_BLK_DATA: 
                begin
                    dout <= data_recv;
                    byte_available <= 1;
                    if (B_cnt == 0) 
                    begin
                        bit_cnt <= 7;
                        state_rtn <= READ_BLK_CRC;
                        state <= RECEIVE_BYTE;
                    end
                    else 
                    begin
                        B_cnt <= B_cnt - 1;
                        state_rtn <= READ_BLK_DATA;
                        bit_cnt <= 7;
                        state <= RECEIVE_BYTE;
                    end
                end
                READ_BLK_CRC: 
                begin
                    bit_cnt <= 7;
                    state_rtn <= IDLE;
                    state <= RECEIVE_BYTE;
                end
                SEND_CMD: 
                begin
                    if (sig_sclk == 1) 
                    begin
                        if (bit_cnt == 0) 
                            state <= RECEIVE_BYTE_WAIT;
                        else 
                        begin
                            bit_cnt <= bit_cnt - 1;
                            out_cmd <= {out_cmd[54:0], 1'b1};
                        end
                    end
                    sig_sclk <= ~sig_sclk;
                end
                RECEIVE_BYTE_WAIT: 
                begin
                    if (sig_sclk == 1) 
                    begin
                        if (miso == 0) 
                        begin
                            data_recv <= 0;
                            bit_cnt <= 6;
                            state <= RECEIVE_BYTE;
                        end
                    end
                    sig_sclk <= ~sig_sclk;
                end
                RECEIVE_BYTE: 
                begin
                    byte_available <= 0;
                    if (sig_sclk == 1) 
                    begin
                        data_recv <= {data_recv[6:0], miso};
                        if (bit_cnt == 0) 
                            state <= state_rtn;
                        else 
                            bit_cnt <= bit_cnt - 1;
                    end
                    sig_sclk <= ~sig_sclk;
                end
                WRITE_BLK_CMD: 
                begin
                    out_cmd <= {16'hFF_58, address, 8'hFF};
                    bit_cnt <= 55;
                    state_rtn <= WRITE_BLK_INIT;
                    state <= SEND_CMD;
                    ready_for_next_byte <= 1;
                end
                WRITE_BLK_INIT: 
                begin
                    mode_cmd <= 0;
                    B_cnt <= WRITE_DATA_SIZE; 
                    state <= WRITE_BLK_DATA;
                    ready_for_next_byte <= 0;
                end
                WRITE_BLK_DATA: 
                begin
                    if (B_cnt == 0) 
                    begin
                        state <= RECEIVE_BYTE_WAIT;
                        state_rtn <= WRITE_BLK_WAIT;
                    end
                    else 
                    begin
                        if ((B_cnt == 2) || (B_cnt == 1)) 
                            sig_data <= 8'hFF;
                        else if (B_cnt == WRITE_DATA_SIZE) 
                            sig_data <= 8'hFE;
                        else 
                        begin
                            sig_data <= din;
                            ready_for_next_byte <= 1;
                        end
                        bit_cnt <= 7;
                        state <= WRITE_BLK_BYTE;
                        B_cnt <= B_cnt - 1;
                    end
                end
                WRITE_BLK_BYTE: 
                begin
                    if (sig_sclk == 1) 
                    begin
                        if (bit_cnt == 0) 
                        begin
                            state <= WRITE_BLK_DATA;
                            ready_for_next_byte <= 0;
                        end
                        else 
                        begin
                            sig_data <= {sig_data[6:0], 1'b1};
                            bit_cnt <= bit_cnt - 1;
                        end;
                    end;
                    sig_sclk <= ~sig_sclk;
                end
                WRITE_BLK_WAIT: 
                begin
                    if (sig_sclk == 1) 
                    begin
                        if (miso == 1) 
                        begin
                            state <= IDLE;
                            mode_cmd <= 1;
                        end
                    end
                    sig_sclk = ~sig_sclk;
                end
            endcase
        end
    end

    assign sclk = sig_sclk;
    assign mosi = mode_cmd ? out_cmd[55] : sig_data[7];
    assign ready = (state == IDLE);
endmodule
//---------------------------------------------------------------------------------------------------------
//done-----------------------------------------------------------------------------------------------------