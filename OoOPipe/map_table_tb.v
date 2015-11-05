module map_table_tb();

reg clk;
reg rst;
//dispatch
reg [4:0] l_rs;
reg [4:0] l_rt;
reg [4:0] l_rd;
reg [5:0] p_rd_new;
reg RegDest;
//recovery
reg [4:0] recover_rd;
reg [5:0] p_rd_flush;
reg recover;
reg RegDest_ROB;

reg hazard_stall;

reg [5:0] p_rd_compl;
reg complete;
reg RegDest_compl;


wire [5:0] p_rs;
wire [5:0] p_rt;
wire p_rs_v;
wire p_rt_v;
wire [5:0] PR_old_rd;

map_table i_map_table(
                      .clk(clk),
                      .rst(rst),
                      .l_rs(l_rs),
                      .l_rt(l_rt),
                      .l_rd(l_rd),
                      .recover_rd(recover_rd),
                      .p_rd_new(p_rd_new),
                      .p_rd_flush(p_rd_flush),
                      .recover(recover),
                      .hazard_stall(hazard_stall),
                      .RegDest(RegDest),
                      .p_rd_compl(p_rd_compl),
                      .complete(complete),
                      .RegDest_ROB(RegDest_ROB),
                      .RegDest_compl(RegDest_compl),
                      .p_rs(p_rs),
                      .p_rt(p_rt),
                      .p_rs_v(p_rs_v),
                      .p_rt_v(p_rt_v),
                      .PR_old_rd(PR_old_rd));


initial begin
    clk = 0;
    rst = 0;
    hazard_stall = 0;
    set_dispatch(5'h00, 5'h00, 5'h00, 6'h00, 0);
    set_recovery(5'h00, 6'h00, 0, 0);
    set_complete(6'h00, 0, 0);
    #2 rst = 1;
    ////////////////////dispatch tests/////////////////////////
    @(posedge clk);
    set_dispatch(5'h01, 5'h02, 5'h03, 6'h20, 1);      //ADD $r3, $r1, $r2   [3] = 20
    set_recovery(5'h00, 6'h00, 0, 0);
    set_complete(6'h00, 0, 1);
    @(posedge clk);
    set_dispatch(5'h04, 5'h05, 5'h06, 6'h21, 1);      //SUB $r6, $r4, $r5    [6] = 21
    set_recovery(5'h00, 6'h00, 0, 0);
    set_complete(6'h00, 0, 1);
    @(posedge clk);
    set_dispatch(5'h07, 5'h08, 5'h00, 6'h22, 0);      //B $r7 $r8    there's no rd
    set_recovery(5'h00, 6'h00, 0, 0);
    set_complete(6'h00, 0, 1);
    /////////////////////////complete test//////////////////////////
    @(posedge clk);
    set_dispatch(5'h03, 5'h02, 5'h07, 6'h22, 1);      //ADD $r7, $r3, $r2   ,$r3 should have new map,  [7] = 22
    set_recovery(5'h00, 6'h00, 0, 0);
    set_complete(6'h20, 1, 1);
    @(posedge clk);
    set_dispatch(5'h01, 5'h02, 5'h07, 6'h23, 1);      //SUB $r7, $r1, $r2   WAW with ADD   [7] = 23
    set_recovery(5'h00, 6'h00, 0, 0);
    set_complete(6'h21, 1, 1);
    @(posedge clk);
    set_dispatch(5'h01, 5'h02, 5'h09, 6'h24, 1);      //ADD $r9, $r1, $r2    [9] = 24
    set_recovery(5'h00, 6'h00, 0, 0);
    set_complete(6'h22, 0, 0);                            //should not set valid[22]
    @(posedge clk);
    set_dispatch(5'h09, 5'h0a, 5'h0b, 6'h25, 1);      //ADD $r11, $r9, $r10   
    set_recovery(5'h06, 6'h06, 1, 1);                    //[6] = 06
    set_complete(6'h22, 1, 1);   
    @(posedge clk);
    set_dispatch(5'h00, 5'h00, 5'h00, 6'h23, 0);      //NOP
    set_recovery(5'h07, 6'h22, 1, 0);            
    set_complete(6'h22, 1, 0);                           //during recovery, the CDB will also be stalled, value pair will be kept in EX/CMP
    @(posedge clk);
    set_dispatch(5'h00, 5'h00, 5'h00, 6'h23, 0);      //NOP
    set_recovery(5'h09, 6'h24, 0, 0);              //will be not written
    set_complete(6'h23, 1, 1);                           //
    repeat (3) @(posedge clk);
    $stop;
end

always 
#5 clk = ~clk;

task set_dispatch(input [4:0] Lrs, input [4:0] Lrt, input [4:0] Lrd, input [5:0] PR_new, input regdst);
begin
    l_rs = Lrs; l_rt = Lrt; l_rd = Lrd; p_rd_new = PR_new; RegDest = regdst; 
end
endtask

task set_recovery(input [4:0] rec_rd, input [5:0] PR_flush, input rec, input regdst_rob);
begin
    recover_rd = rec_rd; p_rd_flush = PR_flush; recover = rec; RegDest_ROB = regdst_rob;
end
endtask

task set_complete(input [5:0] rd_compl, input compl, input regdst_compl);
begin
    p_rd_compl = rd_compl; complete = compl; RegDest_compl = regdst_compl;
end
endtask

endmodule
