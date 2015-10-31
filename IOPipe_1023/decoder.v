////////////////////////////////////////////////////////
////Author: 
////Date: 
////////////////////////////////////////////////////////
module decoder(
    input [5:0] opcode,
    output reg writeRd,
    output reg isSignEx,
    output reg ldic,
    output reg immed,
    output reg alu_ctrl3,
    output reg alu_ctrl2,
    output reg alu_ctrl1,
    output reg alu_ctrl0,
    output reg isJump,
    output reg isJR,
    output reg rs_read,
    output reg rt_read,
    output reg mem_ren,
    output reg mem_wen,
    output reg lw,
    output reg link,
    output reg reg_wen,
    output reg inc_instr,
    output reg str_ccnt,
    output reg str_icnt,
    output reg stp_cnt
 );
localparam NOP = 6'b000000;
localparam ADD = 6'b000001;
localparam ADDI = 6'b000010;
localparam SUB = 6'b000011;
localparam LUI = 6'b000100;
localparam MOV = 6'b000101;
localparam SLL = 6'b000110;
localparam SRA = 6'b000111;
localparam SRL = 6'b001000;
localparam AND = 6'b001001;
localparam ANDI = 6'b001010;
localparam NOT = 6'b001011;
localparam OR = 6'b001100;
localparam ORI = 6'b001101;
localparam XOR = 6'b001110;
localparam XORI = 6'b001111;
localparam LW = 6'b010001;
localparam SW = 6'b010010;
localparam B = 6'b010011;
localparam BEQ = 6'b010100;
localparam BGT = 6'b010101;
localparam BGE = 6'b010110;
localparam BLE = 6'b010111;
localparam BLT = 6'b011000;
localparam BNE = 6'b011001;
localparam J = 6'b011010;
localparam JAL = 6'b011011;
localparam JALR = 6'b011100;
localparam JR = 6'b011101;
localparam STRCNT = 6'b100000;
localparam STPCNT = 6'b100001;
localparam LDCC = 6'b100010;
localparam LDIC = 6'b100011;
localparam TX = 6'b110000;
localparam HALT = 6'b110001;
localparam ADDB = 6'b010100;
localparam ADDBI = 6'b010101;
localparam SUBB = 6'b010110;
localparam SUBBI = 6'b010111;

wire [5:0] ctrl_codes = opcode;

always @(ctrl_codes) begin

    case(ctrl_codes)
        NOP: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 0;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 0;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        ADD: begin
            writeRd = 1;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        ADDI: begin
            writeRd = 0;
             isSignEx = 1;
             ldic = 0;
             immed = 1;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        SUB: begin
            writeRd = 1;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        LUI: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 1;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 1;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 0;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        MOV: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 1;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        SLL: begin
            writeRd = 1;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 1;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        SRA: begin
            writeRd = 1;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 1;
             alu_ctrl1 = 1;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        SRL: begin
            writeRd = 1;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 1;
             alu_ctrl1 = 1;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        AND: begin
            writeRd = 1;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 1;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        ANDI: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 1;
             alu_ctrl3 = 0;
             alu_ctrl2 = 1;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        NOT: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 1;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        OR: begin
            writeRd = 1;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 1;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        ORI: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 1;
             alu_ctrl3 = 1;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        XOR: begin
            writeRd = 1;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 1;
             alu_ctrl2 = 0;
             alu_ctrl1 = 1;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        XORI: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 1;
             alu_ctrl3 = 1;
             alu_ctrl2 = 0;
             alu_ctrl1 = 1;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        LW: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 1;
             mem_wen = 0;
             lw = 1;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        SW: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 1;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        B: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        BEQ: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        BGT: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        BGE: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        BLE: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        BLT: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        BNE: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        J: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 1;
             isJR = 0;
             rs_read = 0;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        JAL: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 1;
             isJR = 0;
             rs_read = 0;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 1;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        JALR: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 1;
             isJR = 1;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 1;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        JR: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 1;
             isJR = 1;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        STRCNT: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 0;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 1;
             str_icnt = 1;
             stp_cnt = 0;
         end
        STPCNT: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 0;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 1;
         end
        LDCC: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 1;
             alu_ctrl2 = 1;
             alu_ctrl1 = 1;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 0;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        LDIC: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 1;
             immed = 0;
             alu_ctrl3 = 1;
             alu_ctrl2 = 1;
             alu_ctrl1 = 1;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 0;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        TX: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 0;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        HALT: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 0;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        ADDB: begin
            writeRd = 1;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 1;
             alu_ctrl2 = 0;
             alu_ctrl1 = 1;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        ADDBI: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 1;
             alu_ctrl3 = 1;
             alu_ctrl2 = 1;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        SUBB: begin
            writeRd = 1;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 1;
             alu_ctrl2 = 1;
             alu_ctrl1 = 0;
             alu_ctrl0 = 1;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 1;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        SUBBI: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 1;
             alu_ctrl3 = 1;
             alu_ctrl2 = 1;
             alu_ctrl1 = 1;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 1;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 1;
             inc_instr = 1;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
        default: begin
            writeRd = 0;
             isSignEx = 0;
             ldic = 0;
             immed = 0;
             alu_ctrl3 = 0;
             alu_ctrl2 = 0;
             alu_ctrl1 = 0;
             alu_ctrl0 = 0;
             isJump = 0;
             isJR = 0;
             rs_read = 0;
             rt_read = 0;
             mem_ren = 0;
             mem_wen = 0;
             lw = 0;
             link = 0;
             reg_wen = 0;
             inc_instr = 0;
             str_ccnt = 0;
             str_icnt = 0;
             stp_cnt = 0;
         end
    endcase
end

endmodule
