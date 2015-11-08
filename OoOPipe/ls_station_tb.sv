//dispatch: 
//if not full, allocate entry in lss at tail, increase tail, set the lss_valid;
//issue: if the head is ready, issue the head, clear the valid bit
//complete: check if rs and rt in lss matches with rd_compl, if yes, set that v_rs, v_rt
//recovery: check is rob_num matches rob_num_rec, if yes, flush that entry by clearing bit 41, 40

module ls_station_tb();

reg clk;
reg rst;

//from dispatch
reg isDispatch;
reg [3:0] rob_num_dp;
reg [5:0] p_rd_new;
reg [5:0] p_rs;
reg v_rs;
reg [5:0] p_rt;
reg v_rt;
reg mem_ren;
reg mem_wen;
reg [15:0] immed;

reg stall_hazard;

//from recovery (ROB)
reg recover;
reg [3:0] rob_num_rec;

//from complete
reg [5:0] p_rd_compl;
reg RegDest_compl;
reg complete;

//to physical register and execution units, LSQ
wire [5:0] p_rs_out;
wire [5:0] p_rt_out;
wire [5:0] p_rd_out;
wire [15:0] immed_out;
wire RegDest_out;
wire mem_ren_out;
wire mem_wen_out;
wire issue;
wire lss_full;

