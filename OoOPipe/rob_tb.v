module rob_tb();

reg rst;
reg clk;
reg isDispatch, MemOp, RegDest;
reg [5:0] PR_old_DP, PR_new_DP;
reg [4:0] rd_DP;

reg complete;
reg [3:0] rob_number;
reg [31:0] jb_addr;
reg changeFlow;

reg hazard_stall;

wire rob_num_dp;
//retire stage, 
wire [5:0] PR_old_RT;
wire RegDest_retire;
wire retire_reg;
//to LSQ
wire retire_LWST;
wire [3:0] retire_rob;

wire full;
wire empty;

//roll back
wire RegDest_out;
wire [5:0] PR_old_flush;
wire [5:0] PR_new_flush;
wire [4:0] rd_flush;
wire [3:0] out_rob_num;
wire changeFlow_out;    //jump or branch misprediction
wire [31:0] changeFlow_addr; //jump or branch misprediction
wire recover;

reorder_buffer i_reorder_buffer(
                                .rst(rst),
                                .clk(clk),
                                .isDispatch(isDispatch),
                                .isSW(MemOp),
                                .RegDest(RegDest),
                                .PR_old_DP(PR_old_DP),
                                .PR_new_DP(PR_new_DP),
                                .rd_DP(rd_DP),
                                .complete(complete),
                                .rob_number(rob_number),
                                .jb_addr(jb_addr),
                                .changeFlow(changeFlow),
                                .hazard_stall(hazard_stall),
                                .rob_num_dp(rob_num_dp),
                                .PR_old_RT(PR_old_RT),
                                .RegDest_retire(RegDest_retire),
                                .retire_reg(retire_reg),
                                .retire_ST(retire_LWST),
                                .retire_rob(retire_rob),
                                .full(full),
                                .empty(empty),
                                .RegDest_out(RegDest_out),
                                .PR_old_flush(PR_old_flush),
                                .PR_new_flush(PR_new_flush),
                                .rd_flush(rd_flush),
                                .out_rob_num(out_rob_num),
                                .changeFlow_out(changeFlow_out),
                                .changeFlow_addr(changeFlow_addr),
                                .recover(recover));

initial begin
    clk = 0;
    rst = 0;
    hazard_stall = 0;
    #2 rst = 1;
    set_dispatch(0, 0, 0, 6'h00, 6'h00, 6'h00);    //set isDispatch to 0
    set_complete(0, 4'h0, 32'h00000000, 0);    //set complete to 0
    @(posedge clk);
    set_dispatch(1, 0, 1, 6'h01, 6'h21, 6'h01);    //start dispatch
    set_complete(0, 4'h0, 32'h00000000, 0);    //set complete to 0
    @(posedge clk);
    set_dispatch(1, 0, 1, 6'h02, 6'h22, 6'h02);    //dispatch
    set_complete(0, 4'h0, 32'h00000000, 0);    //set complete to 0
    @(posedge clk);
    set_dispatch(1, 0, 1, 6'h03, 6'h23, 6'h03);    //dispatch
    set_complete(1, 4'h1, 32'h00000000, 0);    //the instruction in ROB #1 completes
    @(posedge clk);
    set_dispatch(1, 0, 1, 6'h04, 6'h24, 6'h04);    //dispatch
    set_complete(1, 4'h0, 32'h00000000, 0);    //the instruction in ROB #0 completes
    @(posedge clk);
    set_dispatch(1, 0, 1, 6'h05, 6'h25, 6'h05);    //dispatch
    set_complete(1, 4'h2, 32'h00000000, 0);    //the instruction in ROB #2 completes
    @(posedge clk);
    set_dispatch(0, 0, 0, 6'h01, 6'h21, 6'h01);    //set isDispatch to 0
    set_complete(0, 4'h0, 32'h00000000, 0);    //set complete to 0
    @(posedge clk);
    set_dispatch(1, 0, 0, 6'h06, 6'h26, 6'h06);    //dispatch
    set_complete(0, 4'h0, 32'h00000000, 0);    //set complete to 0
    @(posedge clk);
    hazard_stall = 1;
    repeat (3) @(posedge clk);
    hazard_stall = 0;
    set_dispatch(1, 0, 1, 6'h07, 6'h27, 6'h07);    //dispatch
    set_complete(1, 4'h3, 32'h00000010, 1);    //the instruction in ROB #3 completes, a jump instruction
    @(posedge clk);
    set_dispatch(0, 0, 1, 6'h08, 6'h28, 6'h08); 
    set_complete(1, 4'h4, 32'h00000000, 0);
    repeat (4) @(posedge clk);     //waiting for roll back
    $stop;
end

always 
#5 clk = ~clk;

task set_dispatch(input isDis, input Mop, input regD, input [5:0] pr_old_dp, input [5:0] pr_new_dp,
                  input [4:0] rd_dp);
    begin
    isDispatch = isDis; MemOp = Mop; RegDest = regD; PR_old_DP = pr_old_dp; PR_new_DP = pr_new_dp; 
    rd_DP = rd_dp; 
    end
endtask

task set_complete(input compl, input [3:0] ROB_num, input [31:0] jb_add, input changeflow);
    begin
    complete = compl; rob_number = ROB_num; jb_addr = jb_add; changeFlow = changeflow;    
    end
endtask

endmodule
