// Code your testbench here
// or browse Examples
 import uvm_pkg::*;
`include "uvm_pkg.sv"
`include "uvm_macros.svh"
`include "alu_interface.sv"
//`include "design.sv"
`include "alu_sequence_item.sv"
`include "alu_sequence.sv"
`include "alu_driver.sv"
`include "alu_monitor_new.sv"
`include "alu_sequencer.sv"
`include "alu_scoreboard_new1.sv"
`include "alu_subscriber.sv"
`include "alu_agent.sv"
`include "alu_environment.sv"
`include "alu_test.sv"

 
module top;
  	//import alu_pkg::*;
   //import uvm_pkg::*;
  	bit clk;
  	bit rst;
  	
  	initial clk = 1'b0;
  	always #5 clk = ~ clk;
  
  	initial begin
      	rst = 1'b1;
      	#5 rst = 1'b0;
    end
  	
  	alu_intf intf(clk,rst);
  
  ALU_DESIGN  DUT(
    .CLK(intf.clk),
    .RST(intf.rst),
      .OPA(intf.opa),
      .OPB(intf.opb),
      .INP_VALID(intf.inp_valid),
      .CMD(intf.cmd),
      .MODE(intf.mode),
      .CE(intf.ce),
      .CIN(intf.cin),
      .RES(intf.res),
      .COUT(intf.cout),
      .ERR(intf.err),
      .OFLOW(intf.oflow),
      .G(intf.g),
      .E(intf.e),
      .L(intf.l)
  );
  
  initial begin
    uvm_config_db#(virtual alu_intf)::set(uvm_root::get(),"*","vif",intf);
//     $dumpfile("dump.vcd");
// 	$dumpvars;
  end
  
  initial begin

    run_test("alu_test");

    	#100 $finish;
  end
endmodule
