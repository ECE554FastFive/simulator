//dispatch: read p_rs, p_rt, write new p_rd and reset this valid bit, read p_old, use p_rs, p_rt, p_rd_old to index valid array getting valid bit
//complete: set valid bit of the completed physical register number
//recovery: inedxed by recover_rd, if RegDest_ROB = 1, write the p_rd_flush to that entry, and restore the valid bit
module map_table(
    output [5:0] p_rs, p_rt,
    output p_rs_v, p_rt_v,
    output [5:0] PR_old_rd,
    
    input clk, rst,
    
    input hazard_stall, //from hazard detection logic
    
    //from dispatch stage
    input isDispatch,
    input [4:0] l_rs, l_rt, l_rd,
    input RegDest,
    input [5:0] p_rd_new,

    //from recovery
    input [4:0] recover_rd,
    input [5:0] p_rd_flush,
    input recover,
    input RegDest_ROB,
    
    //from complete stage
    input [5:0] p_rd_compl,
    input complete,
    input RegDest_compl  
);

reg [5:0] mt [0:31];
reg [63:0] PR_valid;  //logically separate with map table

/////////////////////////////////writing/reading map table////////////////////////////
wire write_new_rd;
integer i;

assign write_new_rd = isDispatch && RegDest && !hazard_stall && !recover;

always @(posedge clk or negedge rst) begin
    if (!rst) begin                             //initial begin
        for (i = 0; i < 32; i = i + 1) begin
            mt[i] <= i;
        end
    end
    else if (write_new_rd)
        mt[l_rd] <= p_rd_new;
    else if (RegDest_ROB && recover) 
        mt[recover_rd] <= p_rd_flush;     
end

assign p_rs = mt[l_rs];
assign p_rt = mt[l_rt];
assign PR_old_rd = mt[l_rd];  
/////////////////////////////valid array/////////////////////////////////

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        PR_valid <= 64'hFFFFFFFFFFFFFFFF;
    end
    else begin
        if (write_new_rd)
            PR_valid[p_rd_new] <= 1'b0;  
        if (complete && RegDest_compl)  //it should be ok during recovery because if complete is 1, the valid will be set to 1 several times, finally it will
            PR_valid[p_rd_compl] <= 1'b1; //be 1
   end
end

assign p_rs_v = PR_valid[p_rs];
assign p_rt_v = PR_valid[p_rt];     

endmodule
