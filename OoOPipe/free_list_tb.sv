module free_list_tb();

//signals from retire stage
reg [5:0] PR_old;
reg RegDest_retire;
reg retire_reg;

//from dispatch stage
reg RegDest;

reg clk, rst;

//from branch/jump recovery
reg recover;
reg [5:0] PR_new_flush;
reg RegDest_ROB;

//global stall signal
reg hazard_stall;

logic [5:0] PR_new;
logic empty;

free_list_new i_free_list_new(
                              .PR_old(PR_old),
                              .RegDest_retire(RegDest_retire),
                              .retire_reg(retire_reg),
                              .RegDest(RegDest),
                              .clk(clk),
                              .rst(rst),
                              .hazard_stall(hazard_stall),
                              .recover(recover),
                              .PR_new_flush(PR_new_flush),
                              .RegDest_ROB(RegDest_ROB),
                              .PR_new(PR_new),
                              .empty(empty));

//testing the dispatch, retire register, flush registers(RegDest)
initial begin
    clk = 0;   
    rst = 0;                  //after reset, $r32 - $r63 are in the free list
    set_dispatch(0);
    set_flush(0, 6'h00, 0 );
    set_retire(6'h00, 0, 0);
    hazard_stall = 0;
    #2 rst = 1;
    @(posedge clk); 
    set_dispatch(1);  //start dispatch
    repeat (2) @(posedge clk);
    set_retire(6'h01, 1, 1);             //mem[32] = 01
    @(posedge clk); 
    set_retire(6'h02, 1, 0);
    @(posedge clk);
    set_flush(0, 6'h03, 1);   //the first cycle of roll back, should not return this PR_new
    set_retire(6'h03, 1, 1);            //mem[33] = 03
    @(posedge clk);
    set_flush(1, 6'h04, 1);          //mem[34] = 04 (flushed)
    set_retire(6'h0c, 1, 1);            
    @(posedge clk);
    set_flush(1, 6'h05, 0);          //RegDest_ROB = 0, no write
    set_retire(6'h0b, 1, 1);            
    @(posedge clk);
    set_flush(1, 6'h09, 1);         //mem[35] = 09 (flushed)
    set_retire(6'h0a, 1, 1);
    @(posedge clk);
    set_flush(0, 6'h00, 4'h0);
    set_retire(6'h06, 1, 1);           //mem[36] = 06 (flushed)
    @(posedge clk); //on this clock edge, the pr 6 should be returned to free list, new one should be dispatched;
    hazard_stall = 1;                 //testing the stall 
    set_retire(6'h07, 1, 1);
    @(posedge clk);
    set_retire(6'h07, 1, 1);
    @(posedge clk);
    hazard_stall = 0;
    set_retire(6'h07, 1, 1);             //mem[37] = 07 (flushed), head = 
    @(posedge clk);
    set_retire(6'h08, 1, 0);
    repeat (2) @(posedge clk);              //head = 07 about to change to 08, tail = 26
    $stop;
end

always 
 #5 clk = ~clk;

task set_dispatch(input reg_dest);
begin
    RegDest = reg_dest;
end
endtask

task set_flush(input rec, input [5:0] pr_flush, input regdst_rob);
begin
    recover = rec;
    PR_new_flush = pr_flush;
    RegDest_ROB = regdst_rob;
end
endtask

task set_retire(input [5:0] pr_old, input rt_reg, input regdst_retire);
begin
    PR_old = pr_old;
    retire_reg = rt_reg;
    RegDest_retire = regdst_retire;
end
endtask

endmodule
