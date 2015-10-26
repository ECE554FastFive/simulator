module EX_stage(              
    input [31:0] rs_data, rt_data,
    input [31:0] instr,
    input [15:0] instr_cnt, cycle_cnt,
    input [31:0] pc_1,
    //control signals for EX
    input writeRd,   //if 1 select rd as the destination
    input ldic,    //if 1 select instruction counter value
    input isSignEx,  //if 1 select signed extension
    input immed,   //if 1 select immediate value
    input alu_ctrl0, alu_ctrl1, alu_ctrl2, alu_ctrl3,
    input isJump, isJR,
    input pred_taken,
    //other inputs
    output [31:0] alu_result,
    output [31:0] mem_addr,
    output [31:0] jb_addr,   //next pc if there's a jump or branch
    output [4:0] dst_reg,
    output changeFlow,   //change PC, as well as flush the IF/ID and ID/EX
    output taken, not_taken
);

wire flag_z, flag_n, flag_v;
wire [31:0] alu_in0, alu_in1;
wire [15:0] perf_cnt;
wire [4:0] shamt;

wire isBranch;
wire [31:0] branch_addr;

assign alu_in0 = rs_data;
assign alu_in1 = immed ? (isSignEx ? {{16{instr[15]}}, instr[15:0]} : {16'h0000, instr[15:0]}) : rt_data;
assign perf_cnt = ldic ? instr_cnt : cycle_cnt;
assign shamt = instr[10:6];

//ALU
ALU iALU(.alu_out(alu_result), .flag_z(flag_z), .flag_v(flag_v), .flag_n(flag_n), .in1(alu_in1), .in0(alu_in0), .shamt(shamt),
         .perf_cnt(perf_cnt), .alu_ctrl0(alu_ctrl0), .alu_ctrl1(alu_ctrl1), .alu_ctrl2(alu_ctrl2), .alu_ctrl3(alu_ctrl3));

//mem addr generator
assign mem_addr = rs_data + {{16{instr[15]}}, instr[15:0]};

//destination selection
assign dst_reg = writeRd ? instr[15:11] : instr[20:16];

wire mispred_taken, mispred_nottaken;

//branch decision generator
branch_gen ibranch_gen(.isBranch(isBranch), .opcode(instr[31:26]), .flag_n(flag_n), .flag_z(flag_z), .flag_v(flag_v));
assign branch_addr = mispred_nottaken ? (pc_1 + {{16{instr[15]}}, instr[15:0]}) : pc_1;

assign mispred_taken = pred_taken && ~isBranch;  //predict taken, actually not taken
assign mispred_nottaken = ~pred_taken && isBranch;
assign taken = isBranch;
assign not_taken = !isBranch;

//jump&branch address selection, need to flash previous pipeline if there's jump or branch misprediction
assign jb_addr = (mispred_taken|mispred_nottaken) ? branch_addr : (isJR ? rs_data : {pc_1[31:26], instr[25:0]});
assign changeFlow = (mispred_taken|mispred_nottaken) | isJump;   //only branch misprediction or jump will change the flow
endmodule
