/////////now have changed this to 
module physical_register(
    input [5:0] raddr0, raddr1,
    input we,
    input [5:0] waddr,
    input [31:0] din,
    input clk,
    output reg [31:0] dout0,
    output reg [31:0] dout1
);

reg [31:0] mem [0:63];
wire [31:0] dout0_int, dout1_int;


initial begin
    $readmemh("prf_value.txt", mem);
end

always @(posedge clk) begin          //the reset is not used
   if (we)
       mem[waddr] <= din;
   //the IS/EX pipeline register
   dout0 <= dout0_int;
   dout1 <= dout1_int;
end

assign dout0_int = ((raddr0 == waddr) && we) ? din : mem[raddr0];
assign dout1_int = ((raddr1 == waddr) && we) ? din : mem[raddr1];

endmodule
