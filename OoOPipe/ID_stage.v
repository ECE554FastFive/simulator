module ID_stage(
    input [5:0] opcode,

    //other inputs
    input RS_full, ROB_full, free_list_empty,
    input stall_recover, 
    input stall_arbiter,   //when one ALU op and one load complete together, stall one cycle
    //control signal used in Decode
    output writeRd, 
    //control signal used in Dispatch
    output isDispatch,  //rob enable signal
    output MemOp,       //used in LSQ, and ROB, asserted if it is a memory operation
    output RegDest,    //freelist read enable
    output RS_en,
    
    output ldic, isSignEx, immed, 
    output alu_ctrl0, alu_ctrl1, alu_ctrl2, alu_ctrl3,
    output isJump, isJR,

    output ld,   //this signal is 1 for load and 0 for stores
    output mem_wen,   //memory write enable
    
    output link,
    output strcnt, stpcnt,
    output halt
    
);

decoder i_decoder();
stall_control i_stall_control();

endmodule
