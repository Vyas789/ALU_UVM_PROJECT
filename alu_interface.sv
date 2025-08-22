`include "defines.sv"

interface alu_intf(input logic clk, rst);
    logic [1:0] inp_valid;
    logic mode;
    logic [`m-1:0] cmd;
    logic ce;
    logic [`n-1:0] opa;
    logic [`n-1:0] opb;
    logic cin;
    logic err;
    logic [`n:0] res;
    logic cout;
    logic oflow;
    logic g;
    logic e;
    logic l;

    clocking alu_drv_cb @(posedge clk);
        default input #0 output #0;
        output inp_valid, mode, cmd, ce, opa, opb, cin;
        input res, err, cout, oflow, g, e, l;
    endclocking: alu_drv_cb

    clocking alu_mon_cb @(posedge clk);
        default input #0 output #0;
        input err, res, cout, oflow, e, g, l;
        input inp_valid, mode, cmd, ce, opa, opb, cin;
    endclocking: alu_mon_cb

		clocking alu_ref_cb @(posedge clk);
				default input #0 output #0;
				input opa,opb,cin,ce,cmd,mode,inp_valid, rst, err,res,cout,oflow,e,g,l;
		endclocking:alu_ref_cb

    modport drv(clocking alu_drv_cb);
    modport mon(clocking alu_mon_cb);
   	modport ref_m(clocking alu_ref_cb);

endinterface: alu_intf
