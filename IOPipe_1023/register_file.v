module register_file(
    input [4:0] raddr0, raddr1,
    input we,
    input [4:0] waddr,
    input [31:0] din,
    input clk,
    output [31:0] dout0,
    output [31:0] dout1
);

reg [31:0] mem [0:31];
wire [31:0] dout0_int, dout1_int;

always @(posedge clk) begin
   if (we)
       mem[waddr] <= din;
end

assign dout0 = ((raddr0 == waddr) && we) ? din : mem[raddr0];
assign dout1 = ((raddr1 == waddr) && we) ? din : mem[raddr1];

endmodule
