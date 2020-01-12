module static_cpu(
input clk,
input rst,
input [31:0]instruction,//ָ��
input [31:0]rdata,//���ڴ��ж�ȡ��������
output reg[31:0]PC,//ָ���λ��
output [31:0]addr,//���ڴ���е�λ��
output reg[31:0]wdata,//�����ڴ������
output IM_R,//
output DM_CS,//�ڴ�Ƭѡ��Ч
output DM_R,//�ڴ��
output DM_W,//�ڴ�д
output intr,
output inta,


output reg stuck_imem,
input ready_imem
);


reg [31:0]reg_instr;


//�жϴ��� �Ȳ�Ҫ�� �ȵ�Ҫ54���°��ʱ���ٴ���
assign IM_R = 1'b1;
assign intr=1'b1;
assign inta=1'b1;


always @(posedge clk or posedge rst) 
begin
  if (rst) 
    stuck_imem <= 1; 
  else if (ready_imem) 
    stuck_imem <= 0;
end



//----------------------------------------control �ź�------------------------------------------------------------------------
//��Ӧcontrolģ��
wire [3:0]_aluc;//alu�����ź�

wire beq;
wire bne;
wire a_alu;//a_alu��������Դѡ��  sll|srl|sra?0:1;
wire b_alu;//b_alu��������Դѡ��  ori|addi|addiu|andi|xori|slti|sltiu|lui?0:1; //1-rf_rd2  0-s_z_extend
wire [2:0]wd_regfl;//�Ĵ���д������Դ

wire id_DM_R;//�ڴ���ź�
wire id_DM_cs = id_DM_W | id_DM_R;//�ڴ�ѡ���ź�
wire write_rf;//�Ĵ�����д�ź�
wire id_DM_W;//�ڴ�д�ź�

wire ext_sign;//������չ�źţ���ID�׶�ֱ��ʹ�ã�����󴫵�

wire [1:0]wa_regfl;//�Ĵ���д���ݵ�ַѡ��
wire jp_26;
wire jr;
//cp0
wire mfc0;

wire mult;
wire teq;
wire syscall;
wire multu;
wire sign_lblh;
wire [1:0]WMemMode;
wire [4:0]cause;

wire div;
wire mtc0;

wire BREAK;
wire eret;
wire mthi;
wire divu;
wire [1:0]RMemMode;

//ex �� id ��ͻ, mem �� id ��ͻ, wb �� id ��ͻ
wire ex_cflct_in, mem_cflct_in, wb_cflct_in, data_cflct;

wire [31:0]id_rf_rdata1, id_rf_rdata2; //��regfile�ж�ȡ����
//rf_rdata1, rf_rdata2 //��������ˮ�Ĵ�������
wire mtlo;
wire jarl;



wire bgez;
wire clz;





reg DM_W_wb;

//----------------------------------------control �ź�------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------------


//----------------------------����Ŀ����źţ�������ȥ�޸�controlģ�飬���������ط����в��䣩---------------------------------------------------------

wire mfhi = (reg_instr[31:26] == 6'b000000) & (reg_instr[5:0] == 6'b010000);
wire mflo = (reg_instr[31:26] == 6'b000000) & (reg_instr[5:0] == 6'b010010);


//-------------------------------------------------------------------------------------------------------------------------------------------------



//-----------------------------------------------��ˮ�Ĵ���-------------------------------------------------------------------
reg [3:0]_aluc_ex;

//��ˮ�Ĵ���

reg ex_sign_lblh, mem_sign_lblh;
reg [31:0]mem_alu_r;
reg [31:0]ex_alu_a, ex_alu_b;

//�ڴ��ȡ
reg ex_DM_R, DM_R_mem;//�ڴ����Ч
reg ex_DM_W, mem_DM_W;//�ڴ�д��Ч
reg [31:0]ex_addr, mem_addr; //���ڴ�ȡ���ݵĵ�ַ
wire [31:0]id_addr;

reg ex_clz;
reg [2:0]ex_fegfl_wd, mem_wd_regfl;

