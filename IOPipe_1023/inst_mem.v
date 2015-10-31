//Instruction memory model
//Initializes from file
//Read only
//Reads on posedge clk


module inst_mem(clk, addr, dout);

	input clk;
	input [9:0] addr;
	output reg [31:0] dout;

	reg [31:0] mem [1023:0];

	
	initial begin
		$readmemh("../FastFiveSim/BranchInst", mem);
                //$readmemh("jb_test01_machine.txt", mem);
	end
	
	always@(posedge clk) begin
		dout <= mem[addr];
	end 


endmodule
