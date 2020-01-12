
//-----------------------------------------------------------------------------------------------------------------
//ddr2_write_control-----------------------------------------------------------------------------------------------
module ddr2_write_control(
   clk_in,
   _rst,
   I_ADDR,
   I_DATA,
   I_STB,
    O_ACK,
    en_read,
//mig
    app_en,
    app_wdf_wren,
    app_wdf_end,
    app_cmd,
    app_addr,
    app_wdf_data,
    app_rdy,
    app_wdf_rdy
    );

    parameter DQ_WIDTH          = 16;
    parameter ECC_TEST          = "OFF";
    parameter ADDR_WIDTH        = 27;
    parameter nCK_PER_CLK       = 4;

    localparam DATA_WIDTH       = 16;
    localparam PAYLOAD_WIDTH    = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;
    localparam APP_DATA_WIDTH   = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;  //ͻ������Ϊ8
    localparam APP_MASK_WIDTH   = APP_DATA_WIDTH / 8;

    input clk_in;
    input _rst;  
    input I_STB;    //ѡͨ�ź�
    output reg O_ACK;   
    output reg en_read;
    input [26:0] I_ADDR;    //��ȡ��ַ��ƫ��
    input [127:0] I_DATA;  //��Ҫд�������
   
    
    output reg [ADDR_WIDTH-1:0] app_addr;
    output reg [APP_DATA_WIDTH-1:0] app_wdf_data;
    input app_rdy, app_wdf_rdy;
    output reg app_en, app_wdf_wren, app_wdf_end;
    output reg [2:0] app_cmd;
   

    //����д�����ݵ��ź�ֵ
    //----------FSM--------
    reg [2:0] c_state;

    parameter S_IDLE = 3'b001;
    parameter S_WRITE = 3'b010;

    reg [3:0] write_cnt;


    always @(posedge clk_in)
    begin
        if(_rst) 
        begin
            app_cmd <= 3'b1;
            app_en <= 1'b0;
            app_wdf_data <= 128'h0;
            app_addr <= 27'h0;
            app_wdf_end <= 1'b0;
            app_wdf_wren <= 1'b0;
            write_cnt <= 0;
            en_read <= 0;
            O_ACK <= 0;
            c_state <= S_IDLE;
        end
        else if(I_STB) 
        begin
            case(c_state)
                S_IDLE:
                begin
                    if(app_rdy & app_wdf_rdy) 
                    begin
                        app_wdf_data <= I_DATA;
                        app_cmd <= 3'b0;
                        app_en <= 1'b1;
                        app_addr <= I_ADDR;
                        app_wdf_wren <= 1'b1;
                        app_wdf_end <= 1'b1;
                        O_ACK <= 0;  //���Խ�������
                        write_cnt <= write_cnt + 1;
                        c_state <= S_WRITE;
                                         
                    end
                    else 
                        c_state <= S_IDLE; 
                end
                S_WRITE:
                begin
                    O_ACK <= 1;
                    app_wdf_wren <= 1'b0;
                    app_wdf_end <= 0;
                    app_en <= 1'b0;
                    app_cmd <= 3'b1;
                    
                    if(write_cnt == 3)
                    begin
                        en_read <= 1;
                    end
                    c_state <= S_IDLE;
                end
                default:c_state <= S_IDLE;
            endcase
        end
        else 
        begin
            app_wdf_wren <= 0;
            app_wdf_end <= 0;
            O_ACK <= 0;
            app_en <= 0;
           
            c_state <= S_IDLE;
        end
    end


endmodule
//done