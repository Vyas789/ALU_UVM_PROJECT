
class alu_driver extends uvm_driver #(alu_sequence_item);

    `uvm_component_utils(alu_driver)
    virtual alu_intf drv_vif;
   // uvm_analysis_port #(alu_sequence_item) item_sent_port;
		alu_sequence_item drv_req;
 	 	//alu_sequence_item temp;  

  function new(string name ="alu_driver", uvm_component parent=null);
        super.new(name, parent);
    		//item_sent_port = new("item_sent_port",this);
    		//temp=alu_sequence_item::type_id::create("temp",this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
      if(!uvm_config_db#(virtual alu_intf)::get(this, " ", "vif", drv_vif))
          `uvm_info(get_full_name(),"did'nt recieve the virtual interface",UVM_NONE);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
     	 super.run_phase(phase);
				repeat(3)@(drv_vif.alu_drv_cb);
      	forever begin
          `uvm_info(get_full_name(),"starting the driver",UVM_NONE);
        seq_item_port.get_next_item(drv_req);
          `uvm_info(get_full_name(),"got th next sequence item",UVM_NONE);
           drive(drv_req);
          `uvm_info(get_full_name(),"drove the sequence item to the virtual interface",UVM_NONE);
        seq_item_port.item_done();
          `uvm_info(get_full_name(),"item done ",UVM_NONE);
        end
    endtask
    
     task drive(alu_sequence_item drv_req);
       @(drv_vif.alu_drv_cb);
         if(drv_req.inp_valid==2'b01 || drv_req.inp_valid==2'b10)
            begin
               if(((drv_req.mode==1) && (drv_req.cmd inside {0,1,2,3,8,9,10})) || ((drv_req.mode==0) && (drv_req.cmd inside {0,1,2,3,4,5,12,13})))
                 begin
         	drv_vif.alu_drv_cb.opa <= drv_req.opa;
		    	drv_vif.alu_drv_cb.opb <= drv_req.opb;
	        drv_vif.alu_drv_cb.cin <= drv_req.cin;
		    	drv_vif.alu_drv_cb.ce <= drv_req.ce;
		    	drv_vif.alu_drv_cb.cmd <= drv_req.cmd;
		    	drv_vif.alu_drv_cb.mode <= drv_req.mode;
		    	drv_vif.alu_drv_cb.inp_valid <= drv_req.inp_valid;
		    	//item_sent_port.write(drv_req);
                   `uvm_info(get_full_name(),
          $sformatf("Driver drived values normally at first edge of 16 cycle at %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, CMD=%0d, INP_VALID=%0d", $time, drv_req.opa, drv_req.opb, drv_req.cin, drv_req.ce, drv_req.mode, drv_req.cmd, drv_req.inp_valid),
UVM_MEDIUM);

	    for(int j=0;j<16;j++)
                begin
                 @(drv_vif.alu_drv_cb);
                  if (drv_req.inp_valid == 2'b11) 
		    begin
    			drv_vif.alu_drv_cb.opa       <= drv_req.opa;
   		    drv_vif.alu_drv_cb.opb       <= drv_req.opb;
    			drv_vif.alu_drv_cb.cin       <= drv_req.cin;
   		  	drv_vif.alu_drv_cb.ce        <= drv_req.ce;
    			drv_vif.alu_drv_cb.cmd       <= drv_req.cmd;
    			drv_vif.alu_drv_cb.mode      <= drv_req.mode;
    			drv_vif.alu_drv_cb.inp_valid <= drv_req.inp_valid;
		    	//item_sent_port.write(drv_req);
    			break;
					`uvm_info(get_full_name(),
          $sformatf("Driver driving values because it got 11 at %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, CMD=%0d, INP_VALID=%0d", $time, drv_req.opa, drv_req.opb, drv_req.cin, drv_req.ce, drv_req.mode, drv_req.cmd, drv_req.inp_valid),
    UVM_MEDIUM);
			end 
      else
       begin
      drv_req.mode.rand_mode(0);
			drv_req.cmd.rand_mode(0);
			drv_req.ce.rand_mode(0);
			drv_req.randomize();
			`uvm_info(get_full_name(),
          $sformatf("Driver driving constrained values because it didn't get 11 at %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, CMD=%0d, INP_VALID=%0d", $time, drv_req.opa, drv_req.opb, drv_req.cin, drv_req.ce, drv_req.mode, drv_req.cmd, drv_req.inp_valid),
   UVM_MEDIUM);
       end
      end //end of for loop
     end //two input cmd
   else  // for single input cmd
		begin
			drv_vif.alu_drv_cb.opa <= drv_req.opa;
			drv_vif.alu_drv_cb.opb <= drv_req.opb;
			drv_vif.alu_drv_cb.cin <= drv_req.cin;
			drv_vif.alu_drv_cb.ce <= drv_req.ce;
			drv_vif.alu_drv_cb.cmd <= drv_req.cmd;
			drv_vif.alu_drv_cb.mode <= drv_req.mode;
			drv_vif.alu_drv_cb.inp_valid <= drv_req.inp_valid;
			//item_sent_port.write(drv_req);
			`uvm_info(get_full_name(),
          $sformatf("Driver driving values because it got single operand operation at %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, CMD=%0d, INP_VALID=%0d",$time, drv_req.opa, drv_req.opb, drv_req.cin, drv_req.ce, drv_req.mode, drv_req.cmd, drv_req.inp_valid),UVM_MEDIUM);

		 end
	  end
	 else // for in_valid is 00 or 11 
		begin
			drv_vif.alu_drv_cb.opa <= drv_req.opa;
			drv_vif.alu_drv_cb.opb <= drv_req.opb;
			drv_vif.alu_drv_cb.cin <= drv_req.cin;
			drv_vif.alu_drv_cb.ce <= drv_req.ce;
			drv_vif.alu_drv_cb.cmd <= drv_req.cmd;
			drv_vif.alu_drv_cb.mode <= drv_req.mode;
			drv_vif.alu_drv_cb.inp_valid <= drv_req.inp_valid;
			//item_sent_port.write(drv_req);
			`uvm_info(get_full_name(),
          $sformatf("Driver driving values because it got 11 directly at first edge without waiting for 16 cycles at %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, CMD=%0d, INP_VALID=%0d", $time, drv_req.opa, drv_req.opb, drv_req.cin, drv_req.ce, drv_req.mode, drv_req.cmd, drv_req.inp_valid),
          UVM_MEDIUM);

		end
	
if(drv_req.inp_valid inside {0,1,2,3} && ((drv_req.mode==1 && drv_req.cmd inside {0,1,2,3,4,5,6,7,8})|| (drv_req.mode==0 &&drv_req.cmd inside {0,1,2,3,4,5,6,7,8,9,10,11,12,13})))
         repeat (1) @(drv_vif.alu_drv_cb);
       else if(drv_req.inp_valid==3 && (drv_req.mode==1 && drv_req.cmd inside {9,10}))
         repeat(2)@(drv_vif.alu_drv_cb);
      endtask
endclass
