module perf_cnt_tb();
  
reg inc_instr;
reg clk;
reg rst;
reg str_icnt;
reg str_ccnt;
reg stp_cnt;
wire [15:0] instr_cnt;
wire [15:0] cycle_cnt;

perf_cnt i_perf_cnt(
                    .inc_instr(inc_instr),
                    .clk(clk),
                    .rst(rst),
                    .str_icnt(str_icnt),
                    .str_ccnt(str_ccnt),
                    .stp_cnt(stp_cnt),
                    .instr_cnt(instr_cnt),
                    .cycle_cnt(cycle_cnt));
initial begin
    rst = 0;
    clk = 0;
    set_input(0, 0, 0, 0);
    #2 rst = 1;
    repeat (2) @(posedge clk);
    set_input(1, 0, 0, 0);         //inc_instr is 1, however should not increase
    repeat (2) @(posedge clk);
    set_input(1, 0, 1, 0);          //start cycle count, from ID stage
    @(posedge clk);
    set_input(1, 0, 0, 0); 
    repeat (3) @(posedge clk);
    set_input(1, 1, 0, 0);        //start instr count, from WB stage
    @(posedge clk);
    set_input(1, 0, 0, 0); 
    repeat (10) @(posedge clk);      //wait for some cycles
    set_input(0, 0, 0, 0);  
    repeat (1) @(posedge clk);          //for one cycle there is no instruction finishes
    set_input(1, 0, 0, 0); 
    repeat (2) @(posedge clk);      //wait for some cycles
    set_input(1, 0, 0, 1);         //stop count
    @(posedge clk);
    set_input(1, 0, 0, 0);
    repeat (3) @(posedge clk);    
    $stop;
end

always 
#5 clk = ~ clk;


task set_input(input inc_instr_in, input str_icnt_in, input str_ccnt_in, input stp_cnt_in);
begin
    inc_instr = inc_instr_in;
    str_icnt = str_icnt_in;
    str_ccnt = str_ccnt_in;
    stp_cnt = stp_cnt_in;
end
endtask
endmodule
