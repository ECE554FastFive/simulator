//when there is a mis-prediction or jump, need to restore the PRs allocated for younger instructions
//will consider this later
module free_list_new(
    input [5:0] PR_old,   //the previous physical register that needs to be freed when current instruction retires
    input retire_reg,  //from retire stage, if there is instruction retire at this cycle, assert retire_reg
    input RegDest,     //from D stage, to see if current instruction need to get a new physical register

    input clk, rst,
    input stall_recover,  //stop allocate new dest PR, stop adding new free PR
    input hazard_stall,    //stall for any events such as ROB full, RS full, etc.
    input recover,

    input [5:0] PR_new_flush,   //from ROB, when doing branch recovery
    input RegDest_ROB,    //during roll back, if the instr being flushed has RegDest_ROB = 0, don't add it to free list

    output [5:0] PR_new,  //the assigned register for current instruction in D stage
    output empty    //indicate whether free list is empty.
);

reg [5:0] mem [0:63];
reg [5:0] head, tail;  //read from head, write to tail + 1
wire write, read;

assign write = ((retire_reg && ~stall_recover) || recover) && ~hazard_stall;   //just to make it more readable
assign read = RegDest && ~stall_recover && ~recover && ~empty && ~hazard_stall;  //no need to detect full since the FIFO have 64 entries, will never be full

reg [5:0] counter;
//counter recording full or empty status
always @(posedge clk or negedge rst) begin
    if (!rst) 
        counter <= 6'h20;           //at rst, AR 0-31 mapped to PR 0-31, PR 32-63 are in free list
    else if (write && read)
        counter <= counter;
    else if (write)      
        counter <= counter + 1;
    else if (read)
        counter <= counter - 1;
end

//increase head when read, increase tail when write
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        head <= 6'h00;           //at rst, AR 0-31 mapped to PR 0-31, PR 32-63 are in free list
        tail <= 6'h20;           //next write will write to mem[tail]
    end
    else begin
        if ((write && recover && RegDest_ROB) || (write && !recover))      
            tail <= tail + 1;
        if (read)
            head <= head + 1;   
   end
end

//initialization of free list and write to free list in retire stage
integer i;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                mem[i] <= i + 32;
            end
            for (i = 32; i < 63; i = i + 1) begin
                mem[i] <= 0;
            end
    end
    else if (write && recover && RegDest_ROB) 
        mem[tail] <= PR_new_flush;
    else if (write && !recover) 
        mem[tail] <= PR_old;
end

assign PR_new = mem[head];
assign empty = ~(|counter);  //when counter counts to 0, the list is empty
endmodule