//when there is a mis-prediction or jump, need to restore the PRs allocated for younger instructions
//will consider this later
module free_list_new(
    input [5:0] PR_old,   //the previous physical register that needs to be freed when current instruction retires
    input retire_reg,  //from retire stage, if there is instruction retire at this cycle, assert retire_reg
    input RegDest,     //from D stage, to see if current instruction need to get a new physical register
    input clk, rst,
    input stall_recover,  //stop allocate new dest PR, stop adding new free PR
    input recover,
    input [5:0] PR_new_flush,   //from ROB, when doing branch recovery
    output [5:0] PR_new,  //the assigned register for current instruction in D stage
    output empty    //indicate whether free list is empty.
);

reg [5:0] mem [0:63];
reg [5:0] head, tail;  //read from head, write to tail + 1
wire write, read;

assign write = (retire_reg && ~stall_recover) || recover;   //just to make it more readable
assign read = RegDest && ~stall_recover && ~recover && ~empty;  //no need to detect full since the FIFO have 64 entries, will never be full

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
        if (write)      
            tail <= tail + 1;
        if (read)
            head <= head + 1;   
   end
end

//initialization of free list and write to free list in retire stage
wire [5:0] PR_write;
assign PR_write = recover ? PR_new_flush : PR_old;
/*genvar c;
generate 
   for (c = 0; c < 32; c = c + 1) begin: freelist
    always @(negedge rst) begin
        if (!rst) begin
            mem[c] <= c + 32;   //PR 32-63 are in the free list at beginning
        end
    end
   end
endgenerate*/
integer i;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                mem[i] <= i + 32;
            end
    end
    else if (write) begin
        mem[tail] <= PR_write;
    end
end

/*always @(posedge clk) begin
    if (rst && write) begin    //when rst is high, can write to FIFO
         mem[tail] <= PR_write;
    end
end
*/
assign PR_new = mem[head];
assign empty = ~(|counter);  //when counter counts to 0, the list is empty
endmodule