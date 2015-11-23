
module rs_alu(
	input clk,
	input rst,

	//To IS/EX pipe
	output [31:0] PC_out,
	output [3:0] rob_id_out,	
	output [7:0] EX_ctrl_out, //To IS/EX pipe
	output [5:0] p_rs_out,  //To PRF: Read Operand 1
	output [5:0] p_rt_out,  //To PRF: Read Operand 2
	output [15:0] imm_bits_out,
	output [5:0] p_rd_out,	//To ALU: ALU must store it and use it as CDB.Tag 	
	output stl_dec_rs_alu_full, //To Decode
	
	input [3:0] num_rob_entry, //From Decode stage: ROB tail 
	input [31:0] PC_in, 
	input [7:0] EX_ctrl_in, //From Decode
	//input ALU_busy,	//From EX(ALU)
	input [5:0] p_rs_in, 	//From Map Table	
	input [5:0] p_rt_in, 	//From Map Table
	input p_rs_rdy_in,	//From Map Table, PRF Valid array
	input p_rt_rdy_in,	//From Map Table, PRF Valid array
	input rs_read,
	input rt_read,
	input [15:0] imm_bits_in,
	input [5:0] p_rd_new, 	//From Free List

	input alloc_RS_en, 	//From Decode: rs_alu_en
	input stall_issue,	//From EX stage
	output wire issue_en,	//Indicates if an instruction is issued in a clock cycle
	input recover,			
	input [3:0] rec_rob_entry, //ROB# for instructions to be flushed
	input stall_hazard,
	//CDB interface
	input bus_en,
	input [5:0] tag		//From CDB
	//input [3:0] cdb_rob_id, //From CDB
	//input [31:0] value, 	//From CDB
	
);

	integer i; //Index of all the for-loops
	//Allocation
	reg [3:0] alloc_index; //Points to the first available entry of RS from the index[0]
	wire [2:0] alloc_index_3b;
	//Issue 
	reg [2:0] issue_index; reg [2:0] flush_index;

	//Flip-flop arrays
	reg valid[0:8];
	reg [3:0] rob_id[0:8]; //ROB entry number
	reg [5:0] prf_rs[0:8]; //6-bit PRF addresses
	reg [5:0] prf_rt[0:8]; //6-bit PRF addresses
	reg [5:0] prf_rd[0:8]; //6-bit PRF addresses	
	reg [15:0] imm_bits[0:8]; //immediate bits
	reg [7:0] ex_ctrl[0:8]; 	
	reg [31:0] PC[0:8];  //Program Counter	
	reg prf_rs_rdy[0:8]; //Ready bit: prf_rs
	reg prf_rt_rdy[0:8]; //Ready bit: prf_rt

	//Allocation Index calculation
	always@( posedge clk or negedge rst) begin
		if( ~rst) begin
			alloc_index <= 4'd0;
		end else begin
			if( alloc_index[3] == 1'b1 || stall_hazard == 1'b1) 
				alloc_index <= alloc_index;
			else begin
				if( recover==1'b1)
					alloc_index <= alloc_index - 1;
				else begin
				case( {alloc_RS_en, issue_en})
				2'b00: alloc_index <= alloc_index;
				2'b01: alloc_index <= alloc_index - 1;
				2'b10: alloc_index <= alloc_index + 1;
				2'b11: alloc_index <= alloc_index;	
				endcase
				end
			end
		end
	end

	assign alloc_index_3b = alloc_index[2:0];

	//Flush Index calculation
	always@( recover) begin
	if( recover == 1'b1) begin
		if( valid[0] == 1'b1 && rec_rob_entry == rob_id[0]) flush_index = 3'b000;
		else if( valid[1] == 1'b1 && rec_rob_entry == rob_id[1]) flush_index = 3'b001;
		else if( valid[2] == 1'b1 && rec_rob_entry == rob_id[2]) flush_index = 3'b010;
		else if( valid[3] == 1'b1 && rec_rob_entry == rob_id[3]) flush_index = 3'b011;
		else if( valid[4] == 1'b1 && rec_rob_entry == rob_id[4]) flush_index = 3'b100;
		else if( valid[5] == 1'b1 && rec_rob_entry == rob_id[5]) flush_index = 3'b101;
		else if( valid[6] == 1'b1 && rec_rob_entry == rob_id[6]) flush_index = 3'b110;
		else if( valid[7] == 1'b1 && rec_rob_entry == rob_id[7]) flush_index = 3'b111;
		else flush_index = 3'b000;
	end else flush_index = 3'b000;
	end

////////////////////
// Valid
////////////////////

	always@( posedge clk or negedge rst) begin
			valid[8] <= 1'b0;
			
	   	for( i=0; i<8; i=i+1) begin		
		    if( ~rst) begin
			valid[i] <= 1'b0;
		    end else begin	
			if( recover == 1'b1) begin
				if( i==flush_index || i>flush_index) begin					
					if( i < alloc_index-1 ) valid[i] <= valid[i+1];
					else valid[i] <= 1'b0;
				end else valid[i] <= valid[i];
			end 	
			else if( ((i == issue_index || i > issue_index) && i < alloc_index) && issue_en == 1'b1) begin
				if( i == alloc_index-1 || i==7) begin//Last entry of the Array
					if( alloc_RS_en) valid[i] <= 1'b1;
					else valid[i] <= 1'b0;
				end else
					valid[i] <= valid[i+1];
			end else if( i == alloc_index_3b && alloc_index[3] == 1'b0 && alloc_RS_en == 1'b1 && issue_en == 1'b0)
				valid[i] <= 1'b1;
			else
				valid[i] <= valid[i];
		    end
	   	end //for
	end //always	

///////////////////////
// ROB# 
///////////////////////

	always@( posedge clk or negedge rst) begin
			rob_id[8] <= 4'd0;
	
	   	for( i=0; i<8; i=i+1) begin		
		    if( ~rst) begin
			rob_id[i] <= 4'd0;
		    end else begin	
			if( recover == 1'b1) begin
				if( i == flush_index || i>flush_index) begin
					if( i < alloc_index-1) rob_id[i] <= rob_id[i+1];
					else rob_id[i] <= 4'd0;
				end else rob_id[i] <= rob_id[i];
			end 	
			else if( ((i == issue_index || i > issue_index) && i < alloc_index) && issue_en == 1'b1) begin
				if( i == alloc_index-1 || i==7) //Last entry of the Array
					if( alloc_RS_en) rob_id[i] <= num_rob_entry; //value;
					else rob_id[i] <= 4'd0;
				else
					rob_id[i] <= rob_id[i+1];
			end else if( i == alloc_index_3b && alloc_index[3] == 1'b0 && alloc_RS_en == 1'b1 && issue_en == 1'b0)
				rob_id[i] <= num_rob_entry; //value;
			else
				rob_id[i] <= rob_id[i];
		    end
	   	end //for
	end //always	

///////////////////////
// PRF_RS
///////////////////////

	always@( posedge clk or negedge rst) begin
			prf_rs[8] <= 6'd00; //The 9th and unused 
			
	   	for( i=0; i<8; i=i+1) begin		
		    if( ~rst) begin
			prf_rs[i] <= 6'd0;
		    end else begin	
			if( recover == 1'b1) begin
				if( i == flush_index || i>flush_index) begin
					if( i < alloc_index-1) prf_rs[i] <= prf_rs[i+1];
					else prf_rs[i] <= 6'd0;
				end else prf_rs[i] <= prf_rs[i];
			end 	
			else if( ((i == issue_index || i > issue_index) && i < alloc_index) && issue_en == 1'b1) begin
				if( i == alloc_index-1 || i==7) //Last entry of the Array
					if( alloc_RS_en) prf_rs[i] <= p_rs_in; //value;
					else prf_rs[i] <= 6'd0;
				else
					prf_rs[i] <= prf_rs[i+1];
			end else if( i == alloc_index_3b && alloc_index[3] == 1'b0 && alloc_RS_en == 1'b1 && issue_en == 1'b0)
				prf_rs[i] <= p_rs_in; //value;
			else
				prf_rs[i] <= prf_rs[i];
		    end
	   	end //for
	end //always	

///////////////////////
// PRF_RT
///////////////////////

	always@( posedge clk or negedge rst) begin
			prf_rt[8] <= 6'd00; //The 9th and unused 	
	
	   	for( i=0; i<8; i=i+1) begin		
		    if( ~rst) begin
			prf_rt[i] <= 6'd0;
		    end else begin	
			if( recover == 1'b1) begin
				if( i == flush_index || i>flush_index) begin
					if( i < alloc_index-1) prf_rt[i] <= prf_rt[i+1];
					else prf_rt[i] <= 6'd0;
				end else prf_rt[i] <= prf_rt[i];
			end 	
			else if( ((i == issue_index || i > issue_index) && i < alloc_index) && issue_en == 1'b1) begin
				if( i == alloc_index-1 || i==7) //Last entry of the Array
					if( alloc_RS_en) prf_rt[i] <= p_rt_in; //value;
					else prf_rt[i] <= 6'd0;
				else
					prf_rt[i] <= prf_rt[i+1];
			end else if( i == alloc_index_3b && alloc_index[3] == 1'b0 && alloc_RS_en == 1'b1 && issue_en == 1'b0)
				prf_rt[i] <= p_rt_in; //value;
			else
				prf_rt[i] <= prf_rt[i];
		    end
	   	end //for
	end //always	

///////////////////////
// PRF_RD
///////////////////////

	always@( posedge clk or negedge rst) begin
			prf_rd[8] <= 6'd00; //The 9th and unused	
	
	   	for( i=0; i<8; i=i+1) begin		
		    if( ~rst) begin
			prf_rd[i] <= 4'd0;
		    end else begin	
			if( recover == 1'b1) begin
				if( i == flush_index || i>flush_index) begin
					if( i < alloc_index-1) prf_rd[i] <= prf_rd[i+1];
					else prf_rd[i] <= 4'd0;
				end else prf_rd[i] <= prf_rd[i];
			end 	
			else if( ((i == issue_index || i > issue_index) && i < alloc_index) && issue_en == 1'b1) begin
				if( i == alloc_index-1 || i==7) //Last entry of the Array
					if( alloc_RS_en) prf_rd[i] <= p_rd_new;
					else prf_rd[i] <= 4'd0;
				else
					prf_rd[i] <= prf_rd[i+1];
			end else if( i == alloc_index_3b && alloc_index[3] == 1'b0 && alloc_RS_en == 1'b1 && issue_en == 1'b0)
				prf_rd[i] <= p_rd_new;
			else
				prf_rd[i] <= prf_rd[i];
		    end
	   	end //for
	end //always		

///////////////////////
// IMMEDIATE BITS
///////////////////////

	always@( posedge clk or negedge rst) begin
			imm_bits[8] <= 6'd00; //The 9th and unused	
	
	   	for( i=0; i<8; i=i+1) begin		
		    if( ~rst) begin
			imm_bits[i] <= 4'd0;
		    end else begin	
			if( recover == 1'b1) begin
				if( i == flush_index || i>flush_index) begin
					if( i < alloc_index-1) imm_bits[i] <= imm_bits[i+1];
					else imm_bits[i] <= 4'd0;
				end else imm_bits[i] <= imm_bits[i];
			end 	
			else if( ((i == issue_index || i > issue_index) && i < alloc_index) && issue_en == 1'b1) begin
				if( i == alloc_index-1 || i==7) //Last entry of the Array
					if( alloc_RS_en) imm_bits[i] <= imm_bits_in;
					else imm_bits[i] <= 4'd0;
				else
					imm_bits[i] <= imm_bits[i+1];
			end else if( i == alloc_index_3b && alloc_index[3] == 1'b0 && alloc_RS_en == 1'b1 && issue_en == 1'b0)
				imm_bits[i] <= imm_bits_in;
			else
				imm_bits[i] <= imm_bits[i];
		    end
	   	end //for
	end //always	

///////////////////////
// EX CTRL BITS
///////////////////////

	always@( posedge clk or negedge rst) begin
			ex_ctrl[8] <= 8'd0; //9th and unused
	
	   	for( i=0; i<8; i=i+1) begin		
		    if( ~rst) begin
			ex_ctrl[i] <= 8'd0;
		    end else begin	
			if( recover == 1'b1) begin
				if( i == flush_index || i>flush_index) begin
					if( i < alloc_index-1) ex_ctrl[i] <= ex_ctrl[i+1];
					else ex_ctrl[i] <= 8'd0;
				end else ex_ctrl[i] <= ex_ctrl[i];
			end 	
			else if( ((i == issue_index || i > issue_index) && i < alloc_index) && issue_en == 1'b1) begin
				if( i == alloc_index-1 || i==7) //Last entry of the Array
					if( alloc_RS_en) ex_ctrl[i] <= EX_ctrl_in;
					else ex_ctrl[i] <= 8'd0;
				else
					ex_ctrl[i] <= ex_ctrl[i+1];
			end else if( i == alloc_index_3b && alloc_index[3] == 1'b0 && alloc_RS_en == 1'b1 && issue_en == 1'b0)
				ex_ctrl[i] <= EX_ctrl_in;
			else
				ex_ctrl[i] <= ex_ctrl[i];
		    end
	   	end //for
	end //always	

///////////////////////
// Program Counter 
///////////////////////

	always@( posedge clk or negedge rst) begin
			PC[8] <= 32'd0; //9th and unused
			
	   	for( i=0; i<8; i=i+1) begin		
		    if( ~rst) begin
			PC[i] <= 32'd0;
		    end else begin	
			if( recover == 1'b1) begin
				if( i == flush_index || i>flush_index) begin
					if( i < alloc_index-1) PC[i] <= PC[i+1];
					else PC[i] <= 32'd0;
				end else PC[i] <= PC[i];
			end 	
			else if( ((i == issue_index || i > issue_index) && i < alloc_index) && issue_en == 1'b1) begin
				if( i == alloc_index-1 || i==7) //Last entry of the Array
					if( alloc_RS_en) PC[i] <= PC_in;
					else PC[i] <= 32'd0;
				else
					PC[i] <= PC[i+1];
			end else if( i == alloc_index_3b && alloc_index[3] == 1'b0 && alloc_RS_en == 1'b1 && issue_en == 1'b0)
				PC[i] <= PC_in;
			else
				PC[i] <= PC[i];
		    end
	   	end //for
	end //always	


///////////////////////
// PRF RS READY BIT
///////////////////////

	//Ready bit arrays: prf_rs_rdy[]
	//Allocation: Dispatch
	//Issue and Deallocation: Issue
	//CDB Tag match: Complete

	always@( posedge clk or negedge rst) begin
			prf_rs_rdy[8] <= 1'b0; //The 9th and un-used flip-flop	
	
	   	for( i=0; i<8; i=i+1) begin		
		    if( ~rst) 
			prf_rs_rdy[i] <= 1'b0;	
		    else begin
			if( recover == 1'b1) begin
				if( i == flush_index || i>flush_index) begin
					if( i < alloc_index-1) prf_rs_rdy[i] <= prf_rs_rdy[i+1];
					else prf_rs_rdy[i] <= 1'b0;
				end else prf_rs_rdy[i] <= prf_rs_rdy[i];
			end 
			else if( issue_en == 1'b1) begin	
			    if( i >= issue_index && i < alloc_index) begin
				if( bus_en==1'b1) begin
					if( i != alloc_index-1) begin
						if( tag == prf_rs[i+1]) prf_rs_rdy[i] <= 1'b1; //CDB Tag Match
						else prf_rs_rdy[i] <= prf_rs_rdy[i+1]; //Shifting up		
					end else begin
						if( alloc_RS_en==1'b1) begin
							if( tag == p_rs_in) prf_rs_rdy[i] <= 1'b1; //Forwarding
							else prf_rs_rdy[i] <= p_rs_rdy_in | (~rs_read);
						end else	
							prf_rs_rdy[i] <= 1'b0;
					end
				end else begin
					if( i != alloc_index-1)
						prf_rs_rdy[i] <= prf_rs_rdy[i+1]; //Shifting up		
					else begin
						if( alloc_RS_en==1'b1) prf_rs_rdy[i] <= p_rs_rdy_in | (~rs_read); //Allocation
						else prf_rs_rdy[i] <= 1'b0;
					end
				end
			    end else if( i < issue_index) begin
				//if(i==alloc_index-1 && alloc_RS_en==1'b1) prf_rs_rdy[i] <= //Not possible: alloc_index IS ALWAYS GREATER THAN issue_index
				if(bus_en==1'b1 && tag == prf_rs[i]) prf_rs_rdy[i] <= 1'b1;
				else prf_rs_rdy[i] <= prf_rs_rdy[i]; 								
			    end else begin
				prf_rs_rdy[i] <= prf_rs_rdy[i]; 		
			    end 	
			end else begin //issue_en = 0
				if( bus_en==1'b1) begin
					if( i < alloc_index)
						if( tag == prf_rs[i]) prf_rs_rdy[i] <= 1'b1; //CDB Tag match
						else prf_rs_rdy[i] <= prf_rs_rdy[i];
					else if( i==alloc_index && alloc_RS_en == 1'b1)
						if( tag == p_rs_in) prf_rs_rdy[i] <= 1'b1;
						else prf_rs_rdy[i] <= p_rs_rdy_in | (~rs_read); //Allocation
					else //(i>alloc_index)
						prf_rs_rdy[i] <= prf_rs_rdy[i];	//Do nothing		
				end else begin
					if( i==alloc_index && alloc_RS_en == 1'b1)
						if( tag == p_rs_in) prf_rs_rdy[i] <= 1'b1;
						else prf_rs_rdy[i] <= p_rs_rdy_in | (~rs_read); //Allocation
					else
						prf_rs_rdy[i] <= prf_rs_rdy[i];	//Do nothing							
				end

			end
		    end
		end
	end

///////////////////////
// PRF RT READY BIT
///////////////////////

	//Ready bit arrays: prf_rt_rdy[]
	//Allocation: Dispatch
	//Issue and Deallocation: Issue
	//CDB Tag match: Complete

	always@( posedge clk or negedge rst) begin
			prf_rt_rdy[8] <= 1'b0; //The 9th and un-used flip-flop
		
	   	for( i=0; i<8; i=i+1) begin		
		    if( ~rst) 
			prf_rt_rdy[i] <= 1'b0;	
		    else begin
			if( recover == 1'b1) begin
				if( i == flush_index || i>flush_index) begin
					if( i < alloc_index-1) prf_rt_rdy[i] <= prf_rt_rdy[i+1];
					else prf_rt_rdy[i] <= 1'b0;
				end else prf_rt_rdy[i] <= prf_rt_rdy[i];
			end
			else if( issue_en == 1'b1) begin	
			    if( i >= issue_index && i < alloc_index) begin
				if( bus_en==1'b1) begin
					if( i != alloc_index-1) begin
						if( tag == prf_rt[i+1]) prf_rt_rdy[i] <= 1'b1; //CDB Tag Match
						else prf_rt_rdy[i] <= prf_rt_rdy[i+1]; //Shifting up		
					end else begin
						if( alloc_RS_en==1'b1) begin
							if( tag == p_rt_in) prf_rt_rdy[i] <= 1'b1; //Forwarding
							else prf_rt_rdy[i] <= p_rt_rdy_in | (~rt_read);
						end else	
							prf_rt_rdy[i] <= 1'b0;
					end
				end else begin
					if( i != alloc_index-1)
						prf_rt_rdy[i] <= prf_rt_rdy[i+1]; //Shifting up		
					else begin
						if( alloc_RS_en==1'b1) prf_rt_rdy[i] <= p_rt_rdy_in | (~rt_read); //Allocation
						else prf_rt_rdy[i] <= 1'b0;
					end
				end
			    end else if( i < issue_index) begin
				//if(i==alloc_index-1 && alloc_RS_en==1'b1) prf_rt_rdy[i] <= //Not possible: alloc_index IS ALWAYS GREATER THAN issue_index
				if(bus_en==1'b1 && tag == prf_rt[i]) prf_rt_rdy[i] <= 1'b1;
				else prf_rt_rdy[i] <= prf_rt_rdy[i]; 								
			    end else begin
				prf_rt_rdy[i] <= prf_rt_rdy[i]; 		
			    end 	
			end else begin //issue_en = 0
				if( bus_en==1'b1) begin
					if( i < alloc_index)
						if( tag == prf_rt[i]) prf_rt_rdy[i] <= 1'b1; //CDB Tag match
						else prf_rt_rdy[i] <= prf_rt_rdy[i];
					else if( i==alloc_index && alloc_RS_en == 1'b1)
						if( tag == p_rt_in) prf_rt_rdy[i] <= 1'b1;
						else prf_rt_rdy[i] <= p_rt_rdy_in | (~rt_read); //Allocation
					else //(i>alloc_index)
						prf_rt_rdy[i] <= prf_rt_rdy[i];	//Do nothing		
				end else begin
					if( i==alloc_index && alloc_RS_en == 1'b1)
						if( tag == p_rt_in) prf_rt_rdy[i] <= 1'b1;
						else prf_rt_rdy[i] <= p_rt_rdy_in | (~rt_read); //Allocation
					else
						prf_rt_rdy[i] <= prf_rt_rdy[i];	//Do nothing							
				end

			end
		    end
		end
	end

	//Enable/Disable Issue
	reg inst_rdy[0:7]; //Indicates if the source operands are ready	
	wire is_inst_rdy;
	genvar k;
	generate for( k=0; k<8; k=k+1) begin : inst_rdy_block
		always@( valid[k], prf_rs_rdy[k], prf_rt_rdy[k]) begin
			inst_rdy[k] = valid[k] & prf_rs_rdy[k] & prf_rt_rdy[k];
		end
	end
	endgenerate

	assign is_inst_rdy = inst_rdy[0] | inst_rdy[1] | inst_rdy[2] | inst_rdy[3] | inst_rdy[4] | inst_rdy[5] | inst_rdy[6] | inst_rdy[7] ;
	assign issue_en = (recover | stall_hazard | stall_issue) ? (1'b0) : ( is_inst_rdy);

	//Calculate Issue Index
	always@( inst_rdy[0], inst_rdy[1], inst_rdy[2], inst_rdy[3], inst_rdy[4], inst_rdy[5], inst_rdy[6], inst_rdy[7]) begin
		if( inst_rdy[0]) issue_index = 3'b000;
		else if( inst_rdy[1]) issue_index = 3'b001;
		else if( inst_rdy[2]) issue_index = 3'b010;
		else if( inst_rdy[3]) issue_index = 3'b011;
		else if( inst_rdy[4]) issue_index = 3'b100;
		else if( inst_rdy[5]) issue_index = 3'b101;
		else if( inst_rdy[6]) issue_index = 3'b110;
		else if( inst_rdy[7]) issue_index = 3'b111;
		else issue_index = 3'b000;
	end

	//Issue the Instruction/Drive the outputs of RS
	assign p_rs_out = prf_rs[issue_index];
	assign p_rt_out = prf_rt[issue_index];
	assign p_rd_out = prf_rd[issue_index];
	assign EX_ctrl_out = ex_ctrl[issue_index];
	assign imm_bits_out = imm_bits[issue_index];
	assign rob_id_out = rob_id[issue_index];
	assign PC_out = PC[issue_index];	
	assign stl_dec_rs_alu_full = valid[0] & valid[1] & valid[2] & valid[3] & valid[4] & valid[5] & valid[6] & valid[7];

endmodule