reg [31:0] mem_mul_z;
reg [31:0] mem_clz_rlt;

reg write_rf_ex, write_rf_mem, write_rf_wb;
reg [4:0]wa_regflddr_ex, wa_regflddr_mem, wa_regflddr_wb;



reg [31:0]pc_id, pc_ex, pc_mem, pc_wb;

//��54��ʱ�����޸�
reg [31:0]hi_wdata_ex, hi_wdata_mem, hi_wdata_wb;//hi�Ĵ���д��
reg [31:0]lo_wdata_ex, lo_wdata_mem, lo_wdata_wb;//lo�Ĵ���д��
reg [31:0]ex_HI, HI_mem,wb_HI;
reg [31:0]ex_LO,mem_LO,wb_LO;

reg [31:0]ex_rf_rdata2, mem_rf_rdata2;
reg [31:0]ex_rf_rdata1, rf_rdata1_mem;


reg [1:0]ex_WMemMode, WMemMode_mem;
reg [1:0]RMemMode_ex, RMemModemem_;


reg ex_multu, mem_multu;
reg ex_mult, mult_mem;
wire [31:0]rf_rdata2;
wire [4:0]rf_raddr1;
wire [4:0]rf_raddr2;
reg [31:0]wd_regflata;
reg ex_div, ex_divu;

reg [31:0]ex_rdata_cp0, mem_rdata_cp0;

// reg [31:0]clz_result_ex;


//------------------------------------------------��ˮ�Ĵ���------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------


//alu
wire [31:0]a_alus;//a_alu����������
wire [31:0]b_alus;//b_alu����������
wire [31:0]r_alu;//���alu_r
wire zero;//alu ���־


//regfile
wire [4:0]_rs;
wire [4:0]_rt;
wire [4:0]_rd;
wire [4:0]wa_regflddr;
wire [31:0]rf_rdata1;




