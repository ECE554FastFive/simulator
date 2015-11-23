//load_store station is for load-store instruction, they will be issued in order
//dispatch: p_rs, p_rt, immed, p_rd, some control signals
//issue: if the head is ready, issue it
//complete: receive <PR_rd#, RegDest_compl> from CDB, set the valid bit
module ls_station(
     input clk, rst,
     
     //from dispatch stage
     input isDispatch,
     input [3:0] rob_num_dp,
     input [5:0] p_rd_new,            //this rd from decode stage, it is actually rt for load
     input [5:0] p_rs,
     input read_rs,                    //asserted if rs is read
     input v_rs,                       //this input is from map table, if rs is not used, set this to 1
     input [5:0] p_rt,
     input read_rt,
     input v_rt,	 
     input mem_ren, mem_wen,  //enable signal for LSQ can be generated from these two signals
     input [15:0] immed,

     input stall_hazard,
     input stall_issue,

     //from branch/jump recovery
     input recover,
     input [3:0] rob_num_rec,             //flush the instruction that has ROB match

     //from complete stage
     input [5:0] p_rd_compl,              //set the complete bit if register p_rd_compl match rs or rt
     input RegDest_compl,
     input complete,

     output [5:0] p_rs_out, p_rt_out,
     output [5:0] p_rd_out,   //part of the result
     output [15:0] immed_out,
     output [3:0] rob_num_out,
     output RegDest_out,       //for load instruction, write register, if mem_ren is 1, this must be 1, part of result
     output mem_ren_out,       //for load instruction, read memory
     output mem_wen_out,        //for store instruction, write memory
     output issue,              //asserted if an instruction issued

     output lss_full
);
    
//[41]: isLW, [40]: isST, [39:36]:rob_num, [35:30] p_rd, [29:24]: p_rs, [23]:v_rs
//[22:17]: p_rt, [16] v_rt, [15:0] immed,
reg [41:0] ls_station [0:3]; 
reg [3:0] lss_valid;          //valid array for the lss, initialized to 0, when allocate set to 1, deallocated set to 0

reg [2:0] counter; 
reg [3:0] head, tail; 
reg [1:0] head_addr; 

wire read, write;
wire head_rdy;    //the head is ready to be issued
assign write = isDispatch && !stall_hazard && !lss_full && !recover && (mem_ren || mem_wen);
assign read = !stall_hazard && !recover && head_rdy && lss_valid[head_addr] && !stall_issue;   //stall_hazard from outside, asserted if other blocks have hazard

//counter recording full or empty status
always @(posedge clk or negedge rst) begin
    if (!rst) 
        counter <= 3'b000;           
    else if (write && read)
        counter <= counter;
    else if (write)      
        counter <= counter + 1;
    else if (read)
        counter <= counter - 1;
end

assign lss_full = (counter == 3'b100);

//increase head when read, increase tail when write
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        head <= 4'b0001;
        head_addr <= 2'b00;           
        tail <= 4'b0001;  
    end
    else begin
        if (write) begin     
            tail <= {tail[2:0], tail[3]};
		end
        if (read) begin
            head <= {head[2:0], head[3]};
            head_addr <= head_addr + 1;
        end			
   end
end

///////////////////////////////////combinational logic///////////////////////////////////////////////////
wire [3:0] rob_match_array;   //[2] ismatch [1:0] addr
wire [3:0] rs_match_array, rt_match_array;
//comparator array for flushing instruction
genvar j;
generate 
for (j = 0; j < 4; j = j + 1) begin : combinational
    assign rob_match_array[j] = (ls_station[j][39:36] == rob_num_rec) && lss_valid[j];
    assign rs_match_array[j] = (ls_station[j][29:24] == p_rd_compl) && lss_valid[j] && RegDest_compl;
    assign rt_match_array[j] = (ls_station[j][22:17] == p_rd_compl) && lss_valid[j] && RegDest_compl;
end
endgenerate
						 

////////////////////////////////seqnential logic///////////////////////////////////
genvar i;
generate 
    for (i = 0; i < 4; i = i + 1) begin : sequential
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                ls_station[i] <= {42{1'b0}};
                lss_valid[i] <= 1'b0;
            end
            else begin
               if (write && tail[i]) begin //this is ok, because if a entry is tail, valid[i] is 0, head[i] is 0
                   ls_station[i] <= {mem_ren, mem_wen, rob_num_dp, p_rd_new, p_rs, v_rs || (!read_rs),
                                     p_rt, v_rt || (!read_rt), immed};
                   lss_valid[i] <= 1'b1;
               end
               else begin
                   if (recover && rob_match_array[i]) begin    //flush during recovery
                       ls_station[i][41:40] <= 2'b00;
                   end
                   if (complete && rs_match_array[i]) begin   //set rs complete/valid
                       ls_station[i][23] <= 1'b1;
                   end
                   if (complete && rt_match_array[i]) begin
                       ls_station[i][16] <= 1'b1;
                   end
                   if (read && head[i]) begin
                       lss_valid[i] <= 1'b0;
                   end
               end
            end
        end
    end
endgenerate

//////////////////////////////////////issue logic outputs/////////////////////////////////////
assign head_rdy = ls_station[head_addr][23] && ls_station[head_addr][16];
assign p_rs_out = ls_station[head_addr][29:24];
assign p_rt_out = ls_station[head_addr][22:17];
assign p_rd_out = ls_station[head_addr][35:30];
assign immed_out = ls_station[head_addr][15:0];
assign RegDest_out = ls_station[head_addr][41];   //from isLW (mem_ren)
assign mem_ren_out = ls_station[head_addr][41];   //from isLW (mem_ren)
assign mem_wen_out = ls_station[head_addr][40];   //from isSW (mem_wen)
assign rob_num_out = ls_station[head_addr][39:36];
assign issue = read;
endmodule
