`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/04/15 11:08:26
// Design Name: 
// Module Name: CONTROL
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


module CONTROL(
    input [31:0]instruction,
    output reg[3:0]_aluc,
    output write_rf,
    output DM_W,
    output DM_R,
    output ext_sign,
    output a_alu,
    output b_alu,
    output reg[2:0]wd_regfl,
    output reg[1:0]wa_regfl,
    output jp_26,
    output beq,
    output bne,
    output jr,
    output mfc0,
    output mtc0,
    output BREAK,
    output eret,
    output syscall,
    output teq,
    output [4:0]cause,
    output mthi,
    output mtlo,
    output jarl,
    output reg[1:0]RMemMode,
    output sign_lblh,
    output reg[1:0]WMemMode,
    output bgez,
    output clz,
    output multu,
    output mult,
    output div,
    output divu
    );
    
    wire [5:0]instr_op=instruction[31:26];
    wire [5:0]instr_func=instruction[5:0];


   
    wire sub=(instr_op==6'b000000) & (instr_func==6'b100010);
   
    wire lw=instr_op==6'b100011;
    wire ori=instr_op==6'b001101;
    wire sll=(instr_op==6'b000000) & (instr_func==6'b000000);
    wire srl=(instr_op==6'b000000) & (instr_func==6'b000010);
    wire sra=(instr_op==6'b000000) & (instr_func==6'b000011);
    wire addu=(instr_op==6'b000000) & (instr_func==6'b100001);
    wire andi=instr_op==6'b001100;
    wire xori=instr_op==6'b001110;

    wire subu=(instr_op==6'b000000) & (instr_func==6'b100011);
     wire AND=(instr_op==6'b000000) & (instr_func==6'b100100);
    wire OR=(instr_op==6'b000000) & (instr_func==6'b100101);
    wire XOR=(instr_op==6'b000000) & (instr_func==6'b100110);
     wire addi=instr_op==6'b001000;
    wire addiu=instr_op==6'b001001;
        wire slti=instr_op==6'b001010;
     wire sw=instr_op==6'b101011;
    wire add=(instr_op==6'b000000) & (instr_func==6'b100000);
    wire sltiu=instr_op==6'b001011;
    wire lui=instr_op==6'b001111;
    wire jal=instr_op==6'b000011;

    wire NOR=(instr_op==6'b000000) & (instr_func==6'b100111);
    wire sltu=(instr_op==6'b000000) & (instr_func==6'b101011);
    wire srlv=(instr_op==6'b000000) & (instr_func==6'b000110);
    wire srav=(instr_op==6'b000000) & (instr_func==6'b000111);
    wire slt=(instr_op==6'b000000) & (instr_func==6'b101010);
    wire sllv=(instr_op==6'b000000) & (instr_func==6'b000100);
    

   
    assign bgez=instr_op==6'b000001;
    assign div=(instr_op==6'b000000) & (instr_func==6'b011010);
    assign divu=(instr_op==6'b000000) & (instr_func==6'b011011);


    assign mthi=(instr_op==6'b000000) & (instr_func==6'b010001);
    assign mtlo=(instr_op==6'b000000) & (instr_func==6'b010011);

    wire mfhi=(instr_op==6'b000000) & (instr_func==6'b010000);
    wire mflo=(instr_op==6'b000000) & (instr_func==6'b010010);

    wire lb=instr_op==6'b100000;
    wire lh=instr_op==6'b100001;
    wire lbu=instr_op==6'b100100;
    wire lhu=instr_op==6'b100101;

    wire sb=instr_op==6'b101000;
    wire sh=instr_op==6'b101001;
    assign jarl=(instr_op==6'b000000) & (instr_func==6'b001001);

    assign clz=(instr_op==6'b011100) & (instr_func==6'b100000);

    wire mul=(instr_op==6'b011100) & (instr_func==6'b000010);
    assign multu=(instr_op==6'b000000) & (instr_func==6'b011001);
    assign mult=(instr_op==6'b000000) & (instr_func==6'b011000);


    

        
    //CP0 -SIGNAL
    assign mfc0=instruction[31:21]==11'b01000000000;
    assign jp_26=(instr_op==6'b000010)||jal;//j  jal
    assign beq =instr_op==6'b000100;
    assign bne =instr_op==6'b000101;
    assign a_alu=sll|srl|sra?0:1;
    assign b_alu=ori|addi|addiu|andi|xori|slti|sltiu|lui?0:1; //1-rf_rd2  0-s_z_extend
    assign mtc0=instruction[31:21]==11'b01000000100;
    assign syscall=(instr_op==6'b000000) & (instr_func==6'b001100);
    assign BREAK=(instr_op==6'b000000) & (instr_func==6'b001101);
    assign cause = syscall?5'b01000:(BREAK?5'b01001:(teq?5'b01101:5'b00000)); 


    assign teq=(instr_op==6'b000000) & (instr_func==6'b110100);
    assign eret=(instr_op==6'b010000) & (instr_func==6'b011000);//ERETNC?????
    

    assign jr=(instr_op==6'b000000) && (instr_func==6'b001000);



    always @(*) begin
        if(sw)
            WMemMode=2'b11;
        else if(sb)
            WMemMode=2'b00;
        else if (sh) 
            WMemMode=2'b01;
        else 
            WMemMode=2'b10;
    end

    // assign RMemMode = lw?2'b11:(lb|lbu?2'b00:(lh|lhu?2'b01:2'b10));
    always @(*) begin
        if(lw)
            RMemMode=2'b11;
        else if(lb|lbu)
            RMemMode=2'b00;
        else if (lh|lhu) 
            RMemMode=2'b01;
        else 
            RMemMode=2'b10;
    end

    // assign WMemMode = sw?2'b11:(sb?2'b00:(sh?2'b01:2'b10));
    

    

   
    
   
    always @(*) begin
        if (mul)
            wd_regfl=3'b111;
        else if(mflo)
            wd_regfl=3'b100;
        else if(mfc0)
            wd_regfl=3'b010;
        else if(jal|jarl)
            wd_regfl=3'b011;
        else if(clz)
            wd_regfl=3'b110;
        else if(mfhi)
            wd_regfl=3'b101;
       
        else if(lw|lb|lh|lbu|lhu)
            wd_regfl=3'b000;
        else 
            wd_regfl=3'b001;
    end

    //????_aluc???
    always @(*) begin
        case(instruction[31:26])
            6'b000000:
                case(instruction[5:0])
                    
                    6'b100111:_aluc=4'b0111;//nor
                    6'b101010:_aluc=4'b1011;//slt
                    6'b101011:_aluc=4'b1010;//sltu


                    6'b000000:_aluc=4'b111x;//sll
                    6'b000100:_aluc=4'b111x;//sllv
                    6'b000110:_aluc=4'b1101;//srlv
                    6'b100100:_aluc=4'b0100;//and
                    6'b100101:_aluc=4'b0101;//or
                    6'b000010:_aluc=4'b1101;//srl
                    6'b000011:_aluc=4'b1100;//sra
                    
                   6'b100000:_aluc=4'b0010;//add
                    6'b100001:_aluc=4'b0000;//addu
                    6'b100010:_aluc=4'b0011;//sub
                    6'b100011:_aluc=4'b0001;//subu
                    6'b100110:_aluc=4'b0110;//xor
                    6'b000111:_aluc=4'b1100;//srav

                    // 6'b110100:_aluc=4'b0011;//teq   //static_pipeline?§Ó????????ú‘
                    default:_aluc=4'b0010;
                endcase
            6'b001000:_aluc=4'b0010;//addi
             6'b001100:_aluc=4'b0100;//andi
             6'b000100:_aluc=4'b0011;//beq
            6'b000101:_aluc=4'b0011;//bne

            6'b001001:_aluc=4'b0000;//addiu
           
            6'b001010:_aluc=4'b1011;//slti
            6'b001011:_aluc=4'b1010;//sltiu
            6'b001101:_aluc=4'b0101;//ori
            6'b001110:_aluc=4'b0110;//xori

            
            6'b001111:_aluc=4'b100x;//lui

            default:_aluc=4'b0010;
        endcase

    end

    assign write_rf = lw|lb|lh|lbu|lhu|addu|subu|sll|ori|add|sub|AND|OR|XOR|NOR|slt|sltu|srl|sra|sllv|srlv|srav|addi|addiu|andi|xori|slti|sltiu|lui|jal|mfc0|mfhi|mflo|jarl|clz|mul?1:0;
    assign DM_W = sw|sb|sh?1:0;
    assign DM_R = lw|lb|lh|lbu|lhu?1:0;
    always @(*) begin
        if(jal)
            wa_regfl=2'b11;
        else if(mfc0)
            wa_regfl=2'b10;
        else if(lw|lb|lh|lbu|lhu|ori|addi|addiu|andi|xori|slti|sltiu|lui)
            wa_regfl=2'b00;
        else 
            wa_regfl=2'b01;
    end

    // assign wa_regfl = jal?(2'b11):(mfc0?2'b10:(lw|lb|lh|lbu|lhu|ori|addi|addiu|andi|xori|slti|sltiu|lui?2'b00:2'b01));



    //0?????  1???????
    assign ext_sign = ori|andi|xori?0:1;
    assign sign_lblh = lb|lh?1:0;





endmodule
