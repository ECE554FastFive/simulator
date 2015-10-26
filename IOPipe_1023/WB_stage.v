module WB_stage(
    input [31:0] pc_1, alu_result, mem_rdata,
    input [4:0] dst_reg,
    input lw, link,
    output [31:0] wb_data,
    output [4:0] wb_addr
);

    assign wb_data = lw ? mem_rdata : (link ? pc_1 : alu_result);
    assign wb_addr = link ? 5'b11111 : dst_reg;

endmodule
