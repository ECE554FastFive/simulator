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
decoder i_decoder(
                  .opcode(instr_IF_DP[31:26]),
                  .writeRd(writeRd),
                  .RegDest(RegDest),
                  .isDispatch(isDispatch),
                  .mem_wen(mem_wen));
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
reorder_buffer i_reorder_buffer(
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
/*ls_station i_ls_station(
                        .clk(clk),
                        .rst(rst),
                        .isDispatch(isDispatch),
                        .rob_num_dp(rob_num_dp),
                        .p_rd_new(p_rd_new),
                        .p_rs(p_rs),
                        .v_rs(v_rs),
                        .p_rt(p_rt),
                        .v_rt(v_rt),
                        .mem_ren(mem_ren),
                        .mem_wen(mem_wen),
                        .immed(immed),
                        .stall_hazard(stall_hazard),
                        .recover(recover),
                        .rob_num_rec(rob_num_rec),
                        .p_rd_compl(p_rd_compl),
                        .RegDest_compl(RegDest_compl),
                        .complete(complete),
                        .p_rs_out(p_rs_out),
                        .p_rt_out(p_rt_out),
                        .p_rd_out(p_rd_out),
                        .immed_out(immed_out),
                        .RegDest_out(RegDest_out),
                        .mem_ren_out(mem_ren_out),
                        .mem_wen_out(mem_wen_out),
                        .issue(issue),
                        .lss_full(lss_full));


/////////////////////////////////physical register for ALU////////////////////////////
physical_register i_physical_register_ALU(
                                      .raddr0(raddr0),
                                      .raddr1(raddr1),
                                      .we(we),
                                      .waddr(waddr),
                                      .din(din),
                                      .clk(clk),
                                      .dout0(dout0),
                                      .dout1(dout1));

/////////////////////////////////physical register for MEM////////////////////////////
physical_register i_physical_register_MEM(
                                      .raddr0(raddr0),
                                      .raddr1(raddr1),
                                      .we(we),
                                      .waddr(waddr),
                                      .din(din),
                                      .clk(clk),
                                      .dout0(dout0),
                                      .dout1(dout1));
*/
endmodule