wire [31:0]EXTS16={{16{instr_low16[15]}},instr_low16};
wire [15:0]instr_low16=reg_instr[15:0];
wire [31:0]EXTZ16={16'b0,instr_low16};
wire [31:0]EXTZ5={27'b0,reg_instr[10:6]};



wire [31:0]clz_result;
wire [31:0]q_div;
wire [31:0]r_div;

wire [31:0]exc_addr;
wire exception=BREAK|syscall|(teq&(rf_rdata1 == rf_rdata2));
wire [31:0]status;
wire [31:0]q_divu;

wire [31:0]rdata_cp0;

wire [31:0]r_divu;

//sb,sh
wire [1:0]sb_r=mem_addr[1:0];//�ж�0 1 2 3
wire sh_r=mem_addr[1];//�ж� 0 1

//
wire [1:0]lb_r=mem_addr[1:0];
wire lh_r=mem_addr[1];


wire [31:0]MemDataS16 = lh_r?{{16{rdata[31]}}, rdata[31:16]}:{{16{rdata[15]}}, rdata[15:0]};
wire [31:0]MemDataS8 = lb_r[1]?(lb_r[0]?{{24{rdata[31]}}, rdata[31:24]}:{{24{rdata[23]}}, rdata[23:16]}):(lb_r[0]?{{24{rdata[15]}}, rdata[15:8]}:{{24{rdata[7]}}, rdata[7:0]});

wire [31:0]MemDataZ16 = lh_r?{16'd0, rdata[31:16]}:{16'd0, rdata[15:0]};
wire [31:0]MemDataZ8 = lb_r[1]?(lb_r[0]?{24'd0, rdata[31:24]}:{24'd0, rdata[23:16]}):(lb_r[0]?{24'd0, rdata[15:8]}:{24'd0, rdata[7:0]});







wire jump_16=(beq & (rf_rdata1 == rf_rdata2))|(bne&((rf_rdata1 != rf_rdata2)))|(bgez&(~rf_rdata1[31]));



wire [25:0]instr_index=reg_instr[25:0];
wire [5:0]instr_op=reg_instr[31:26];





wire busy_div;
wire busy_divu;
wire [63:0]multu_z=multu_a*multu_b;
wire signed [31:0]mul_a=ex_rf_rdata1;
wire signed [31:0]mul_b=ex_rf_rdata2;
wire signed [31:0]mul_z = mul_a*mul_b;
reg [31:0]HI;
reg [31:0]LO;
// wire signed [63:0]mult_z = mul_a*mul_b;




// reg start_div;
// reg start_divu;


wire start_divu;
wire over_div;
wire over_divu;
wire [31:0]multu_a=ex_rf_rdata1;
wire [31:0]multu_b=ex_rf_rdata2;
wire signed [63:0]mult_z;
wire start_div;

// wire busy=busy_div|busy_divu|(ex_div&(~over_div))|(ex_divu&(~over_divu));
wire busy=busy_div|busy_divu;
assign start_div = (ex_div&(~busy_div)&(~over_div))?1:0;
assign start_divu = (ex_divu&(~busy_divu)&(~over_divu))?1:0;






//LO ע�⣺�������޸ġ�
always @(posedge clk or posedge rst) begin
  if(rst)begin
    LO<=32'h00000000;
  end
  else begin
    if (mtlo)
      LO<=rf_rdata1;
    else if (over_divu)
      LO<=q_divu;
    else if (ex_mult) 
      LO<=mult_z[31:0];
    else if (over_div)
      LO<=q_div;
    else if (ex_multu) 
      LO<=multu_z[31:0];   
    else 
      LO<=LO;
  end
end


assign _rs=reg_instr[25:21];
assign _rt=reg_instr[20:16];
assign _rd=reg_instr[15:11];
//ѡ��Ĵ��� ��д��ַ
assign rf_raddr1 = _rs;
assign rf_raddr2 = _rt;
// assign wa_regflddr = jal?5'd31:(wa_regfl?_rd:_rt);//54��������Ҫ��wa_regfl�޸ĳ���λ--�Ż�
// assign wa_regflddr = wa_regfl[1]?(wa_regfl[0]?5'd31:mfc0...):(wa_regfl[0]?_rd:_rt);
assign wa_regflddr = wa_regfl[1]?(wa_regfl[0]?5'd31:_rt):(wa_regfl[0]?_rd:_rt);

assign id_addr = rf_rdata1 + (ext_sign ? EXTS16:EXTZ16);//��Ҫ��������ź�**** lw sw************************************

wire [31:0]Wdata_sh= sh_r?{mem_rf_rdata2[15:0],rdata[15:0]}:{rdata[31:16],mem_rf_rdata2[15:0]};
reg [31:0]Wdata_sb;

//HI ע�⣺�������޸ġ�
always @(posedge clk or posedge rst) 
begin
  if(rst)
    HI<=32'h00000000;
  else begin
    if (mthi)
      HI<=rf_rdata1;
    else if (ex_mult) 
      HI<=mult_z[63:32];   
    else if (over_div)
      HI<=r_div;
    else if (over_divu)
      HI<=r_divu;
    else if (ex_multu) 
      HI<=multu_z[63:32];
    
   
    else 
      HI<=HI;
  end
end






always @(posedge clk or posedge rst) 
begin
    if (rst)
        wd_regflata <= 0;
    else 
    begin
        case(mem_wd_regfl) 
        3'b111:wd_regflata <=mem_mul_z;
         3'b100:wd_regflata <=mem_LO;

        3'b010:wd_regflata <=mem_rdata_cp0;

        // 3'b011:wd_regflata <=pc_mem + 4;//��ˮ��Ҫ��Ϊ+8   +4����ת֮ǰ�ͱ�ִ��
      3'b011:wd_regflata <=pc_mem + 8;
        3'b110:wd_regflata <=mem_clz_rlt;
        3'b000:
          case(RMemModemem_)
            2'b11:wd_regflata <=rdata;
            2'b10:wd_regflata <=rdata;
            2'b01:wd_regflata <=mem_sign_lblh?MemDataS16:MemDataZ16;
            2'b00:wd_regflata <=mem_sign_lblh?MemDataS8:MemDataZ8;
            default:wd_regflata <=rdata;
        3'b101:wd_regflata <=HI_mem;
       

        

          endcase
        3'b001:wd_regflata <=mem_alu_r;
        default:
        wd_regflata <=mem_alu_r;
      endcase   
    end
  
end


always @(*) 
begin
  case(sb_r)
  2'b11:Wdata_sb={mem_rf_rdata2[7:0],rdata[23:0]};
  2'b10:Wdata_sb={rdata[31:24],mem_rf_rdata2[7:0],rdata[15:0]};
  2'b01:Wdata_sb={rdata[31:16],mem_rf_rdata2[7:0],rdata[7:0]};
  2'b00:Wdata_sb={rdata[31:8],mem_rf_rdata2[7:0]};
  default:Wdata_sb={rdata[31:8],mem_rf_rdata2[7:0]};
  endcase
end


assign a_alu = a_alu?rf_rdata1:EXTZ5;
assign b_alu = b_alu?rf_rdata2:(ext_sign ? EXTS16:EXTZ16);


always @(*) 
begin
  case(WMemMode_mem)
    2'b11:wdata=mem_rf_rdata2;
    2'b10:wdata=mem_rf_rdata2;
    2'b01:wdata=Wdata_sh;
    2'b00:wdata=Wdata_sb;
    default:wdata=mem_rf_rdata2;

  endcase
end

//-----------------------------------------IF--------------------------------------------------

wire [31:0]NPC=PC+32'd4;
//wire [31:0]IPC=PC-32'h00400000;//����ṹ��ָ��ӳ��



always @(posedge clk or posedge rst) 
begin
    if (rst) 
        reg_instr <= 32'b0;
    else if (data_cflct | busy) 
    begin //���ݳ�ͻ ���� ����æ�ź�  ���µ� ��ͣ��ˮ
        reg_instr <= reg_instr;
    end
    else 
        reg_instr <= instruction;
end



//-----------------------------------------ID--------------------------------------------------

CONTROL inst_ctrl(.instruction(reg_instr),._aluc(_aluc),.write_rf(write_rf),.DM_W(id_DM_W),.DM_R(id_DM_R),
    .ext_sign(ext_sign),.a_alu(a_alu),.b_alu(b_alu),.wd_regfl(wd_regfl),
    .wa_regfl(wa_regfl),.jp_26(jp_26),.beq(beq),.bne(bne),.jr(jr), .mfc0(mfc0), .mtc0(mtc0),
    .BREAK(BREAK), .eret(eret), .syscall(syscall), .teq(teq), .cause(cause), .mthi(mthi),
    .mtlo(mtlo),.jarl(jarl),.RMemMode(RMemMode),.sign_lblh(sign_lblh),.WMemMode(WMemMode),
    .bgez(bgez),.clz(clz),.multu(multu),.mult(mult),.div(div),.divu(divu));



//PC
always @(posedge clk or posedge rst) 
begin
  if (rst) 
    PC<=32'h00400000; 
  else if (stuck_imem)
    PC<=32'h00400000;
   else if (jr|jarl)
    PC<=rf_rdata1;
  else if (data_cflct)
    PC <= PC;
  else if (busy) 
    PC<=PC;
  
  else if (exception| eret)   
    PC<=exc_addr;
    else if (jump_16) 
    PC <= PC+{{14{instr_low16[15]}},instr_low16,2'b00}; 
  else if (jp_26)
    PC<={PC[31:28],instr_index,{2'b00}};
  
  else  
    PC<=NPC;
 
end







always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        pc_id <= 0;
    end
    else if (data_cflct | busy) 
    begin //��ͣ��ˮ
        pc_id <= pc_id;
    end
    else 
    begin
        pc_id <= PC;
    end
end

// id �� wb ��ͻ д�ؼĴ�����addr ��id�׶ε� _rs �� _rt
assign wb_cflct_in = (wa_regflddr_wb != 0) & (&write_rf_wb & (wa_regflddr_wb == _rs || wa_regflddr_wb == _rt));



assign data_cflct = ex_cflct_in | mem_cflct_in | wb_cflct_in;

assign ex_cflct_in =  ((wa_regflddr_ex != 0) & (write_rf_ex & (wa_regflddr_ex == _rs || wa_regflddr_ex == _rt)))
                       ||((mfhi | mflo) & (over_divu | over_div | ex_multu | ex_mult));
                       //hi lo ��ȡ�����ݳ�ͻ


// id �� mem ��ͻ д�ؼĴ�����addrΪ _rs �� _rt, ����  ���ڴ�д�Ĵ��� ��ַ��ͻ
assign mem_cflct_in = (wa_regflddr_mem != 0) & (&write_rf_mem & (wa_regflddr_mem == _rs || wa_regflddr_mem == _rt));


//---------------------------------------------���ݳ�ͻ���-----------------------------------------------------------------------------
//---------------------------------------------���ݳ�ͻ���-----------------------------------------------------------------------------
//---------------------------------------------���ݳ�ͻ���-----------------------------------------------------------------------------




//-----------------------------------------EX--------------------------------------------------





//alu������
alu cal(.a(ex_alu_a),.b(ex_alu_b),._aluc(_aluc_ex), .r(r_alu),.zero(zero),.carry(),.negative(),.overflow());







//��ex�׶μ���
CLZ inst_clz(.in(ex_rf_rdata1),.out(clz_result));



assign addr = mem_addr;

always @(posedge clk or posedge rst) 
begin
    if (rst | busy) 
    begin//����æ�źţ���mem�����п����źŶ���Ч
        write_rf_mem <= 0;
        pc_mem <= 0;
        hi_wdata_mem <= 0;
        lo_wdata_mem <= 0;
        DM_R_mem <= 0;
        mem_DM_W <= 0;
        mem_wd_regfl <= 0;
        mem_mul_z <= 0;
        mem_sign_lblh <= 0;
        mem_alu_r <= 0;
        RMemModemem_ <= 0;
        WMemMode_mem <= 0;
        mem_addr <= 0;
        mem_clz_rlt <= 0;
       mem_LO <= 0;
        HI_mem <= 0;
        mem_rf_rdata2 <= 0;
        mem_multu <= 0;
        mult_mem <= 0;
        mem_rdata_cp0 <= 0;
    end
    else  
    begin
        write_rf_mem <= write_rf_ex;
        pc_mem <= pc_ex;
        hi_wdata_mem <= hi_wdata_ex;
        lo_wdata_mem <= lo_wdata_ex;
        DM_R_mem <= ex_DM_R;
        mem_DM_W <= ex_DM_W;
        mem_wd_regfl <= ex_fegfl_wd;
        mem_mul_z <= mul_z;
        mem_sign_lblh <= ex_sign_lblh;
        mem_alu_r <= r_alu;
        RMemModemem_ <= RMemMode_ex;
        WMemMode_mem <= ex_WMemMode;
        wa_regflddr_mem <= wa_regflddr_ex;
        mem_addr <= ex_addr;
        mem_clz_rlt <= clz_result;
       mem_LO <=ex_LO;
        HI_mem <=ex_HI;
        mem_rf_rdata2 <= ex_rf_rdata2;
        mem_multu <= ex_multu;
        mult_mem <= ex_mult;
        mem_rdata_cp0 <= ex_rdata_cp0;
    end
end

always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        write_rf_wb <=0;
        pc_wb <= 0;
        hi_wdata_wb <= 0;
        lo_wdata_wb <= 0;
       wb_HI <= 0;
       wb_LO <= 0;
        DM_W_wb <= 0;
    end
    else 
    begin
        write_rf_wb <= write_rf_mem;
        wa_regflddr_wb <= wa_regflddr_mem;
        pc_wb <= pc_mem;
        hi_wdata_wb <= hi_wdata_mem;
        lo_wdata_wb <= lo_wdata_mem;
       wb_HI <= HI_mem;
       wb_LO <=mem_LO;
        DM_W_wb <= mem_DM_W;
    end
end

always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        ex_DM_W <= 0;
        ex_DM_R <= 0;
        hi_wdata_ex <= 0;
        lo_wdata_ex <= 0;

        ex_addr <= 0;
        ex_fegfl_wd <= 0;

        ex_clz <= 0;
        write_rf_ex <= 0;
        pc_ex <= 0;
        ex_div <= 0;
        ex_divu <= 0;
        ex_rdata_cp0 <= 0;
        
        ex_rf_rdata2 <= 0;
        ex_multu <= 0;
        ex_mult <= 0;

       
    end
    else if (data_cflct) 
    begin
        write_rf_ex <= 0;
        ex_multu <= 0;
        ex_mult <= 0;
        ex_DM_W <= 0;
        ex_DM_R <= 0;
        ex_clz <= 0;

        
    end
    else if(busy) 
    begin
        pc_ex <=pc_ex;
    end
    else 
    begin
        _aluc_ex <= _aluc;
        ex_alu_a <= a_alu;
        
        // hi_wdata_ex <= hi_wdata_id;
        // lo_wdata_ex <= lo_wdata_id;

        ex_addr <= id_addr;
        RMemMode_ex <= RMemMode;
        ex_WMemMode <= WMemMode;
         ex_DM_W <= id_DM_W;
        ex_DM_R <= id_DM_R;
      

        ex_div <= div;
        ex_divu <= divu;

        ex_rdata_cp0 <= rdata_cp0;
        ex_sign_lblh <= sign_lblh;
        ex_clz <= clz;

        ex_rf_rdata2 <= rf_rdata2;
        ex_rf_rdata1 <= rf_rdata1;

        ex_multu <= multu;
        ex_mult <=  mult;
      

        wa_regflddr_ex <= wa_regflddr;
        write_rf_ex <= write_rf;// д�Ĵ�����ַ �� д�Ĵ����ź� ����������׶�ȷ����

        pc_ex <= pc_id;
        ex_fegfl_wd <= wd_regfl;
       ex_HI <= HI;
       ex_LO <= LO;
       ex_alu_b <= b_alu;
       
    end
end


//����׶�ִ��
CP0 inst_cp0(.clk(clk), .rst(rst), .mfc0(mfc0), .mtc0(mtc0), .pc(pc_id), 
.Rd(_rd),        //����  [2:0]  sel 
.wdata(rf_rdata2),    // rt�ж�ȡ����  rf_raddr2 = _rt;
.exception(exception), 
.eret(eret),
.cause(cause), 
.intr(), 
.rdata(rdata_cp0),      // Data from CP0 register for GP register 
.status(status), 
.timer_int(), 
.exc_addr(exc_addr)    // Address for PC at the beginning of an exception 
); 


Regfiles regfiles(.clk(clk),.rst(rst),.wena(write_rf_wb),.raddr1(rf_raddr1),.raddr2(rf_raddr2),
    .waddr(wa_regflddr_wb),.wdata(wd_regflata),.rdata1(rf_rdata1),.rdata2(rf_rdata2));

DIV inst_div(.dividend(ex_rf_rdata1),.divisor(ex_rf_rdata2),.start(start_div),.clock(clk),.reset(rst),.q(q_div),.r(r_div),.busy(busy_div),.over(over_div));
DIVU inst_divu(.dividend(ex_rf_rdata1),.divisor(ex_rf_rdata2),.start(start_divu),.clock(clk),.reset(rst),.q(q_divu),.r(r_divu),.busy(busy_divu),.over(over_divu));

assign DM_CS = mem_DM_W | DM_R_mem;
assign DM_R = DM_R_mem;
assign DM_W = mem_DM_W;




//-----------------------------------------WB--------------------------------------------------






endmodule



