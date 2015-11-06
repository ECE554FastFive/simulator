module perf_cnt(
    output reg [15:0] instr_cnt, cycle_cnt,
    input inc_instr,    //from write back stage, adding a new control signal, set to 1 except for nop
    input clk, rst,
    input str_icnt, str_ccnt,
    input stp_cnt
);

reg clr_ccnt, enb_ccnt;
reg clr_icnt, enb_icnt;

always @(posedge clk or negedge rst) begin
     if (!rst) 
         instr_cnt <= 0;
     else if (clr_icnt)
         instr_cnt <= 0;
     else if (enb_icnt && inc_instr)               //instruction counter only increase when receiving inc signal from WB/retire stage
         instr_cnt <= instr_cnt + 1;
end

always @(posedge clk or negedge rst) begin
     if (!rst) 
         cycle_cnt <= 0;
     else if (clr_ccnt)
         cycle_cnt <= 0;
     else if (enb_ccnt)                   //cycle counter increases every cycle if enable is asserted
         cycle_cnt <= cycle_cnt + 1;
end

localparam IDLE_C = 1'b0;
localparam CCNT = 1'b1;

reg state_c, nstate_c;

always @(posedge clk or negedge rst) begin
    if (!rst) 
        state_c <= IDLE_C;
    else
        state_c <= nstate_c;
end

always @(state_c or str_ccnt or stp_cnt) begin
    clr_ccnt = 0;
    enb_ccnt = 0;
    nstate_c = IDLE_C;
    case (state_c) 
        IDLE_C: begin 
              if (str_ccnt) begin
                  nstate_c = CCNT;
                  clr_ccnt = 1;
             end else begin
                  nstate_c = IDLE_C;
             end
       end
       default: begin
             enb_ccnt = 1;
             if (stp_cnt) 
                 nstate_c = IDLE_C;
             else 
                 nstate_c = CCNT; 
       end
   endcase
end

localparam IDLE_I = 1'b0;
localparam ICNT = 1'b1;

reg state_i, nstate_i;

always @(posedge clk or negedge rst) begin
    if (!rst) 
        state_i <= IDLE_I;
    else
        state_i <= nstate_i;
end

always @(state_i or str_icnt or stp_cnt) begin
    clr_icnt = 0;
    enb_icnt = 0;
    nstate_i = IDLE_I;
    case (state_i) 
        IDLE_C: begin 
              if (str_icnt) begin
                  nstate_i = ICNT;
                  clr_icnt = 1;
             end else begin
                  nstate_i = IDLE_I;
             end
       end
       default: begin
             enb_icnt = 1;
             if (stp_cnt) 
                 nstate_i = IDLE_I;
             else 
                 nstate_i = ICNT; 
       end
   endcase
end
endmodule
