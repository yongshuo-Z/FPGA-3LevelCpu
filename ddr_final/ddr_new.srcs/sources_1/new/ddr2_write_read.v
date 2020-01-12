`timescale 1ns / 1ps

module ddr2_write_read(
    input clk_in,
    input rst,
    input clk_ref_i,
    output ddr2_ck_p,
    output ddr2_ck_n,
    output ddr2_cke,
    output ddr2_cs_n,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    output [1:0] ddr2_dm,
    output [2:0] ddr2_ba,
    output [12:0] ddr2_addr,
    inout [15:0] ddr2_dq,
    inout [1:0] ddr2_dqs_p,
    inout [1:0] ddr2_dqs_n,
    output [1:0] rdqs_n,
    output ddr2_odt,

    input [31:0] addr_i_32,
    input [127:0] data_i,
    input stb_i,
    output ack_o,
    output [127:0] app_rd_data,
    output app_rd_data_valid,
    output app_rdy
    );

    wire [26:0]addr_i;
    assign addr_i[26:3]=addr_i_32[23:0];
    assign addr_i[2:0]=3'b0;

    //---MIG IP core parameter
    //---user interface signals
    
    wire app_en_wr;
   
    wire [2:0] app_cmd_wr;
    wire [26:0] app_addr_wr;
    wire app_en;
    wire [127:0] app_wdf_data;
    wire app_wdf_end;
    wire [26:0] app_addr;
    reg [2:0] app_cmd;
    wire app_wdf_wren;
   // wire [127:0] app_rd_data;
    wire app_rd_data_end;
   // wire app_rd_data_valid;
    //wire app_rdy;
    wire app_wdf_rdy;
    wire [2:0] app_cmd_pe;
    wire [26:0] app_addr_pe;
    wire app_en_pe;
    wire app_ref_ack;
    wire app_zq_ack;
    wire app_sr_active;
    
    wire ui_clk;
    wire ui_clk_sync_rst;

  
    assign app_en = app_en_wr | app_en_pe;


    always @(*)
    begin
        if(stb_i&app_en_wr)
            app_cmd <= app_cmd_wr;
        else if(~stb_i&app_en_pe) 
             app_cmd <= app_cmd_pe;
    end

    assign app_addr=addr_i;



    wire read_en;

    ddr2_write_control ctr_ddr_write(
        .clk_in(ui_clk),
        ._rst(ui_clk_sync_rst),
        .I_ADDR(addr_i),
        .I_DATA(data_i),
        .I_STB(stb_i),
        .O_ACK(ack_o),
        .en_read(read_en),
        //ddr_signals
        .app_en(app_en_wr),
        .app_wdf_wren(app_wdf_wren),
        .app_wdf_end(app_wdf_end),
        .app_cmd(app_cmd_wr),
        .app_addr(app_addr_wr),
        .app_wdf_data(app_wdf_data),
        .app_rdy(app_rdy),
        .app_wdf_rdy(app_wdf_rdy)
    );

    /* DDR2 ��???��???��??? */
    ddr2_read_control ctr_ddr_read(
        .clk_in(ui_clk),
        ._rst(ui_clk_sync_rst),
        .ena(~stb_i),
        .addr_read(addr_i),
        //ddr2_signal
        .app_en(app_en_pe),
        .app_cmd(app_cmd_pe),
        .app_addr(app_addr_pe),
        .app_rd_data(app_rd_data),
        .app_rdy(app_rdy),
        .app_rd_data_end(app_rd_data_end),
        .app_rd_data_valid(app_rd_data_valid)
    );



//MIG IP core
ddr2_ram mig_ddr2_ram (
    // Memory interface ports
    .ddr2_addr                      (ddr2_addr),  // output [12:0]                       ddr2_addr
    .ddr2_ba                        (ddr2_ba),  // output [2:0]                      ddr2_ba
    .ddr2_cas_n                     (ddr2_cas_n),  // output                                       ddr2_cas_n
    .ddr2_ck_n                      (ddr2_ck_n),  // output [0:0]                        ddr2_ck_n
    .ddr2_ck_p                      (ddr2_ck_p),  // output [0:0]                        ddr2_ck_p
    .ddr2_cke                       (ddr2_cke),  // output [0:0]                       ddr2_cke
    .ddr2_ras_n                     (ddr2_ras_n),  // output                                       ddr2_ras_n
    .ddr2_we_n                      (ddr2_we_n),  // output                                       ddr2_we_n
    .ddr2_dq                        (ddr2_dq),  // inout [15:0]                         ddr2_dq
    .ddr2_dqs_n                     (ddr2_dqs_n),  // inout [1:0]                        ddr2_dqs_n
    .ddr2_dqs_p                     (ddr2_dqs_p),  // inout [1:0]                        ddr2_dqs_p
    .init_calib_complete            (init_calib_complete),  // output                                       init_calib_complete

    .ddr2_cs_n                      (ddr2_cs_n),  // output [0:0]           ddr2_cs_n
    .ddr2_dm                        (ddr2_dm),  // output [1:0]                        ddr2_dm
    .ddr2_odt                       (ddr2_odt),  // output [0:0]                       ddr2_odt
    // Application interface ports
    .app_addr                       (app_addr),  // input [26:0]                       app_addr
    .app_cmd                        (app_cmd),  // input [2:0]                                  app_cmd
    .app_en                         (app_en),  // input                                        app_en
    .app_wdf_data                   (app_wdf_data),  // input [127:0]    app_wdf_data
    .app_wdf_end                    (app_wdf_end),  // input                                        app_wdf_end
    .app_wdf_wren                   (app_wdf_wren),  // input                                        app_wdf_wren
    .app_rd_data                    (app_rd_data),  // output [127:0]   app_rd_data
    .app_rd_data_end                (app_rd_data_end),  // output                                       app_rd_data_end
    .app_rd_data_valid              (app_rd_data_valid),  // output                                       app_rd_data_valid
    .app_rdy                        (app_rdy),  // output                                       app_rdy
    .app_wdf_rdy                    (app_wdf_rdy),  // output                                       app_wdf_rdy
    .app_sr_req                     (1'b0),  // input                                        app_sr_req
    .app_ref_req                    (1'b0),  // input                                        app_ref_req
    .app_zq_req                     (1'b0),  // input                                        app_zq_req
    .app_sr_active                  (app_sr_active),  // output                                       app_sr_active
    .app_ref_ack                    (app_ref_ack),  // output                                       app_ref_ack
    .app_zq_ack                     (app_zq_ack),  // output                                       app_zq_ack
    .ui_clk                         (ui_clk),  // output                                       ui_clk
    .ui_clk_sync_rst                (ui_clk_sync_rst),  // output                                       ui_clk_sync_rst

    .app_wdf_mask                   (16'h0000),  // input [15:0]  app_wdf_mask

    // System Clock Ports
    .sys_clk_i                       (clk_in),
    // Reference Clock Ports
    .clk_ref_i                      (clk_ref_i),
    .sys_rst                        (~rst) // input  sys_rst  ��??��?��?????��???
);
endmodule


//-----------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------
