//Two units: ALU, branch reslover, memory address generator in LSQ
//LSQ is kind of in parallel with this unit
module EX_stage_OoO(
    //from performance counters
    input [15:0] instr_cnt, cycle_cnt,
    //from reservation station, data signals
    input [31:0] rs_data, rt_data,
    input [31:0] pc_1,
    input [15:0] immed_value,
    input [5:0] opcode,
    //from reservation station, control signals
    ////*****writeRd: which is for write whether rd or rt, moved to ID/DP stage, before indexing Map Table
    input ldic, isSignEx, immed,
    input alu_ctrl0, alu_ctrl1, alu_ctrl2, alu_ctrl3,
    input isJump, isJR,
    output [31:0] alu_out,     //to CDB arbiter
    output changeFlow,
    output [31:0] jb_addr     //changeFlow and jb_addr, to complete stage, then to ROB
);

wire flag_z, flag_n, flag_v;
wire [31:0] in0, in1;
wire [15:0] perf_cnt;
wire [4:0] shamt;

assign in0 = rs_data;
assign in1 = immed ? (isSignEx ? {{16{immed_value[15]}}, immed_value[15:0]} : {16'h0000, immed_value[15:0]}) : rt_data;
assign perf_cnt = ldic ? instr_cnt : cycle_cnt;
assign shamt = immed_value[10:6];

//ALU
ALU i_ALU(
          .in0(in0),
          .in1(in1),
          .shamt(shamt),
          .perf_cnt(perf_cnt),
          .alu_ctrl0(alu_ctrl0),
          .alu_ctrl1(alu_ctrl1),
          .alu_ctrl2(alu_ctrl2),
          .alu_ctrl3(alu_ctrl3),
          .alu_out(alu_out),
          .flag_z(flag_z),
          .flag_v(flag_v),
          .flag_n(flag_n));


wire isBranch;          //if branch taken, set to 1
wire [31:0] branch_addr;
//branch resolver
branch_gen ibranch_gen(.isBranch(isBranch), .opcode(opcode), .flag_n(flag_n), .flag_z(flag_z), .flag_v(flag_v));
assign branch_addr = pc_1 + {{16{immed_value[15]}}, immed_value[15:0]};
assign changeFlow = isBranch | isJump;                                 //first assume branch untaken
assign jb_addr = isBranch ? branch_addr : (isJR ? rs_data : {pc_1[31:16], immed_value});

endmodule
