module in_order_cpu_tb();
   

reg clk, rst;

in_order_cpu i_in_order_cpu(.clk(clk), .rst(rst));

initial begin
    clk = 1;
    rst = 0;
    #2 rst = 1;
    repeat (60) @(posedge clk);
    $stop;
end

always 
 #5 clk = ~clk;

endmodule