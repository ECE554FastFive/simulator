module OoO_cpu(
    input clk, rst 
);

//////////////////////////insturction fetch and IF/DP pipeline////////////////////////////////

/////////////////some temporary signals/////////////////
wire changeFlow_IF; assign changeFlow_IF = 0;
wire [31:0] jb_addr_IF; assign jb_addr_IF = {32{1'b0}};
wire stall_PC; assign stall_PC = 0;
wire stall_IF_DP; assign stall_IF_DP = 0;
wire flush_IF_DP; assign flush_IF_DP = 0;
wire [31:0] instr_IF_DP;
wire [31:0] pc_1_IF_DP;
///////////////////////////////////////////////////////
IF_stage i_IF_stage(
                    .clk(clk),
                    .rst(rst),
                    .changeFlow(changeFlow_IF),
                    .jb_addr(jb_addr_IF),
                    .stall_PC(stall_PC),
                    .stall_IF_DP(stall_IF_DP),
                    .flush_IF_DP(flush_IF_DP),
                    .instr_IF_DP(instr_IF_DP),
                    .pc_1_IF_DP(pc_1_IF_DP));

/////////////////////////////////decoder////////////////////////////////////
wire writeRd;           //asserted for write rd, deasserted for write rt
wire RegDest;           //asserted when write register
wire isDispatch;        //

wire mem_wen;
wire mem_ren;
wire read_rs, read_rt;

//to alu reservation station
wire alloca_RS_en;
wire ldic, isSignedEx, isImmed;
wire alu_ctrl0, alu_ctrl1, alu_ctrl2, alu_ctrl3;
wire isJump, isJR;
wire link;

decoder i_decoder(
                  .opcode(instr_IF_DP[31:26]),
                  .writeRd(writeRd),
                  .RegDest(RegDest),
                  .isDispatch(isDispatch),
                  .mem_wen(mem_wen),
                  .mem_ren(mem_ren),
                  .read_rs(read_rs),
                  .read_rt(read_rt),
                  .alloc_RS_en(alloc_RS_en),
                  .ldic(ldic),
                  .isSignEx(isSignEx),
                  .isImmed(isImmed),
                  .alu_ctrl0(alu_ctrl0),
                  .alu_ctrl1(alu_ctrl1),
                  .alu_ctrl2(alu_ctrl2),
                  .alu_ctrl3(alu_ctrl3),
                  .isJump(isJump),
                  .isJR(isJR),
                  .link(link));
////////////////////////////////////////////////////////////////////////////

//////////////////////////map table//////////////////////////////////////////

////temporary signals/////////////////////////////////////////////////////
wire hazard_stall_map_table; assign hazard_stall_map_table = 0;
/////////////recovery////////////////
wire [4:0] recover_rd; 
wire [5:0] p_rd_flush; 
/////////////////complete///////
wire [5:0] p_rd_compl; assign p_rd_compl = 6'h00;
wire complete = 0;
wire RegDest_compl = 0;
//////////////////////////////////////////////////////////////////////////
wire [4:0] l_rs_map_table;
wire [4:0] l_rt_map_table;
wire [4:0] l_rd_map_table;
wire [5:0] PR_new;   //from free list

////////////////these four to reservation station
wire [5:0] p_rs;            
wire p_rs_v;
wire [5:0] p_rt;
wire p_rt_v;
wire [5:0] PR_old_DP;    //to ROB

//from ROB, for recovery
wire recover;
wire RegDest_ROB;
wire [4:0] flush_rd; 
wire [5:0] PR_old_flush;

assign l_rs_map_table = instr_IF_DP[25:21];
assign l_rt_map_table = instr_IF_DP[20:16];
assign l_rd_map_table = writeRd ? instr_IF_DP[15:11] : instr_IF_DP[20:16];

map_table i_map_table(
                      .clk(clk),
                      .rst(rst),
                      .hazard_stall(hazard_stall_map_table),
                      .l_rs(l_rs_map_table),
                      .l_rt(l_rt_map_table),
                      .l_rd(l_rd_map_table),
                      .isDispatch(isDispatch),
                      .RegDest(RegDest),
                      .p_rd_new(PR_new),
                      .recover_rd(flush_rd),
                      .p_rd_flush(PR_old_flush),
                      .recover(recover),
                      .RegDest_ROB(RegDest_ROB),
                      .p_rd_compl(p_rd_compl),
                      .complete(complete),
                      .RegDest_compl(RegDest_compl),
                      .p_rs(p_rs),
                      .p_rt(p_rt),
                      .p_rs_v(p_rs_v),
                      .p_rt_v(p_rt_v),
                      .PR_old_rd(PR_old_DP));

///////////////////////////////free list ////////////////////////////////////

///////////////temporary signals//////////////////////
wire hazard_stall_free_list = 0;

/////////////////////////////////////////////////////
wire free_list_empty;
wire [5:0] PR_old_RT;     //from re-order buffer
wire RegDest_retire;
wire retire_reg;

//for recovery
wire [5:0] PR_new_flush;

free_list_new i_free_list_new(
                              .PR_old(PR_old_RT),
                              .RegDest_retire(RegDest_retire),
                              .retire_reg(retire_reg),
                              .RegDest(RegDest),
                              .clk(clk),
                              .rst(rst),
                              .hazard_stall(hazard_stall_free_list),
                              .recover(recover),
                              .PR_new_flush(PR_new_flush),
                              .RegDest_ROB(RegDest_ROB),
                              .PR_new(PR_new),
                              .empty(free_list_empty));


////////////////////////////reorder buffer/////////////////////////////////////

///////////////temporary signals/////////////////////
wire [3:0] rob_num_compl = 4'h0;
/////////////these two from complete stage
wire changeFlow_rob_in = 0;
wire [31:0] jb_addr_rob_in = {32{1'b0}};    
wire hazard_stall_rob = 0; 
/////////////////////////////////////////////////////

//////these two go to store queue
wire retire_ST;
wire [3:0] retire_rob;

wire rob_full, rob_empty;
wire [3:0] flush_rob_num;

wire [3:0] rob_num_dp;   //rob number written into reservation station
reorder_buffer_beh i_reorder_buffer(
                                .rst(rst),
                                .clk(clk),
                                .isDispatch(isDispatch),
                                .isSW(mem_wen),
                                .RegDest(RegDest),
                                .PR_old_DP(PR_old_DP),
                                .PR_new_DP(PR_new),
                                .rd_DP(l_rd_map_table),
                                .complete(complete),
                                .rob_number(rob_num_compl),
                                .jb_addr(jb_addr_rob_in),
                                .changeFlow(changeFlow_rob_in),
                                .hazard_stall(hazard_stall_rob),
                                .rob_num_dp(rob_num_dp),
                                .PR_old_RT(PR_old_RT),
                                .RegDest_retire(RegDest_retire),
                                .retire_reg(retire_reg),
                                .retire_ST(retire_ST),
                                .retire_rob(retire_rob),
                                .full(full),
                                .empty(empty),
                                .RegDest_out(RegDest_ROB),
                                .PR_old_flush(PR_old_flush),
                                .PR_new_flush(PR_new_flush),
                                .rd_flush(flush_rd),
                                .out_rob_num(flush_rob_num),
                                .changeFlow_out(changeFlow_IF),
                                .changeFlow_addr(jb_addr_IF),
                                .recover(recover));


///////////////////////////////////////////ls_station//////////////////////////////////

///////////temporary wires/////////////////
wire hazard_stall_lss; assign hazard_stall_lss = 0;

///////////////////////////////////////////

wire [5:0] p_rs_lss, p_rt_lss, p_rd_lss;
wire [15:0] immed_lss;
wire [3:0] rob_num_lss;
wire RegDest_lss, mem_ren_lss, mem_wen_lss;
wire issue_lss;
wire lss_full;

ls_station i_lss(       .clk(clk),
                        .rst(rst),
                        .isDispatch(isDispatch),
                        .rob_num_dp(rob_num_dp),   //from rob in dispatch stage
                        .p_rd_new(PR_new),       //from free list
                        .p_rs(p_rs),           //these four signals from map table
                        .read_rs(read_rs),      //from decoder ********
                        .v_rs(p_rs_v),
                        .p_rt(p_rt),
                        .read_rt(read_rt),      //from decoder  ********
                        .v_rt(p_rt_v),
                        .mem_ren(mem_ren),     //from decoder   ********
                        .mem_wen(mem_wen),     //from decoder   ********
                        .immed(instr_IF_DP[15:0]),         //from decode
                        .stall_hazard(hazard_stall_lss),
                        .recover(recover),                     //from ROB
                        .rob_num_rec(flush_rob_num),           //from ROB
                        .p_rd_compl(p_rd_compl),             
                        .RegDest_compl(RegDest_compl),
                        .complete(complete),
                        .p_rs_out(p_rs_lss),
                        .p_rt_out(p_rt_lss),
                        .p_rd_out(p_rd_lss),
                        .immed_out(immed_lss),
                        .rob_num_out(rob_num_lss),
                        .RegDest_out(RegDest_lss),
                        .mem_ren_out(mem_ren_lss),
                        .mem_wen_out(mem_wen_lss),
                        .issue(issue_lss),
                        .lss_full(lss_full)); 

////////////////////////////////ALU reservation station///////////////////////////////////
wire rs_alu_full;
///////////////temporary signals////////////
wire stall_hazard_rs_alu;
assign stall_hazard_rs_alu = 0;
wire stall_issue = 0;
////////////////////////////////////////////

wire issue_en_alu;
//to EX (IS/EX pipeline reg)
wire [16:0] EX_ctrl_in;
//[5:0] opcode, [6] ldic, [7] isSignEx, [8] isImmed, [9] alu_ctrl0, [10] alu_ctrl1, [11] alu_ctrl2, [12] alu_ctrl3
//[13] isJump, [14] isJR, [15] RegDest, [16] link
assign EX_ctrl_in = { link,
                      RegDest,
                      isJR,
                      isJump,
                      alu_ctrl3, alu_ctrl2, alu_ctrl1, alu_ctrl0,
                      isImmed, isSignEx,
                      ldic,                     //load instruction count
                      instr_IF_DP[31:26] };
                      
wire [31:0] PC_out_rs_alu;
wire [15:0] imm_rs_alu;
//go through EX (IS/EX pipeline reg)stage, but used in COMPL stage
wire [3:0] EX_rob_alu;
wire [5:0] p_rd_rs_alu;
//to physical register
wire [5:0] p_rs_out_alu, p_rt_out_alu;

rs_alu i_rs_alu(
                  .clk(clk),
                  .rst(rst),
                  .num_rob_entry(rob_num_dp),   //rob number of rob in dispatch stage
                  .PC_in(pc_1_IF_DP),       //
                  .EX_ctrl_in(EX_ctrl_in),
                  .p_rs_in(p_rs),        //from map table 
                  .p_rt_in(p_rt),
                  .p_rs_rdy_in(p_rs_v),   //valid bits from map table
                  .p_rt_rdy_in(p_rt_v),
                  .rs_read(read_rs),      //from the decoder, indicates if read rs/rt
                  .rt_read(read_rt),
                  .imm_bits_in(instr_IF_DP[15:0]),   //immediate value
                  .p_rd_new(PR_new),               //from free list
                  .alloc_RS_en(alloc_RS_en),
                  .recover(recover),
                  .rec_rob_entry(flush_rob_num),
                  .stall_hazard(stall_hazard_rs_alu),
                  .stall_issue(stall_issue),
                  .bus_en(complete && RegDest_compl),   //set ready bit only if RegDest is 1
                  .tag(p_rd_compl),
                  .issue_en(issue_en_alu),
                  .PC_out(PC_out_rs_alu),                   //to EX stage
                  .rob_id_out(EX_rob_alu),
                  .EX_ctrl_out(EX_ctrl_out),         //one part to EX, the other part used in COMPL  
                  .p_rs_out(p_rs_out_alu),               //to physical register
                  .p_rt_out(p_rt_out_alu),
                  .imm_bits_out(imm_rs_alu),       
                  .p_rd_out(p_rd_rs_alu),
                  .stl_dec_rs_alu_full(rs_alu_full));

/////////temporary wires////////////////////
wire [31:0] result_compl;
assign result_compl = 32'h00000000;

////////////////////////////////////////////

wire [31:0] rs_data_IS_EX_alu, rt_data_IS_EX_alu;
/////////////////////////////////physical register for ALU////////////////////////////
physical_register i_physical_register_ALU(
                                      .raddr0(p_rs_out_alu),
                                      .raddr1(p_rt_out_alu),
                                      .we(RegDest_compl),
                                      .waddr(p_rd_compl),
                                      .din(result_compl),
                                      .clk(clk),
                                      .dout0(rs_data_IS_EX_alu),
                                      .dout1(rt_data_IS_EX_alu));

//////////////////////////////IS/EX pipeline register for ALU instructions///////////////
//pc_1, immed_value, ldic, isSignedEx, immed, alu_ctrls, isJump, isJR, 
////temporary wires//////////
wire [15:0] instr_cnt, cycle_cnt;
assign instr_cnt = 16'h0000;
assign cycle_cnt = 16'h0000;
/////////////////////////////

/////////////////////////////////functional units////////////////////////////////////////
EX_stage_OoO i_EX_stage_OoO(
                            .instr_cnt(instr_cnt),
                            .cycle_cnt(cycle_cnt),
                            .rs_data(rs_data_IS_EX_alu),
                            .rt_data(rt_data_IS_EX_alu),
                            .pc_1(pc_1),
                            .immed_value(immed_value),
                            .opcode(opcode),
                            .ldic(ldic),
                            .isSignEx(isSignEx),
                            .immed(immed),
                            .alu_ctrl0(alu_ctrl0),
                            .alu_ctrl1(alu_ctrl1),
                            .alu_ctrl2(alu_ctrl2),
                            .alu_ctrl3(alu_ctrl3),
                            .isJump(isJump),
                            .isJR(isJR),
                            .alu_out(alu_out),
                            .changeFlow(changeFlow),
                            .jb_addr(jb_addr));


/////////////////////////////////physical register for MEM////////////////////////////

//////////////////////////////////
//physical register serves as part of IS_EX pipeline register
wire [31:0] rs_data_IS_EX_ls, rt_data_IS_EX_ls;
physical_register i_physical_register_LS(
                                      .raddr0(p_rs_lss),
                                      .raddr1(p_rt_lss),
                                      .we(RegDest_compl),
                                      .waddr(p_rd_compl),
                                      .din(result_compl),
                                      .clk(clk),
                                      .dout0(rs_data_IS_EX_ls),
                                      .dout1(rt_data_IS_EX_ls));

/////////////IS_EX pipeline register, for LS/ST/////////////////////////////////////
///*****************WILL CONSIDER STALL HERE
reg [5:0] p_rd_IS_EX_ls;
reg [15:0] immed_IS_EX_ls;
reg [3:0] rob_num_IS_EX_ls;
reg RegDest_IS_EX_ls;
reg mem_ren_IS_EX_ls;
reg mem_wen_IS_EX_ls;
reg issue_IS_EX_ls;


always @(posedge clk or negedge rst) begin
    if (!rst) begin
        {p_rd_IS_EX_ls, immed_IS_EX_ls, rob_num_IS_EX_ls} <= 0;
        {RegDest_IS_EX_ls, mem_ren_IS_EX_ls, mem_wen_IS_EX_ls, issue_IS_EX_ls} <= 0;
    end
    else if (recover && (rob_num_IS_EX_ls == flush_rob_num)) begin
        {RegDest_IS_EX_ls, mem_ren_IS_EX_ls, mem_wen_IS_EX_ls, issue_IS_EX_ls} <= 0;
    end
    else begin
        {p_rd_IS_EX_ls, immed_IS_EX_ls, rob_num_IS_EX_ls} <= {p_rd_lss, immed_lss, rob_num_lss};
        {RegDest_IS_EX_ls, mem_ren_IS_EX_ls, mem_wen_IS_EX_ls, issue_IS_EX_ls} <= {RegDest_lss, mem_ren_lss, mem_wen_lss, issue_lss};
    end
end

/////////////////////////////store queue/////////////////////////////

////////temporary wires/////////////
wire hazard_stall_store_queue;  assign hazard_stall_store_queue = 0;
///////////////////////////////////

wire sq_full;
wire isLS_CMP;
wire [31:0] load_result_CMP;
wire [5:0] ls_p_rd_CMP;
wire [3:0] ls_rob_CMP;
wire ls_RegDest_CMP;

////////////////////////////first connect the complete from store queue
store_queue i_store_queue(
                          .clk(clk),
                          .rst(rst),
                          .issue(issue_IS_EX_ls),
                          .mem_wen(mem_wen_IS_EX_ls),
                          .mem_ren(mem_ren_IS_EX_ls),
                          .rs_data(rs_data_IS_EX_ls),
                          .rt_data(rt_data_IS_EX_ls),
                          .immed(immed_IS_EX_ls),
                          .rob_in(rob_num_IS_EX_ls),
                          .p_rd_in(p_rd_IS_EX_ls),
                          .stall_hazard(hazard_stall_store_queue),
                          .retire_ST(retire_ST),
                          .retire_rob(retire_rob),
                          .recover(recover),
                          .rec_rob(flush_rob_num),
                          .sq_full(sq_full),
                          .isLS(isLS_CMP),
                          .load_result(load_result_CMP),
                          .ls_p_rd(ls_p_rd_CMP),
                          .ls_rob(ls_rob_CMP),
                          .ls_RegDest(ls_RegDest_CMP));
endmodule
