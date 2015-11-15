module OoOPipe_tb();

    logic clk;
    logic rst;


    OoO_cpu i_OoO_cpu(.clk(clk), .rst(rst));

    initial begin
         clk = 0;
         rst = 0;
         #16 rst = 1;
         repeat (20) @(posedge clk);
         $stop;
    end

    always 
     #5 clk = ~clk;

endmodule
