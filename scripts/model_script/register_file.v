module register_file(
    input [4:0] raddr0, raddr1,
    input we,
    input [4:0] waddr,
    input [31:0] din,
    input clk,
    output reg [31:0] dout0,
    output reg [31:0] dout1
);

reg [31:0] mem [0:31];
wire [31:0] dout0_int, dout1_int;

always @(posedge clk) begin
   if (we)
       mem[waddr] <= din;
   dout0 <= dout0_int;
   dout1 <= dout1_int;
end

//register bypass
assign dout0_int = (raddr0 == waddr) ? din : mem[raddr0];
assign dout1_int = (raddr1 == waddr) ? din : mem[raddr1];

endmodule
