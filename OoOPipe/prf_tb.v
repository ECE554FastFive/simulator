`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:35:11 11/08/2015 
// Design Name: 
// Module Name:    prf_tb 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module prf_tb( );

reg clk, rst, RegDest_compl, tbclk2x;		//clk, rst, write enable, testbench 2x clk
reg [5:0] p_rs, p_rt, p_rd;		//reg addresses
reg [31:0] wr_data_in;
wire [31:0] rd_data_rs, rd_data_rt;

phy_reg_file prf(
clk,
rst,	
	//Read interface
p_rs, //Read Address 1
p_rt, //Read Address 2
rd_data_rs, //Read Data out1
rd_data_rt, //Read Data out2
	//Write interface
p_rd,			 //From CDB.Tag (complete stage)
wr_data_in, //From CDB.Value  (complete stage)
RegDest_compl            //RegDest from complete stage, it is 1 if this instruction writes register
);

always #5 clk = ~clk;
//always #2.5 tbclk2x = ~tbclk2x;

initial begin
clk = 0;
rst = 1;
RegDest_compl = 0;
p_rs = 6'b0;
p_rt = 6'b0;
p_rd = 6'b0;
wr_data_in = 32'h0;

@(posedge clk);
repeat (2) @(posedge clk);						//rst needs to be asserted for 3 cycles
@(negedge clk) rst = 0;
repeat (10) @(posedge clk); 					//wait 10 clk cycles before clk2x is valid
p_rs = 6'h1;
@(posedge clk)
	wr_data_in = 32'hDEADBEEF;
	RegDest_compl = 1'b1;
	p_rs = 6'h0;
@(posedge clk) //RegDest_compl = 1'b0;
p_rt = 6'h2;
p_rd = 6'h4;
p_rs = 6'h4;
wr_data_in = 32'habababab;
@(posedge clk) RegDest_compl = 1'b0;

//repeat (3) @(posedge clk);
//p_rt = 6'h0;


end


endmodule

