module in_order_cpu_tb();
   

reg clk, rst;
reg switch_program;
reg [31:0] SPART_pc;
wire spart_wrt_en;
wire [31:0] spart_wrt_add;
wire [31:0] spart_wrt_data;

in_order_cpu i_in_order_cpu(
                            .clk(clk),
                            .rst(rst),
                            .switch_program(switch_program),
                            .SPART_pc(SPART_pc),
                            .spart_wrt_en(spart_wrt_en),
                            .spart_wrt_add(spart_wrt_add),
                            .spart_wrt_data(spart_wrt_data));

initial begin
    clk = 1;
    rst = 0;
    set_input(0, 32'h00000000);
    #2 rst = 1;
    repeat (60) @(posedge clk);
    $stop;
end

always 
 #5 clk = ~clk;


task set_input(sp, pc);
begin
    switch_program = sp;
    SPART_pc = pc;
end
endtask

endmodule