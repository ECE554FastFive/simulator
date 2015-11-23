//issue stage: if the instruction is a store, store in the head 
//execute: if the instruction is a load, check if there's store in the store queue that has address match, if yes forwarding
//store will complete in the same stage as the load and other instructions to make the ROB design easier
//if a load and a store in the same time, load goes first, head store goes in next cycle
//retire: set the store queue entry ready bit using ROB# to match
module store_queue(
    input clk, rst,
    input issue, mem_wen,
    input mem_ren,   //this is a load, don't release a store at this cycle, since d-mem is single port
    input [31:0] rs_data,    //used to calculating load/store address
    input [31:0] rt_data,   //data for store

    //from the load-store station
    input [15:0] immed,
    input [3:0] rob_in, 
    input [5:0] p_rd_in,

    input stall_hazard,

    //from ROB, for retire stage, set the ready bit in 
    input retire_ST,
    input [3:0] retire_rob,
    
    input recover,
    input [3:0] rec_rob,

    output sq_full,

    //////////////these five signals go to the arbiter, 
    output reg isLS,
    output [31:0] load_result,
    output reg [5:0] ls_p_rd,
    output reg [3:0] ls_rob,
    output reg ls_RegDest
    
    //this signal is the write enable signal for store queue, it indicates the complete of the store instruction
      
);


///////////////***************************store queue logic********************************//////////////////////
reg [3:0] head, tail; 
reg [1:0] head_addr; 
reg [2:0] counter;  

wire read, write;
wire head_retired;
//issue head store to data memory when the head is ready, and no load executed
assign read = !stall_hazard && !recover && head_retired && !mem_ren;  
//get instruction from the reservation station if it is a store and it is issued  
assign write = issue && mem_wen && !stall_hazard && !recover && !sq_full;   

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

assign sq_full = (counter == 3'b100);

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


reg [31:0] value_queue [0:3];  
reg [15:0] addr_queue [0:3]; 
reg [3:0] rob_queue [0:3];
reg [2:0] control_queue [0:3]; //[0]:valid, [1]:mem_wen [2]: ready 
//reg [1:0] priority_queue [0:3];  //recoding priority, deciding which store is the youngest

////////////////////////memory address generator
wire [31:0] address_in;
assign address_in = rs_data + {{16{immed[15]}}, immed};

/////////////////combinational logic, comparators////////////////////////////
wire [3:0] rt_rob_match_array, rec_rob_match_array, addr_match_array;
genvar i;
generate for(i = 0; i < 4; i = i + 1) begin : combinational
    //for retire stage, set the ready bit 
    assign rt_rob_match_array[i] = (rob_queue[i] == retire_rob) && retire_ST && control_queue[i][0] && control_queue[i][1];
    //for recovery, flush the entry if rob number matches, and recover is high
    assign rec_rob_match_array[i] = (rob_queue[i] == rec_rob) && recover && control_queue[i][0] && control_queue[i][1];
    //for incoming load instruction, address match when valid, mem_ren is 1,
    assign addr_match_array[i] = (addr_queue[i] == address_in[15:0]) && control_queue[i][0] && control_queue[i][1] && mem_ren; 
end
endgenerate

////////////////////////sequential logic/////////////////////////////////////////
genvar j;
generate for (j = 0; j < 4; j = j + 1) begin : sequential
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            value_queue[j] <= 0;
            addr_queue[j] <= 0;
            rob_queue[j] <= 0;
            control_queue[j] <= 0;
        end
        else if (write && tail[j]) begin   //this is the tail, match cannot happen on tail, 
            value_queue[j] <= rt_data;
            addr_queue[j] <= address_in[15:0]; //the memory will only use 16 bit memory address
            rob_queue[j] <= rob_in;
            control_queue[j] <= {1'b0, mem_wen, 1'b1};
        end else begin
            if (rt_rob_match_array[j]) begin        //set ready bit
                control_queue[j][2] <= 1'b1;
            end
            if (rec_rob_match_array[j]) begin       //flush this entry
                control_queue[j][1] <= 1'b0;   //only need to flush mem_wen, thus it cannot write to D-Mem, and cannot
            end                                //match with incoming load, retired rob
            if (read && head[j]) begin
                control_queue[j][0] <= 1'b0;          //set to invalid
            end
        end
    end
end
endgenerate

assign head_retired = control_queue[head_addr][2] && control_queue[head_addr][0];
///////////////***************************end of store queue logic********************************//////////////////////

//////////////////////////////////////////data memory and load forwarding logic/////////////////////////
//////////////signals from store queue (load instruction will also use this address) to the memory
wire [31:0] store_data;
wire [15:0] mem_addr;            //can be store addr or load addr
wire mem_wen_out;

wire mem_ren_out;
wire [31:0] load_data_from_mem;
wire [31:0] fwd_data_int;
wire isFwd;

assign store_data = value_queue[head_addr];
assign mem_addr = mem_ren_out ? address_in : addr_queue[head_addr];
assign mem_wen_out = (& control_queue[head_addr]) && !mem_ren;
assign mem_ren_out = mem_ren && issue;
////////////this may lead to errors if one stores to same address twice within 4 stores
assign fwd_data_int = addr_match_array[0] ? value_queue[0] :
                      addr_match_array[1] ? value_queue[1] :
                      addr_match_array[2] ? value_queue[2] :
                      addr_match_array[3] ? value_queue[3] : 32'h00000000;
assign isFwd = |addr_match_array;    //if any of the entry matches, forwarding the data to load
/////////////////////////////data memory, data available at next clock edge////////////////////
data_mem i_data_mem(.clk(clk), .en(mem_ren_out), .we(mem_wen_out), .wdata(store_data), .addr(mem_addr[13:0]), .rdata(load_data_from_mem));

reg isFwd_reg;
reg [31:0] fwd_data_reg;     
//////delay forwarding data by 1 cycle, because the load data from another path(memory) has 1 cycle delay
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        fwd_data_reg <= 0;
        isFwd_reg <= 0;
        isLS <= 0;
        ls_p_rd <= 0;
        ls_rob <= 0;
        ls_RegDest <= 0;
    end
    else begin
        fwd_data_reg <= fwd_data_int;
        isFwd_reg <= isFwd;
        isLS <= mem_ren_out | write;
        ls_p_rd <= p_rd_in;
        ls_rob <= rob_in;
        ls_RegDest <= mem_ren && issue;
    end
end

assign load_result = isFwd_reg ? fwd_data_reg : load_data_from_mem;

endmodule
