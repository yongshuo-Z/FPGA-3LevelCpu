
module DIVU(
    input [31:0]dividend,         //������
    input [31:0]divisor,          //����
    input start,                  //������������
    input clock,
    input reset,
    output [31:0]q,               //��
    output [31:0]r,               //����    
    output reg busy,                   //������æ��־λ
    output reg over
    );

    reg [4:0]count;
    reg [31:0] q_reg;
    reg [31:0] r_reg;
    reg [31:0] b_reg;
    reg sign_r;
    wire [32:0] sub_add = sign_r?({r_reg,q[31]} + {1'b0,b_reg}):({r_reg,q[31]} - {1'b0,b_reg});    //�ӡ�������
    assign r = sign_r? r_reg + b_reg : r_reg;
    assign q = q_reg; 


    always @(negedge clock or posedge reset) begin
        if (reset) 
        begin
            busy<=0;
            count<=0;
            over<=0;
        end
        else 
        begin
            if (start) begin
                q_reg<=dividend;
                 count<=0;
                busy<=1;
                sign_r<=0;
                b_reg<=divisor;
                r_reg<=32'b0;
               
            end
            else if (busy) 
            begin
                r_reg<=sub_add[31:0];
                 sign_r<=sub_add[32];
                count<=count +5'b1;
                q_reg<={q_reg[30:0],~sub_add[32]};
               
                if(count == 5'd31)
                begin
                    busy<=0;
                    over<=1;
                end
            end
            else 
                 over<=0;
            
        end

    end
endmodule