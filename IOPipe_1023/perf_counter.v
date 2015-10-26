module perf_counter(
    input strcnt, stpcnt,    //from write-back stage
    input clk, rst,
    input inc_instr,         //from write-back stage
    output reg [15:0] instr_cnt, cycle_cnt
);

localparam IDLE = 1'b0;
localparam CNT = 1'b1;

reg state, nstate;

reg clr_cnt, enb_cnt;

always @(posedge clk or negedge rst) begin
    if (rst) 
        state <= 0;
    else
        state <= nstate;
end

always @(state or strcnt or stpcnt) begin
    clr_cnt = 0;
    enb_cnt = 0;
    nstate = IDLE;
    case (state) 
        IDLE: begin 
              if (strcnt) begin
                  nstate = CNT;
                  clr_cnt = 1;
             end else begin
                  nstate = IDLE;
             end
       end
       default: begin
             enb_cnt = 1;
             if (stpcnt) 
                 nstate = IDLE;
             else 
                 nstate = CNT; 
       end
   endcase
end

always @(posedge clk or posedge rst) begin
     if (rst) 
         instr_cnt <= 0;
     else if (clr_cnt)
         instr_cnt <= 0;
     else if (enb_cnt && inc_instr)               //instruction counter only increase when receiving inc signal from WB/retire stage
         instr_cnt <= instr_cnt + 1;
end

always @(posedge clk or posedge rst) begin
     if (rst) 
         cycle_cnt <= 0;
     else if (clr_cnt)
         cycle_cnt <= 0;
     else if (enb_cnt)                   //cycle counter increases every cycle if enable is asserted
         cycle_cnt <= cycle_cnt + 1;
end


endmodule
