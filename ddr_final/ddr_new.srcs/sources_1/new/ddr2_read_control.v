//-----------------------------------------------------------------------------------------------------------------
//ddr2_read_control------------------------------------------------------------------------------------------------
module ddr2_read_control(
    input clk_in,
    input _rst,
    input ena,

    input [26:0]addr_read,


    //mig
    input [127:0] app_rd_data,
    input app_rdy,
    input app_rd_data_end,
    input app_rd_data_valid,
    output reg app_en,
    output reg [2:0] app_cmd,
    output reg [26:0] app_addr
   
    );

   

    //��ȡFSM
    reg [4:0] c_state;
    
    localparam S_IDLE = 5'b0_0001;
    localparam S_READ = 5'b0_0010;

    always @(posedge clk_in)
    begin
        if(_rst) 
        begin
            app_en <= 0;
            app_addr<=0;
            c_state <= S_IDLE;
        end
        else if(ena) 
        begin
            case(c_state)
            S_IDLE:
            begin
                app_en <= 1;
                app_cmd <= 3'b001;
                c_state <= S_READ;
                app_addr<=addr_read;
               
            end
            S_READ:
            begin
                if(app_rdy) 
                begin
                    app_en <= 1'b0;
                    app_addr<=addr_read;
                    c_state <= S_IDLE;
                end
            end
            default:
                c_state <= S_IDLE;
            endcase
        end 
        else 
        begin
            c_state <= S_IDLE;
            app_en <= 1'b0;           
        end 
    end

endmodule

//-----------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------
