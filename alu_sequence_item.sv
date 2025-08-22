import uvm_pkg::*;
`include "uvm_macros.svh"
`include "defines.sv"


class alu_sequence_item extends uvm_sequence_item;
    
    rand bit [`n-1:0] opa;          
    rand bit [`n-1:0] opb;          
    rand bit cin;                
    rand bit ce;                  
    rand bit mode;               
    rand bit [1:0] inp_valid;    
    rand bit [`m-1:0] cmd;          
    
    bit [`n:0] res;                
    bit oflow;                    
    bit cout;                    
    bit g, l, e;                 
    bit err;                      
    
    `uvm_object_utils_begin(alu_sequence_item)
        `uvm_field_int(opa,      UVM_ALL_ON)
        `uvm_field_int(opb,      UVM_ALL_ON)
        `uvm_field_int(cin,      UVM_ALL_ON)
        `uvm_field_int(ce,       UVM_ALL_ON)
        `uvm_field_int(mode,     UVM_ALL_ON)
        `uvm_field_int(inp_valid,UVM_ALL_ON)
        `uvm_field_int(cmd,      UVM_ALL_ON)
        `uvm_field_int(res,      UVM_ALL_ON)
        `uvm_field_int(oflow,    UVM_ALL_ON)
        `uvm_field_int(cout,     UVM_ALL_ON)
        `uvm_field_int(g,        UVM_ALL_ON)
        `uvm_field_int(l,        UVM_ALL_ON)
        `uvm_field_int(e,        UVM_ALL_ON)
        `uvm_field_int(err,      UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "alu_sequence_item");
        super.new(name);
    endfunction
	
    constraint clk_en { ce dist {0:=10,1:=90}; }
	  constraint input_valid { inp_valid dist {[1:3]:=90,0:=10};}
    constraint command {if(mode)
                       cmd inside {[0:10]};
                    else
                       cmd inside {[0:13]};}
 
endclass