ls_station i_lss(
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
integer assert_idx;

initial begin
    clk = 0;
    rst = 0;
    assert_idx = 0;
    #2 rst = 1;
    set_dispatch(0, 4'h0, 6'h00, 6'h00, 0, 6'h00, 0, 0, 0, 16'h0000);
    set_rec(0, 4'h0);
    set_compl(6'h00, 0, 0);
    stall_hazard = 1'b0;
    @(negedge clk) 
    set_dispatch(1, 4'h1, 6'h03, 6'h01, 1, 6'h02, 1, 0, 0, 16'h0000);  //ADD r3, r1, r2
    
    ///checking the dispatch
    @(negedge clk)
    assert (i_lss.tail == 4'b0001 &&
            i_lss.head == 4'b0001 &&
            i_lss.lss_valid[0] == 1'b0
           ) $display("Ok, success dispatch %0d!", assert_idx++);
        else $error("not successful");
    set_dispatch(1, 4'h2, 6'h05, 6'h03, 0, 6'h05, 1, 1, 0, 16'h0100);  //LD r5, r3(0x0100)

    @(negedge clk)
    assert (i_lss.tail == 4'b0010 &&
            i_lss.head == 4'b0001 &&
            i_lss.lss_valid[0] == 1'b1 &&
            i_lss.ls_station[0][41] == 1'b1 &&
            i_lss.ls_station[0][40] == 1'b0 &&
            i_lss.ls_station[0][35:30] == 6'h05 &&           //p_rd_new
            i_lss.ls_station[0][29:24] == 6'h03 &&           //p_rs
            i_lss.ls_station[0][23] == 1'b0 &&
            i_lss.ls_station[0][22:17] == 6'h05 &&           //p_rt
            i_lss.ls_station[0][16] == 1'b1 &&
            i_lss.ls_station[0][15:0] == 16'h0100
           ) $display("Ok, success dispatch %0d!", assert_idx++);
        else $error("not successful");
    set_dispatch(1, 4'h3, 6'h00, 6'h03, 1, 6'h02, 0, 0, 1, 16'h0100);  //SW r2, r3(0x0100)

    @(negedge clk)
    assert (i_lss.tail == 4'b0100 &&
            i_lss.head == 4'b0001 &&
            i_lss.lss_valid[1] == 1'b1 &&
            i_lss.ls_station[1][41] == 1'b0 &&
            i_lss.ls_station[1][40] == 1'b1 &&
            i_lss.ls_station[1][35:30] == 6'h00 &&         //p_rd_new
            i_lss.ls_station[1][29:24] == 6'h03 &&         //p_rs
            i_lss.ls_station[1][23] == 1'b1 &&
            i_lss.ls_station[1][22:17] == 6'h02 &&         //p_rt
            i_lss.ls_station[1][16] == 1'b0 &&
            i_lss.ls_station[1][15:0] == 16'h0100
           ) $display("Ok, success dispatch %0d!", assert_idx++);
        else $error("not successful");
    
    set_dispatch(1, 4'h4, 6'h00, 6'h03, 1, 6'h02, 0, 0, 1, 16'h0100);  //SW r2, r3(0x0100)

    @(negedge clk)
    assert (i_lss.tail == 4'b1000 &&
            i_lss.head == 4'b0001 &&
            i_lss.lss_valid[2] == 1'b1 &&
            i_lss.ls_station[2][41] == 1'b0 &&
            i_lss.ls_station[2][40] == 1'b1 &&
            i_lss.ls_station[2][35:30] == 6'h00 &&         //p_rd_new
            i_lss.ls_station[2][29:24] == 6'h03 &&         //p_rs
            i_lss.ls_station[2][23] == 1'b1 &&
            i_lss.ls_station[2][22:17] == 6'h02 &&         //p_rt
            i_lss.ls_station[2][16] == 1'b0 &&
            i_lss.ls_station[2][15:0] == 16'h0100
           ) $display("Ok, success dispatch %0d!", assert_idx++);
        else $error("not successful");
    
    set_dispatch(1, 4'h5, 6'h00, 6'h03, 1, 6'h02, 1, 0, 1, 16'h0100);  //SW r2, r3(0x0100)

    @(negedge clk)
    assert (i_lss.tail == 4'b0001 &&
            i_lss.head == 4'b0001 &&
            i_lss.lss_valid[3] == 1'b1 &&
            i_lss.ls_station[3][41] == 1'b0 &&
            i_lss.ls_station[3][40] == 1'b1 &&
            i_lss.ls_station[3][35:30] == 6'h00 &&         //p_rd_new
            i_lss.ls_station[3][29:24] == 6'h03 &&         //p_rs
            i_lss.ls_station[3][23] == 1'b1 &&
            i_lss.ls_station[3][22:17] == 6'h02 &&         //p_rt
            i_lss.ls_station[3][16] == 1'b1 &&
            i_lss.ls_station[3][15:0] == 16'h0100 &&
            i_lss.lss_full == 1
           ) $display("Ok, success dispatch %0d!", assert_idx++);
        else $error("not successful");

    ////////////////////////////check if the full signal prevents writing////////////////////////
    set_dispatch(1, 4'h6, 6'h00, 6'h03, 1, 6'h02, 1, 0, 1, 16'h0100);  //SW r2, r3(0x0100)

    @(negedge clk)
    //////check if the entry 0 is still unchanged
    assert (i_lss.tail == 4'b0001 &&
            i_lss.head == 4'b0001 &&
            i_lss.lss_valid[0] == 1'b1 &&
            i_lss.ls_station[0][41] == 1'b1 &&
            i_lss.ls_station[0][40] == 1'b0 &&
            i_lss.ls_station[0][35:30] == 6'h05 &&         //p_rd_new
            i_lss.ls_station[0][29:24] == 6'h03 &&         //p_rs
            i_lss.ls_station[0][23] == 1'b0 &&
            i_lss.ls_station[0][22:17] == 6'h05 &&         //p_rt
            i_lss.ls_station[0][16] == 1'b1 &&
            i_lss.ls_station[0][15:0] == 16'h0100
           ) $display("Ok, success dispatch full check %0d!", assert_idx++);
        else $error("not successful");

    //check complete, first r3 completes
    set_dispatch(0, 4'h0, 6'h00, 6'h00, 0, 6'h00, 0, 0, 0, 16'h0000);
    set_compl(6'h03, 1, 1);
    @(negedge clk)
    assert (i_lss.rs_match_array[0] == 1'b1 &&
            i_lss.ls_station[0][23] == 1'b1 &&
            issue == 1'b1 &&
            p_rs_out == 6'h03 &&
            p_rt_out == 6'h05 &&
            p_rd_out == 6'h05 &&
            RegDest_out == 1'b1 &&
            mem_ren_out ==1'b1 &&
            mem_wen_out == 1'b0 &&
            i_lss.head == 4'b0001
           ) $display("Ok, success complete check %0d!", assert_idx++);
        else $error("not successful");
    
    set_compl(6'h02, 1, 1);
    @(negedge clk)       
    assert (                                    //the entry #1 is issued
            i_lss.ls_station[1][16] == 1'b1 &&
            i_lss.ls_station[2][16] == 1'b1 &&
            i_lss.ls_station[3][16] == 1'b1 &&
            issue == 1'b1 &&
            p_rs_out == 6'h03 &&
            p_rt_out == 6'h02 &&
            RegDest_out == 1'b0 &&
            mem_ren_out ==1'b0 &&
            mem_wen_out == 1'b1 &&
            i_lss.head == 4'b0010 &&
            i_lss.lss_valid[0] == 1'b0 &&
            lss_full == 1'b0
           ) $display("Ok, success complete and issue check %0d!", assert_idx++);
        else $error("not successful");

    set_rec(1, 4'h4);
    set_compl(6'h00, 0, 0);

    @(negedge clk) 
    assert (                                    //the entry #1 is issued
            issue == 1'b0 &&
            p_rs_out == 6'h03 &&
            p_rt_out == 6'h02 &&
            RegDest_out == 1'b0 &&
            mem_ren_out ==1'b0 &&
            mem_wen_out == 1'b1 &&
            i_lss.head == 4'b0010 &&
            i_lss.lss_valid[0] == 1'b0 &&
            i_lss.ls_station[2][40] == 1'b0 &&
            i_lss.ls_station[2][41] == 1'b0
           ) $display("Ok, success recovery check %0d!", assert_idx++);
        else $error("not successful");
    $stop;
end

always 
#5 clk = ~clk;

task set_dispatch(input isDis, input [3:0] rob_n, input [5:0] prd, input [5:0] prs, input vrs,
                  input [5:0] prt, input vrt, input mren, input mwen, input [15:0] imm); begin
     isDispatch = isDis; rob_num_dp = rob_n; p_rd_new = prd; p_rs = prs; v_rs = vrs;
     p_rt = prt; v_rt = vrt; mem_ren = mren; mem_wen = mwen; immed = imm;    
end
endtask

task set_rec(input rec, input [3:0] rob_n); begin
    recover = rec; rob_num_rec = rob_n;
end
endtask

task set_compl(input [5:0] prd, input RegDest, input compl); begin
    p_rd_compl = prd; RegDest_compl = RegDest; complete = compl;
end
endtask

endmodule
