module free_list_tb();

reg [5:0] p_rd_old;
reg retire_reg;
reg reg_wen;
reg stall_recover;
reg recover;
reg [5:0] PR_new_flush;
reg clk;
reg rst;
logic [5:0] p_rd_new;
logic empty;


free_list_new i_free_list(
                      .p_rd_old(p_rd_old),
                      .retire_reg(retire_reg),
                      .reg_wen(reg_wen),
                      .clk(clk),
                      .rst(rst),
                      .stall_recover(stall_recover),
                      .recover(recover),
                      .PR_new_flush(PR_new_flush),
                      .p_rd_new(p_rd_new),
                      .empty(empty));
initial begin
    clk = 0;
    rst = 0;
    stall_recover = 0;
    recover = 0;
    PR_new_flush = 6'h24;
    #2 rst = 1;
    @(posedge clk) retire_reg = 1;
                   p_rd_old = 31;
                   reg_wen = 1;
    repeat (5) @(posedge clk);
    reg_wen = 0;
    repeat (5) @(posedge clk);
    retire_reg = 0;
    reg_wen = 1;
    repeat (5) @(posedge clk);
    stall_recover = 1;
    @(posedge clk);
    stall_recover = 0;
    recover = 1;
    repeat (4) @(posedge clk);
    $stop;
end

always 
 #5 clk = ~clk;

endmodule
