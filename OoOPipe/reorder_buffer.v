//re-order buffer did three things
//In dispatch, unless ROB is full, allocate new ROB entry for incoming instruction at tail, increase the tail
  //during the recovery time (when dec_tail|recover is 1), the ROB will not allocate new entry for instructions in dispatch stage
//In complete, if the completed instruction is not a branch. The ROB entry indexed by rob_number will be marked as complete.
  //if it is a branch misprediction or jump, stall all things (flush IF/DP) in the first cycle (when stall_recover is high), 
  //decrease the tail by 1 (since the tail points to next allocated instr, cannot recover from tail entry). Then, 
  //assert the recover signal, all data(PR_old, PR_new, rd) are ready, during the time recover is high, flush RS entry (ROB# match),
  //flush MT, FL, LSQ (all for ROB# match), flush IS/EX(if ROB# match), EX/CMP(ROB# match). If ROB# doesn't match, stall that block.
  //after recover becomes low, the changeFlow_out becomes 1 for 1 cycle, thus PC changes to correct PC, changeFlow also flush the IF/DP
   //when recover is low, other parts are allowed to go (MT,RS,FL will not allocate since the IF/DP is NOP, however some instructions
   //might still in IS/EX or EX/CMP, let them go
module reorder_buffer(
    input rst, clk,
    input isDispatch, //serve as the write enable of FIFO
    input MemOp,   //
    input RegDest,    //stored for roll back, if it is 1, MT and FL need to be restored
    input [5:0] PR_old_DP, //from map table, the previous PR#
    input [5:0] PR_new_DP,
    input [4:0] rd_DP, //architectural destinatioMn register
    input PR_old_valid,

    input complete,    //from complete stage, if there is intruction completes
    input [3:0] rob_number,  //from the complete stage, used to set complete bit
    input [31:0] jb_addr,    //from complete stage
    input changeFlow,   //asserted if branch-misprediction or jump, from complete, start the state machine

    input hazard_stall,   //stall because of structure hazard, won't allocate new entry

    output [5:0] PR_old_RT,  //PR_old to be retired
    output retire_reg,  //read enable signal of FIFO
    output retire_LWST,
    output [3:0] retire_rob,   //for load/store queue, indicate which ROB entry is retired
    output full, empty,   

    output RegDest_out,
    output [5:0] PR_old_flush,
    output old_valid_out,
    output [5:0] PR_new_flush,
    output [4:0] rd_flush,
    output [3:0] out_rob_num,  //for recovery, provide the current ROB number for FL, MT, RS
    output reg changeFlow_out,   //asserted for one cycle after all recovery works done
    output reg [31:0] changeFlow_addr,
    output reg recover,          //recover signal, inform RS, MT, FL, LSQ, IS/EX, EX/CMP to flush(ROB# match) or stall (ROB# not match)
    output reg stall_recover  //before the recover, pointer= tail, stall the pipeline
);

reg [19:0] rob [15:0];  //[19]: RegDest, (whether bet PR back to MT and FL)[18]: PR_old_valid, [17]: MemOp, [16:12]rd, [11:6] t_old, [5:0] t_new
reg [15:0] complete_array;



/////////////////////////////////////////////Synch FIFO structure///////////////////////////////////////////
reg [3:0] head, tail;
reg dec_tail;  //for recovery
reg [19:0] retire_entry; 

wire read, write;
//no read or write of ROB during recovery
assign write = isDispatch && !full && !recover && !hazard_stall;
assign read = retire_reg && !empty && !recover && !stall_recover && !hazard_stall;
//head logic
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        head <= 4'h0;
        retire_entry <= 0;
    end
    else if (read) begin
        head <= head + 1;
        retire_entry <= rob[head];
    end
end

assign retire_reg = complete_array[head];   //if the head is complete, retire it
assign PR_old_RT = retire_entry[11:6];      //the PR returned to free list
assign retire_LWST = retire_entry[17];       //tell LSQ now a load/store is retired
assign retire_rob = head;

//tail logic
always @(posedge clk or negedge rst) begin
    if (!rst)
        tail <= 4'h0;
    else if (dec_tail)
        tail <= tail - 1;   //when decreasing tail, the ROB will not accept new instructions
    else if (write) begin
        tail <= tail + 1;
        rob[tail] <= {RegDest, PR_old_valid, MemOp, rd_DP, PR_old_DP, PR_new_DP};
        complete_array[tail] <= 0;   //reset complete bit when allocate a new entry
    end
end

//Synch FIFO counter
reg [4:0] status_cnt;
always @(posedge clk or negedge rst) begin
    if (!rst) 
        status_cnt <= 4'h0;
    else if (write && !read)   //write but not read
        status_cnt <= status_cnt + 1;
    else if (read && !write)  //read but not write
        status_cnt <= status_cnt - 1;
    else if (dec_tail)
        status_cnt <= status_cnt - 1;
end

assign full = status_cnt[4];  //if counter = 16, the FIFO is full
assign empty = ~(|status_cnt);

///////////////////////////////////////////////////end of synch FIFO///////////////////////////////////////////////////


//////////////////////////////complete part////////////////////////////////////

reg [3:0] branch_rob;
reg store_jb_addr;
always @(posedge clk or negedge rst) begin
    if (!rst) 
        complete_array <= 0;
    else if (complete) 
        complete_array[rob_number] <= 1'b1;    //ROB# cannot equal to tail, will this synthesize?
end

//changeFlow address and ROB number for branch/jump
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        changeFlow_addr <= 0;
        branch_rob <= 0;
    end
    else if (store_jb_addr) begin
        changeFlow_addr <= jb_addr;
        branch_rob <= rob_number;   //store the ROB# of branch when here comes a branch
    end
end
//////////////////////////////end of complete part/////////////////////////////////////

assign out_rob_num = tail;  //may need to store ROB number in RS, when completing instructions can index the ROB to set
                            //during recovery, this number is also used for indexing the flush entry
localparam IDLE = 2'b00;
localparam REC = 2'b01;
localparam CF = 2'b10;

reg [1:0] state, nstate;

always @(posedge clk or negedge rst) begin
    if (!rst) 
        state <= IDLE;
    else
        state <= nstate;
end

wire recover_end = (branch_rob + 1 == tail);
always @(*) begin
    nstate = IDLE;
    stall_recover = 0;
    dec_tail = 0;
    recover = 0;
    store_jb_addr = 0;
    changeFlow_out = 0;

    case (state) 
     IDLE: begin
         if(complete && changeFlow) begin
             nstate = REC;
             stall_recover = 1;
             dec_tail = 1;
             store_jb_addr = 1;
         end
         else
             nstate = IDLE;
     end
     REC: begin
         if(recover_end) begin
            nstate = CF;
            recover = 1;
         end
         else begin
            nstate = REC;
            dec_tail = 1;
            recover = 1;
         end
     end
     default: begin   //CF
         nstate = IDLE;
         changeFlow_out = 1;
     end
    endcase
end

//[16:12]rd, [11:6] t_old, [5:0] t_new
assign rd_flush = rob[tail][16:12];
assign PR_old_flush = rob[tail][11:6];
assign PR_new_flush = rob[tail][5:0];
assign old_valid_out = rob[tail][18];
assign RegDest_out = rob[tail][19];
//out_rob_tail assigned before, since it is used both in recovery and normal dispatch
endmodule
