module IF_stage(
    input clk, rst,
    input changeFlow,
    input [31:0] jb_addr,
    input stall_PC,
    input stall_IF_DP,
    input flush_IF_DP,
    output reg [31:0] instr_IF_DP,
    output reg [31:0] pc_1_IF_DP
);

reg [31:0] pc;
wire [31:0] nxt_pc;
wire clk_n;
wire [31:0] pc_1;
wire [31:0] instr;

always @(posedge clk or negedge rst) begin
    if (!rst) 
        pc <= 32'h00000000;
    else if (!stall_PC)
        pc <= nxt_pc;
end

assign pc_1 = pc + 1;
assign nxt_pc = changeFlow ? jb_addr : pc_1;
assign clk_n = ~clk;

inst_mem i_inst_mem(.clk(clk_n), .addr(pc[9:0]), .dout(instr));


always @(posedge clk or negedge rst) begin
   if (!rst)
      {instr_IF_DP, pc_1_IF_DP} <= {32'h00000000, 32'h00000000};
   else if (flush_IF_DP) 
      instr_IF_DP <= 0;   //flushing instr_IF_ID is enough
   else if (!stall_IF_DP)
      {instr_IF_DP, pc_1_IF_DP} <= {instr, pc_1};
end

endmodule
