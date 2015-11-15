module store_queue_tb();
 
reg clk;
reg rst;
//////////////from load-store station
reg issue;
reg mem_wen;
reg mem_ren;
reg [15:0] immed;
reg [3:0] rob_in;
reg [5:0] p_rd_in;
////////from physical register file
reg [31:0] rs_data;
reg [31:0] rt_data;
////stall hazard
reg stall_hazard;

//from the ROB, retire
reg retire_ST;
reg [3:0] retire_rob;
//from the ROB, recovery
reg recover;
reg [3:0] rec_rob;

wire sq_full;
////////////to complete stage, arbiter
wire isLS;
wire [31:0] load_result;
wire [5:0] ls_p_rd;
wire [3:0] ls_rob;
wire ls_RegDest;
   
store_queue i_store_queue(
                          .clk(clk),
                          .rst(rst),
                          .issue(issue),
                          .mem_wen(mem_wen),
                          .mem_ren(mem_ren),
                          .rs_data(rs_data),
                          .rt_data(rt_data),
                          .immed(immed),
                          .rob_in(rob_in),
                          .p_rd_in(p_rd_in),
                          .stall_hazard(stall_hazard),
                          .retire_ST(retire_ST),
                          .retire_rob(retire_rob),
                          .recover(recover),
                          .rec_rob(rec_rob),
                          .sq_full(sq_full),
                          .isLS(isLS),
                          .load_result(load_result),
                          .ls_p_rd(ls_p_rd),
                          .ls_rob(ls_rob),
                          .ls_RegDest(ls_RegDest));

initial begin
    clk = 0;
    rst = 0;
    ////////////////at first reset all things
    set_lss_pr(0, 0, 0, 16'h0000, 4'h0, 6'h00, 32'h00000000, 32'h00000000);
    set_rob(0, 4'h0, 0, 4'h0);
    stall_hazard = 0;
    #2 rst = 1;

    //////******************Issuing *store* into store queue***************///////////////////
    @(negedge clk);
    //first store goes into store-queue, from ROB #2, store into 0001
    set_lss_pr(1, 0, 1, 16'h0001, 4'h2, 6'h00, 32'h00000000, 32'h00001234);
    /*assert (i_lss.tail == 4'b0001 &&
            i_lss.head == 4'b0001 &&
            i_lss.lss_valid[0] == 1'b0
           ) $display("Ok, success dispatch %0d!", assert_idx++);
        else $error("not successful");*/
    @(negedge clk);
    //second store goes into store-queue, from ROB #3, store into 0002
    set_lss_pr(1, 0, 1, 16'h0002, 4'h3, 6'h00, 32'h00000000, 32'h00002345);
    @(negedge clk);
    //third store goes into store-queue, from ROB #4, store into 0003 
    set_lss_pr(1, 0, 1, 16'h0003, 4'h4, 6'h00, 32'h00000000, 32'h00004567);
    @(negedge clk);
    //fourth store goes into store-queue, from ROB #5, store into 0004 
    set_lss_pr(1, 0, 1, 16'h0004, 4'h5, 6'h00, 32'h00000000, 32'h00005678);
    @(negedge clk);
    //fifth store from ROB #6, store into 0005 , however since SQ is full, this one won't be written
    set_lss_pr(1, 0, 1, 16'h0005, 4'h6, 6'h00, 32'h00000000, 32'h00007890);
    @(negedge clk);
    assert(sq_full == 1 &&              //should be full since 4 stores has been written to SQ
           i_store_queue.head == 4'b0001 &&   //no store issued, since no store is ready
           i_store_queue.tail == 4'b0001 
          ) $display("Ok, success full status check!");
        else $error("not success full status check");
    //////******************End of Issuing *store* into store queue***************///////////////////

    ///////*****************Now some "stores" will retire, will store data into memory******/////////
    set_lss_pr(0, 0, 0, 16'h0000, 4'h0, 6'h00, 32'h00000000, 32'h00000000);
    ///store in ROB#2 retires
    set_rob(1, 4'h2, 0, 4'h0);
    @(negedge clk);
    assert(i_store_queue.control_queue[0][2] == 1   //ready bit set
          ) $display("Ok, success set ready check!");
        else $error("not successful set ready check");
    //store in ROB#3 retires
    set_rob(1, 4'h3, 0, 4'h0);
    @(negedge clk);
     assert(i_store_queue.control_queue[1][2] == 1 && //ready bit set
            i_store_queue.head == 4'b0010
          ) $display("Ok, success set ready check!");
        else $error("not successful set ready check");

    ////*********Now load issued, in the same time store retires, however load should go first////////
    //load from address 0001, should from memory not forwarding, load to register 01
    set_lss_pr(1, 1, 0, 16'h0001, 4'h0, 6'h01, 32'h00000000, 32'h0000FFFF);
    set_rob(1, 4'h4, 0, 4'h0);
    @(negedge clk);
    assert(i_store_queue.mem_ren_out == 1 &&  //load goes first
           i_store_queue.mem_wen_out == 0 &&  //store wait
           i_store_queue.head == 4'b0010     //head not moved
          ) $display("Ok, success load store ordering check!");
        else $error("not successful load store ordering check");
    //load from address 0003, should be forward from store queue entry [3]
    set_lss_pr(1, 1, 0, 16'h0003, 4'h0, 6'h02, 32'h00000000, 32'h0000FFFF);
    set_rob(1, 4'h5, 0, 4'h0);
    @(negedge clk);
    assert(i_store_queue.fwd_data_int == 32'h00004567 && //get right forward data
           i_store_queue.isFwd == 1'b1    //select forwarding data
          ) $display("Ok, success forwarding check!");
        else $error("not successful forwarding check");
    ////////********Now, continue to issue ready stores*******////////////
    //no more memory instructions, no more retire stores
    set_lss_pr(0, 0, 0, 16'h0000, 4'h0, 6'h00, 32'h00000000, 32'h00000000);
    set_rob(0, 4'h0, 0, 4'h0);
    repeat (3) @(negedge clk);
    $stop;
end

always 
#5 clk = ~clk;

task set_lss_pr(input is, input mr, input mw, input [15:0] im, input [3:0] rob, input [5:0] rd,
                input [31:0] rs_d, input [31:0] rt_d);
begin
      issue = is; mem_ren = mr; mem_wen = mw; immed = im; rob_in = rob; p_rd_in = rd;
      rs_data = rs_d; rt_data = rt_d;  
end
endtask

/////when recover is 1, although rt_st, rt_rob can be any value, it doesn't matter because 
////ROB will stop retiring new instructions if the recover is high, need to check ROB for this
task set_rob(input rt_st, input [3:0] rt_rob, input rec, input [3:0] recover_rob);
begin
      retire_ST = rt_st; retire_rob = rt_rob;
      recover = rec; rec_rob = recover_rob;
end
endtask
endmodule
