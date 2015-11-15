`timescale 1ns / 1ps

module tb();

 abiter abiter(
	.rst(rst),
	.clk(clk),
	.is_alu(is_alu),
	.is_ls(is_ls),

	.sel_result(sel_result),
	.stall_alu(stall_alu),
	.stall_ls(stall_ls)
	);

	reg clk, rst, is_alu, is_ls;

 	initial begin
		clk <= 1'b1;
		forever #5 clk <= ~clk;
 	end
	initial begin
		is_alu <= 1'b0;
		forever #20 is_alu <= ~is_alu;
	end
	initial begin
		is_ls  <= 1'b0;
		forever #60 is_ls  <= ~is_ls;
	end

 	initial begin
		#0 rst <= 1'b1;
		#20 rst <= 1'b0;
		#150 $finish;
 	end

	initial begin
  	$dumpfile("z_dump.vcd");
  	$dumpvars(0,tb);
	end

endmodule
