//Data memory model
//Has one read and one write port
//Reads and writes are carried out on posedge clk

module data_mem(clk, en, we, wdata, addr, rdata);

	input clk;
 	input en; 
	input we;

 	input [13:0] addr;
	input [31:0] wdata;
	
	output reg [31:0] rdata;

	reg [31:0] mem [16383:0];

	always@(posedge clk) begin
		if(en)
			rdata <= mem[addr];
		else
			rdata <= 32'hxxxxxxxx;
	end

	always@(posedge clk) begin
		if(we)
			mem[addr] <= wdata;
	end

	initial begin
		$readmemh("../FastFiveSim/BubbleData", mem);
	end

endmodule
