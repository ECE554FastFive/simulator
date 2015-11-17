//64 registers, 32-bits each 
module phy_reg_file (
	input clk,
	input rst,	
	//Read interface
	input [5:0] p_rs, //Read Address 1
	input [5:0] p_rt, //Read Address 2
	output [31:0] rd_data_rs, //Read Data out1
	output [31:0] rd_data_rt, //Read Data out2
	//Write interface
	input [5:0] p_rd,			 //From CDB.Tag (complete stage)
	input [31:0] wr_data_in, //From CDB.Value  (complete stage)
	input RegDest_compl            //RegDest from complete stage, it is 1 if this instruction writes register
);

wire clk2x, clk_buf; 
reg [5:0] clked_rs;
reg [5:0] clked_rt;
reg [31:0] rd_data_rs, rd_data_rt;
wire [31:0] rd_data_a, rd_data_b, rd_data_a_muxed, rd_data_b_muxed;
wire [5:0] addra, addrb;
wire we;

assign we =  RegDest_compl&~clk_buf;		// only write if clk is high (second 1/2 of clk cycle) 
assign addra = we?p_rd:clked_rs;	//if write enabled, addr change to rd
assign addrb = we?p_rd:clked_rt;

//read on second clk edge of 2x clk
always@(posedge clk2x, posedge rst) begin
	if(rst) begin
		clked_rs <= 6'h0;
		clked_rt <= 6'h0;
	end else begin
		clked_rs <= p_rs;
		clked_rt <= p_rt;
	end
end

//clk the mem read outputs, keep same on clk high (when writing)
always@(posedge clk_buf, posedge rst) begin
	if(rst) begin
		rd_data_rs <= 32'h0;
		rd_data_rt <= 32'h0;
	end else begin
		rd_data_rs <= rd_data_a_muxed;
		rd_data_rt <= rd_data_b_muxed;
	end
end

clk_mult cm(.CLKIN_IN(clk), 
            .RST_IN(rst), 
            .CLKIN_IBUFG_OUT(), 
            .CLK0_OUT(clk_buf), 
				.CLK2X_OUT(clk2x),
            .LOCKED_OUT());

blockram br_prf(
  .clka(clk2x),		//clock A
  .wea(we),		//write enable A
  .addra(addra),		//addr A (first phase write, second phase read)
  .dina(wr_data_in),		//data in A
  .douta(rd_data_a),		//data out A
  .clkb(clk2x),		//clock B
  .web(we),		//write enable B
  .addrb(addrb),		//addr B (first phase write, second phase read)
  .dinb(wr_data_in),		//data in B
  .doutb(rd_data_b)		//data out B
);

assign rd_data_a_muxed = (|clked_rs) ? rd_data_a : 32'h0;		//if addr not 0, read data, else is 0
assign rd_data_b_muxed = (|clked_rt) ? rd_data_b : 32'h0;

endmodule
