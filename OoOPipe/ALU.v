module ALU(
    output reg [31:0] alu_out,
    output flag_z, flag_v, flag_n,
    input [31:0] in0, in1,     //in0 is rs, in1 can be rt or sign/unsign-extended immediate value
    input [4:0] shamt,
    input [15:0] perf_cnt, //input from performance counter
    input alu_ctrl0, alu_ctrl1, alu_ctrl2, alu_ctrl3
);

localparam ADD = 4'h0, SUB = 4'h1, LUI = 4'h2, MOV = 4'h3;
localparam AND = 4'h4, SLL = 4'h5, SRA = 4'h6, SRL = 4'h7; 
localparam NOT = 4'h8, OR = 4'h9, XOR = 4'ha, ADDB = 4'hb;
localparam ADDBI = 4'hc, SUBB = 4'hd, SUBBI = 4'he, LDC = 4'hf; //LDC stands for load counters

wire [3:0] alu_ctrl = {alu_ctrl3, alu_ctrl2, alu_ctrl1, alu_ctrl0};

//////wires for shift
wire [31:0] dsll0, dsll1, dsll2, dsll3, dsll4;
wire [31:0] dsrl0, dsrl1, dsrl2, dsrl3, dsrl4;
wire [31:0] dsra0, dsra1, dsra2, dsra3, dsra4;

//////wires for byte-wise arithmetic
wire [8:0] addb0_int, addb1_int, addb2_int, addb3_int; 
wire [7:0] addb0, addb1, addb2, addb3;       
wire [7:0] subb0, subb1, subb2, subb3;

//////ALU result
always @(alu_ctrl or in0 or in1) begin
    case (alu_ctrl)
        ADD: alu_out = in0 + in1;
        SUB: alu_out = in0 - in1;
        LUI: alu_out = {in1[15:0], 16'h0000};   //the concatenation is done before going into ALU
        MOV: alu_out = in0;
        AND: alu_out = in0 & in1;
        SLL: alu_out = dsll4;
        SRA: alu_out = dsra4;
        SRL: alu_out = dsrl4;
        NOT: alu_out = ~in0;
        OR: alu_out = in0 | in1;
        XOR: alu_out = in0 ^ in1;
        ADDB: alu_out = {addb3, addb2, addb1, addb0};         //currently don't care about the correctness of these byte-wise ops
        ADDBI: alu_out = {addb3, addb2, addb1, addb0};
        SUBB: alu_out = {subb3, subb2, subb1, subb0};
        SUBBI: alu_out = {subb3, subb2, subb1, subb0};
        LDC: alu_out = {16'h0000, perf_cnt};
    endcase
end

//////flags  //////our flag only used in branch instruction, we don't have overflow exception
assign flag_z = ~(|alu_out);
assign flag_n = alu_out[31];
assign flag_v = (in0[31] & in1[31] & ~alu_out[31]) || (~in0[31] & ~in1[31] & alu_out[31]);
///////////////////////////////////////////////////////////////////////////////////////////////
//////////////////log shifter//////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
//shifter left logically (SLL) block
assign dsll0 = shamt[0] ? {in0[30:0], 1'b0} : in0;        //shift left logic/arithmetic
assign dsll1 = shamt[1] ? {dsll0[29:0], 2'b00} : dsll0;
assign dsll2 = shamt[2] ? {dsll1[27:0], 4'h0} : dsll1;
assign dsll3 = shamt[3] ? {dsll2[23:0], 8'h00} : dsll2;
assign dsll4 = shamt[4] ? {dsll3[15:0], 16'h0000} : dsll3;

//SRL block
assign dsrl0 = shamt[0] ? {1'b0, in0[31:1]} : in0;    //shift right logically
assign dsrl1 = shamt[1] ? {2'b00, dsrl0[31:2]} : dsrl0;  
assign dsrl2 = shamt[2] ? {4'h0, dsrl1[31:4]} : dsrl1;
assign dsrl3 = shamt[3] ? {8'h00, dsrl2[31:8]} : dsrl2;
assign dsrl4 = shamt[4] ? {16'h0000, dsrl3[31:16]} : dsrl3;

//SRA block
assign dsra0 = shamt[0] ? { in0[31], in0[31:1]} : in0;
assign dsra1 = shamt[1] ? { {2{dsra0[31]}} , dsra0[31:2]} : dsra0;  //shift right arithmetically
assign dsra2 = shamt[2] ? { {4{dsra1[31]}} , dsra1[31:4]} : dsra1;
assign dsra3 = shamt[3] ? { {8{dsra2[31]}} , dsra2[31:8]} : dsra2;
assign dsra4 = shamt[4] ? { {16{dsra3[31]}} , dsra3[31:16]} : dsra3;


///////////////////////////////////////////////////////////////////////////////////////////////////
////////////saturating unsigned arithmetic for byte-wise operation//////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
assign addb0_int = in0[7:0] + in1[7:0];
assign addb1_int = (alu_ctrl == ADDBI) ? in0[15:8] + in1[7:0] : in0[15:8] + in1[15:8];
assign addb2_int = (alu_ctrl == ADDBI) ? in0[15:8] + in1[7:0] : in0[23:16] + in1[23:16];
assign addb3_int = (alu_ctrl == ADDBI) ? in0[15:8] + in1[7:0] : in0[31:24] + in1[31:24];
assign addb0 = addb0_int[8] ? 8'hFF : addb0_int[7:0];
assign addb1 = addb1_int[8] ? 8'hFF : addb1_int[7:0];
assign addb2 = addb2_int[8] ? 8'hFF : addb2_int[7:0];
assign addb3 = addb3_int[8] ? 8'hFF : addb3_int[7:0];
assign subb0 = in0[7:0] - in1[7:0];
assign subb1 = (alu_ctrl == SUBBI) ? in0[15:8] - in1[7:0] : in0[15:8] - in1[15:8];
assign subb2 = (alu_ctrl == SUBBI) ? in0[15:8] - in1[7:0] : in0[23:16] - in1[23:16];
assign subb3 = (alu_ctrl == SUBBI) ? in0[15:8] - in1[7:0] : in0[31:24] - in1[31:24];
endmodule
