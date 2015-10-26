module reorder_buffer_tb();

reg rst;
reg clk;
reg isDispatch;
reg [5:0] PR_old_DP;
reg [5:0] PR_new_DP;
reg [4:0] rd_DP;
reg complete;
reg [3:0] rob_number;
reg [31:0] data;
reg changeFlow;
wire [5:0] PR_old_RT;
wire retire_reg;
wire [5:0] PR_new_flush;
wire rd_flush;
wire [3:0] out_rob_num;
wire changeFlow_out;
wire [31:0] changeFlow_addr;
wire full;
wire empty;

reorder_buffer i_reorder_buffer(
                                .rst(rst),
                                .clk(clk),
                                .isDispatch(isDispatch),
                                .PR_old_DP(PR_old_DP),
                                .PR_new_DP(PR_new_DP),
                                .rd_DP(rd_DP),
                                .complete(complete),
                                .rob_number(rob_number),
                                .data(data),
                                .changeFlow(changeFlow),
                                .PR_old_RT(PR_old_RT),
                                .retire_reg(retire_reg),
                                .PR_new_flush(PR_new_flush),
                                .rd_flush(rd_flush),
                                .out_rob_num(out_rob_num),
                                .changeFlow_out(changeFlow_out),
                                .changeFlow_addr(changeFlow_addr),
                                .full(full),
                                .empty(empty));

reg [4:0] rob_n;
initial begin
    clk = 0;
    rst = 0;
    #2 rst = 1;
    set_input(1, 6'h00, 6'h01, 5'h00, 0, 4'h0, 31'h00000000, 0);
    @(posedge clk);
    set_input(1, 6'h01, 6'h02, 5'h01, 0, 4'h0, 31'h00000000, 0);
    @(posedge clk);
    set_input(1, 6'h02, 6'h03, 5'h00, 0, 4'h2, 31'h00000000, 0);
    @(posedge clk);
    set_input(1, 6'h03, 6'h04, 5'h03, 1, 4'h1, 31'h00000001, 0);
    @(posedge clk);
    PR_old_DP = 6'h04; PR_new_DP = 6'h05; rd_DP = 5'h04; complete = 1; rob_number = 4'h0; data = 32'h00000002;
    @(posedge clk);
    PR_old_DP = 6'h05; PR_new_DP = 6'h06; rd_DP = 5'h05; complete = 1; rob_number = 4'h2; data = 32'h00000003;
    @(posedge clk);
    PR_old_DP = 6'h06; PR_new_DP = 6'h07; rd_DP = 5'h06; complete = 1; rob_number = 4'h3; data = 32'h00000004;
    @(posedge clk); 
    repeat (15)
    begin
        PR_old_DP = 6'h07; PR_new_DP = 6'h08; rd_DP = 5'h07; complete = 0; rob_number = 4'h3; data = 32'h00000004;
        @(posedge clk); 
    end 
    //will be full until this point
    set_input(0, 6'h03, 6'h04, 5'h03, 1, 4'h6, 31'h00000001, 0);
    @(posedge clk);
    set_input(0, 6'h03, 6'h04, 5'h03, 1, 4'h5, 31'h00000001, 0);
    @(posedge clk);
    set_input(0, 6'h03, 6'h04, 5'h03, 1, 4'h4, 31'h00000001, 0);
    @(posedge clk);
    for(rob_n = 5'h07; rob_n < 16; rob_n = rob_n + 1) 
    begin
        set_input(0, 6'h03, 6'h04, 5'h03, 1, rob_n, 31'h00000001, 0);
        @(posedge clk);
    end 
    set_input(0, 6'h03, 6'h04, 5'h03, 1, 4'h3, 31'h00000001, 0);
    @(posedge clk);
    set_input(0, 6'h03, 6'h04, 5'h03, 1, 4'h2, 31'h00000001, 0);
    @(posedge clk);
    set_input(0, 6'h03, 6'h04, 5'h03, 1, 4'h1, 31'h00000001, 0);
    @(posedge clk);
    set_input(0, 6'h03, 6'h04, 5'h03, 1, 4'h0, 31'h00000001, 0);
    repeat (6) @(posedge clk);
    //will be empty again
    $stop;
end

always
 #5 clk = ~clk;

task set_input(input isDis, input [5:0] pr_old_DP, input [5:0] pr_new_DP, input [4:0] rd, 
               input compl, input [3:0] rob_num, input [31:0] da, input changeF);
    begin
    isDispatch = isDis; PR_old_DP = pr_old_DP; PR_new_DP = pr_new_DP; rd_DP = rd; 
    complete = compl; rob_number = rob_num; data = da; changeFlow = changeF;
    end
endtask

endmodule
