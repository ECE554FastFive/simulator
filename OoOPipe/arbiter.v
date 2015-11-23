module abiter (
	input rst,
	input clk,
	input is_alu,
	input is_ls,

	output sel_result,
	output stall_alu,
	output stall_ls
);

	reg int_reg;

	assign sel_result = (is_alu && is_ls)? int_reg : (is_ls? 1'b1 : 0);
	assign stall_alu  = is_alu && is_ls && int_reg;
	assign stall_ls   = is_alu && is_ls && ~int_reg;

	always @(posedge clk)
	if (!rst)
		int_reg <= 0;
	else 
		if (is_alu && is_ls)
			int_reg <= ~int_reg;
	
endmodule
