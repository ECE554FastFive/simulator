module rob_tb();

reg rst;
reg clk;
reg isDispatch;
reg [5:0] PR_old_DP;
reg [5:0] PR_new_DP;
reg [4:0] rd_DP;
reg complete;
reg [3:0] rob_number;
reg [31:0] jb_addr;
reg changeFlow;
wire [5:0] PR_old_RT;
wire retire_reg;
wire full;
wire empty;
wire [5:0] PR_old_flush;
wire [5:0] PR_new_flush;
wire [4:0] rd_flush;
wire [3:0] out_rob_num;
wire changeFlow_out;
wire recover;
wire stall_recover;

reorder_buffer i_reorder_buffer(
                                .rst(rst),
                                .clk(clk),
                                .isDispatch(isDispatch),
                                .PR_old_DP(PR_old_DP),
                                .PR_new_DP(PR_new_DP),
                                .rd_DP(rd_DP),
                                .complete(complete),
                                .rob_number(rob_number),
                                .jb_addr(jb_addr),
                                .changeFlow(changeFlow),
                                .PR_old_RT(PR_old_RT),
                                .retire_reg(retire_reg),
                                .full(full),
                                .empty(empty),
                                .PR_old_flush(PR_old_flush),
                                .PR_new_flush(PR_new_flush),
                                .rd_flush(rd_flush),
                                .out_rob_num(out_rob_num),
                                .changeFlow_out(changeFlow_out),
                                .recover(recover),
                                .stall_recover(stall_recover));

initial begin
    clk = 0;
    rst = 0;
    #2 rst = 1;
    set_input(1, 6'h00, 6'h01, 5'h00, 0, 4'h0, 31'h00000000, 0);
    @(posedge clk);
    set_input(1, 6'h01, 6'h02, 5'h01, 0, 4'h0, 31'h00000000, 0);
    @(posedge clk);
    set_input(1, 6'h02, 6'h03, 5'h00, 0, 4'h0, 31'h00000000, 0);
    @(posedge clk);
    set_input(1, 6'h03, 6'h04, 5'h03, 0, 4'h0, 31'h00000001, 0);
    @(posedge clk);
    set_input(1, 6'h04, 6'h05, 5'h04, 0, 4'h0, 31'h00000000, 0);
    @(posedge clk);
    set_input(1, 6'h05, 6'h06, 5'h05, 1, 4'h0, 31'h00000001, 0);
    @(posedge clk);
    set_input(1, 6'h06, 6'h07, 5'h06, 0, 4'h1, 31'h00000001, 0);
    @(posedge clk);
    repeat (14) begin
    set_input(1, 6'h05, 6'h06, 5'h05, 0, 4'h0, 31'h00000001, 0);
    @(posedge clk);
    end
    set_input(0, 6'h05, 6'h06, 5'h05, 1, 4'h1, 31'h00000001, 0);
    @(posedge clk);
    set_input(0, 6'h05, 6'h06, 5'h05, 1, 4'h2, 31'h00000001, 0);
    @(posedge clk);
     set_input(1, 6'h07, 6'h08, 5'h07, 1, 4'hb, 31'h00000345, 1);
    @(posedge clk);
    repeat (10) begin
        set_input(1, 6'h08, 6'h09, 5'h08, 0, 4'h0, 31'h00000000, 0);
        @(posedge clk);
    end
    $stop;
end

always 
#5 clk = ~clk;

task set_input(input isDis, input [5:0] pr_old_DP, input [5:0] pr_new_DP, input [4:0] rd, 
               input compl, input [3:0] rob_num, input [31:0] da, input changeF);
    begin
    isDispatch = isDis; PR_old_DP = pr_old_DP; PR_new_DP = pr_new_DP; rd_DP = rd; 
    complete = compl; rob_number = rob_num; jb_addr = da; changeFlow = changeF;
    end
endtask

endmodule
