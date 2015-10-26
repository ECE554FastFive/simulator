module MEM_stage(
    output [31:0] mem_rdata,
    input clk,
    input [31:0] mem_addr,
    input [31:0] mem_wdata,
    input mem_ren, mem_wen
);

data_mem i_data_mem(
                    .clk(clk),
                    .en(mem_ren),
                    .we(mem_wen),
                    .addr(mem_addr[13:0]),
                    .wdata(mem_wdata),
                    .rdata(mem_rdata));
//adding another memory module in 
endmodule
