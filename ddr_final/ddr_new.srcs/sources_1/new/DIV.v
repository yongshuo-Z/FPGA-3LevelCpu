`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/5/21 10:19:01
// Design Name: 
// Module Name: DIV
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



module DIV( 
    input signed [31:0]dividend,//������ 
    input signed [31:0]divisor,//���� 
    input start,//������������  
    input clock, 
    input reset, 
    output [31:0]q,//�� 
    output reg [31:0]r,//����     
    output reg busy,//������æ��־λ 
    output reg over
);
reg[5:0]count; 
reg signed [31:0] q_reg; 
reg signed [31:0] r_reg; 
reg signed [31:0] b_reg; 
reg sign_r; 

wire [32:0] sub_add = sign_r?({r_reg,q[31]} + {1'b0,b_reg}):({r_reg,q[31]} - {1'b0,b_reg});//�ӡ������� 

// assign q = q_reg;    
// wire signed[31:0] tq=(dividend[31]^divisor[31])?(-q_reg):q_reg;
assign q = q_reg;     
always @ (negedge clock or posedge reset)
begin 
    if (reset)
        begin//���� 
            count <=0; 
            busy <= 0; 
            over<=0;
        end
    else
        begin
        if (busy) 
                begin
                    if(count<=31)
                        begin 
                            r_reg <= sub_add[31:0];//�������� 
                            sign_r <= sub_add[32];//���Ϊ�����´���� 
                            q_reg <= {q_reg[30:0],~sub_add[32]};//����
                            count <= count +1;//��������һ 
                        end
                    else
                        begin
                            if(dividend[31]^divisor[31])
                                q_reg<=-q_reg;
                            if(!dividend[31])
                                r<=sign_r? r_reg + b_reg : r_reg;
                            else
                                r<=-(sign_r? r_reg + b_reg : r_reg);
                            busy <= 0;
                            over <= 1;
                        end
                end 
            else if (start) 
                begin//��ʼ�������㣬��ʼ�� 
                    r_reg <= 0; 
                    sign_r <= 0; 
                    count <= 0; 
                    busy <= 1; 
                    if(dividend<0)
                        q_reg <= -dividend;
                    else
                        q_reg <= dividend;
                    if(divisor<0)
                        b_reg <= -divisor; 
                    else
                        b_reg <= divisor; 
                end 
            
            else
            over<=0;
        end 
end 
endmodule

