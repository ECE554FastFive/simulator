module hazard_detect(
    input changeFlow, //control hazard, need to flush IF_ID and ID_EX
    input [4:0] ID_rs, ID_rt,
    input rs_read, rt_read,
    input [4:0] EX_dst_reg, MEM_dst_reg,
    input EX_reg_wen, MEM_reg_wen,
    output flush_ID, flush_EX,   //flush ID and EX when changing flow. flush EX, stall PC and ID when data hazard
    output stall_PC_ID
);

wire ex_dep, mem_dep;
assign ex_dep = (((ID_rs == EX_dst_reg) && rs_read) ||
                ((ID_rt == EX_dst_reg) && rt_read)) && EX_reg_wen;
assign mem_dep = (((ID_rs == MEM_dst_reg) && rs_read) ||
                ((ID_rt == MEM_dst_reg) && rt_read)) && MEM_reg_wen;

assign flush_ID = changeFlow;        //flush both IF_ID and ID_EX when there is jump or branch mis-prediction
assign flush_EX = changeFlow || ex_dep || mem_dep;
assign stall_PC_ID = ex_dep || mem_dep;   //stall PC and IF_ID, flush ID_EX when there is RAW data dependence
endmodule
