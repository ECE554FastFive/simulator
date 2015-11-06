module IF_stage(
    input clk, rst,
    input changeFlow,
    input [31:0] jb_addr,
    input stall_PC,
    input taken, not_taken,   //branch result, from EX stage  
    input switch_program,
    input [31:0] SPART_pc, 
    output [31:0] instr,
    output [31:0] pc_1,
    output pred_taken,
    output halt
);

reg [31:0] pc;
wire [31:0] nxt_pc;
wire clk_n;

//branch predictor ports
wire [31:0] pred_addr;
wire branch;   //asserted if it is a branch instruction

always @(posedge clk or negedge rst) begin
    if (!rst) 
        pc <= 32'h00000000;
    else if (switch_program) 
        pc <= SPART_pc;
    else if (!stall_PC && (!halt || changeFlow))
        pc <= nxt_pc;
end

assign pc_1 = pc + 1;
assign nxt_pc = changeFlow ? jb_addr : (pred_taken ? pred_addr : pc_1);
assign clk_n = ~clk;

inst_mem i_inst_mem(.clk(clk_n), .addr(pc[9:0]), .dout(instr));



assign branch = (instr[31:26] == 6'b010011) |
                (instr[31:26] == 6'b010100) |
                (instr[31:26] == 6'b010101) |
                (instr[31:26] == 6'b010110) |
                (instr[31:26] == 6'b010111) |
                (instr[31:26] == 6'b011000) |
                (instr[31:26] == 6'b011001);

assign halt = (instr[31:26] == 6'b110001);

branch_pred i_branch_pred(
                          .branch(branch),
                          .taken(taken),
                          .not_taken(not_taken),
                          .pc_1(pc_1),
                          .offset(instr[15:0]),
                          .clk(clk),
                          .rst_n(rst),
                          .pred_taken(pred_taken),
                          .pred_addr(pred_addr));

endmodule
