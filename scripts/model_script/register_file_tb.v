module register_file_tb();
    reg [4:0] raddr0, raddr1;
    reg we;
    reg [5:0] waddr;
    reg [31:0] din;
    reg clk;
    wire [31:0] dout0;
    wire [31:0] dout1;

    register_file iDUT(.raddr0(raddr0), .raddr1(raddr1), .we(we), .waddr(waddr), .din(din),
                       .clk(clk), .dout0(dout0), .dout1(dout1));
 
    integer outfile;
    integer idx;
    initial begin
        clk = 0;
        raddr0 = 4;
        raddr1 = 5;
        we = 1;
        din = 32'h00000001;
        outfile = $fopen("rf_dump.txt", "w");
        for (waddr = 0; waddr < 32; waddr = waddr + 1) begin
            @(posedge clk);
            din = din + 1;
        end
        we = 0;
        repeat (2) @(posedge clk);
        raddr0 = 14;
        raddr1 = 15;
        $display("This is a dispaly %0d", dout0);
        for (idx = 0; idx < 32; idx = idx + 1) begin
            $fwrite(outfile, "rf#: %0d value: %0h\n", idx, iDUT.mem[idx]);
        end
        $fclose(outfile);
        repeat (2) @(posedge clk); $stop;
    end

   always 
      #5 clk = ~clk;
endmodule
