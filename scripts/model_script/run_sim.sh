#!/bin/sh         
 
vlib work                    ##create a library work
vlog register_file.v         ##compile register_file.v
vlog register_file_tb.v      ##compile testbench

vsim -novopt -t 1ps register_file_tb -do run.do 
