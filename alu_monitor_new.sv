class alu_monitor extends uvm_monitor;
  `uvm_component_utils(alu_monitor)

  // standardized names
  virtual alu_intf          			mon_vif;
  uvm_analysis_port#(alu_sequence_item) mon_port;
  alu_sequence_item                     mon_req;

  function new(string name="alu_monitor", uvm_component parent = null);
    super.new(name, parent);
    mon_port = new("mon_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual alu_intf)::get(this, " ", "vif", mon_vif)) begin
      `uvm_fatal(get_full_name(), "Monitor didn't get interface handle");
    end
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(get_full_name(), "Monitor run_phase started", UVM_MEDIUM);

    // allow DUT/clock to settle
    repeat (4) @(mon_vif.alu_mon_cb);

    forever begin
      @(mon_vif.alu_mon_cb);
	mon_req = alu_sequence_item::type_id::create("mon_req", this);
			
      // small pre-delay logic (matching your original intent)
      if (mon_vif.alu_mon_cb.inp_valid inside {0,1,2,3} &&
          ((mon_vif.alu_mon_cb.mode == 1 && mon_vif.alu_mon_cb.cmd inside {0,1,2,3,4,5,6,7,8}) ||
           (mon_vif.alu_mon_cb.mode == 0 && mon_vif.alu_mon_cb.cmd inside {0,1,2,3,4,5,6,7,8,9,10,11,12,13})))
        repeat (1) @(mon_vif.alu_mon_cb);
      else if (mon_vif.alu_mon_cb.inp_valid == 2'b11 &&
               (mon_vif.alu_mon_cb.mode == 1 && mon_vif.alu_mon_cb.cmd inside {9,10}))
        repeat (2) @(mon_vif.alu_mon_cb);

      // --- branch: first-edge 01 or 10 cases (two-input candidates) ---
      if ((mon_vif.alu_mon_cb.inp_valid == 2'b01) || (mon_vif.alu_mon_cb.inp_valid == 2'b10)) begin

        if ( ((mon_vif.alu_mon_cb.mode == 1) && (mon_vif.alu_mon_cb.cmd inside {0,1,2,3,8,9,10})) ||
             ((mon_vif.alu_mon_cb.mode == 0) && (mon_vif.alu_mon_cb.cmd inside {0,1,2,3,4,5,12,13})) ) begin

          // scan for up to 16 clocks to see if inp_valid becomes 11 (two-operand capture)
          for (int j = 0; j < 16; j++) begin
            @(mon_vif.alu_mon_cb);

            if (mon_vif.alu_mon_cb.inp_valid == 2'b11) begin

              // 2-cycle multiply case (mode==1 & cmd {9,10})
              if ((mon_vif.alu_mon_cb.mode == 1) && (mon_vif.alu_mon_cb.cmd inside {9,10})) begin
                repeat (2) @(mon_vif.alu_mon_cb);

                `uvm_info(get_full_name(),
                  $sformatf("Virtual interface values from DUT to monitor at %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, INP_VALID=%0d, CMD=%0d, RES=%0d, OFLOW=%0d, COUT=%0d, ERR=%0d, G=%0d, L=%0d, E=%0d",
                            $time,
                            mon_vif.alu_mon_cb.opa, mon_vif.alu_mon_cb.opb, mon_vif.alu_mon_cb.cin, mon_vif.alu_mon_cb.ce,
                            mon_vif.alu_mon_cb.mode, mon_vif.alu_mon_cb.inp_valid, mon_vif.alu_mon_cb.cmd,
                            mon_vif.alu_mon_cb.res, mon_vif.alu_mon_cb.oflow, mon_vif.alu_mon_cb.cout,
                            mon_vif.alu_mon_cb.err, mon_vif.alu_mon_cb.g, mon_vif.alu_mon_cb.l, mon_vif.alu_mon_cb.e),
                  UVM_MEDIUM);

                // create fresh item to avoid handle reuse
                //mon_req = alu_seq_item::type_id::create("mon_req", this);

                // populate outputs
                mon_req.res    = mon_vif.alu_mon_cb.res;
                mon_req.err    = mon_vif.alu_mon_cb.err;
                mon_req.g      = mon_vif.alu_mon_cb.g;
                mon_req.l      = mon_vif.alu_mon_cb.l;
                mon_req.e      = mon_vif.alu_mon_cb.e;
                mon_req.oflow  = mon_vif.alu_mon_cb.oflow;
                mon_req.cout   = mon_vif.alu_mon_cb.cout;

                // populate inputs (for reference/comparison)
                mon_req.opa       = mon_vif.alu_mon_cb.opa;
                mon_req.opb       = mon_vif.alu_mon_cb.opb;
                mon_req.cin       = mon_vif.alu_mon_cb.cin;
                mon_req.ce        = mon_vif.alu_mon_cb.ce;
                mon_req.mode      = mon_vif.alu_mon_cb.mode;
                mon_req.cmd       = mon_vif.alu_mon_cb.cmd;
                mon_req.inp_valid = mon_vif.alu_mon_cb.inp_valid;

                mon_port.write(mon_req);

                `uvm_info(get_full_name(),
                  $sformatf("Monitor put values from DUT to scoreboard @ %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, CMD=%0d, INP_VALID=%0d, RES=%0d, ERR=%0d, OFLOW=%0d, G=%0d, L=%0d, E=%0d",
                            $time,
                            mon_vif.alu_mon_cb.opa, mon_vif.alu_mon_cb.opb, mon_vif.alu_mon_cb.cin, mon_vif.alu_mon_cb.ce,
                            mon_vif.alu_mon_cb.mode, mon_vif.alu_mon_cb.cmd, mon_vif.alu_mon_cb.inp_valid,
                            mon_vif.alu_mon_cb.res, mon_vif.alu_mon_cb.err, mon_vif.alu_mon_cb.oflow,
                            mon_vif.alu_mon_cb.g, mon_vif.alu_mon_cb.l, mon_vif.alu_mon_cb.e),
                  UVM_MEDIUM);

              end else begin
                // other two-operand op where result available after 1 extra cycle
                repeat (1) @(mon_vif.alu_mon_cb);

                `uvm_info(get_full_name(),
                  $sformatf("Virtual interface values from DUT to monitor at %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, INP_VALID=%0d, CMD=%0d, RES=%0d, OFLOW=%0d, COUT=%0d, ERR=%0d, G=%0d, L=%0d, E=%0d",
                            $time,
                            mon_vif.alu_mon_cb.opa, mon_vif.alu_mon_cb.opb, mon_vif.alu_mon_cb.cin, mon_vif.alu_mon_cb.ce,
                            mon_vif.alu_mon_cb.mode, mon_vif.alu_mon_cb.inp_valid, mon_vif.alu_mon_cb.cmd,
                            mon_vif.alu_mon_cb.res, mon_vif.alu_mon_cb.oflow, mon_vif.alu_mon_cb.cout,
                            mon_vif.alu_mon_cb.err, mon_vif.alu_mon_cb.g, mon_vif.alu_mon_cb.l, mon_vif.alu_mon_cb.e),
                  UVM_MEDIUM);

                //mon_req = alu_seq_item::type_id::create("mon_req", this);

                mon_req.res    = mon_vif.alu_mon_cb.res;
                mon_req.err    = mon_vif.alu_mon_cb.err;
                mon_req.g      = mon_vif.alu_mon_cb.g;
                mon_req.l      = mon_vif.alu_mon_cb.l;
                mon_req.e      = mon_vif.alu_mon_cb.e;
                mon_req.oflow  = mon_vif.alu_mon_cb.oflow;
                mon_req.cout   = mon_vif.alu_mon_cb.cout;

                mon_req.opa       = mon_vif.alu_mon_cb.opa;
                mon_req.opb       = mon_vif.alu_mon_cb.opb;
                mon_req.cin       = mon_vif.alu_mon_cb.cin;
                mon_req.ce        = mon_vif.alu_mon_cb.ce;
                mon_req.mode      = mon_vif.alu_mon_cb.mode;
                mon_req.cmd       = mon_vif.alu_mon_cb.cmd;
                mon_req.inp_valid = mon_vif.alu_mon_cb.inp_valid;

                mon_port.write(mon_req);

                `uvm_info(get_full_name(),
                  $sformatf("Monitor put values from DUT to scoreboard @ %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, CMD=%0d, INP_VALID=%0d, RES=%0d, ERR=%0d, OFLOW=%0d, G=%0d, L=%0d, E=%0d",
                            $time,
                            mon_vif.alu_mon_cb.opa, mon_vif.alu_mon_cb.opb, mon_vif.alu_mon_cb.cin, mon_vif.alu_mon_cb.ce,
                            mon_vif.alu_mon_cb.mode, mon_vif.alu_mon_cb.cmd, mon_vif.alu_mon_cb.inp_valid,
                            mon_vif.alu_mon_cb.res, mon_vif.alu_mon_cb.err, mon_vif.alu_mon_cb.oflow,
                            mon_vif.alu_mon_cb.g, mon_vif.alu_mon_cb.l, mon_vif.alu_mon_cb.e),
                  UVM_MEDIUM);

              end // else (non-mul)
              break;
            end else begin
              // still waiting for inp_valid == 11, continue scanning
              continue;
            end
          end // for j
        end // if cmd inside two-operand set

        // special single-op direct-case sets (immediate single-op result)
        else if ((mon_vif.alu_mon_cb.mode == 1 && mon_vif.alu_mon_cb.cmd inside {4,5,6,7}) ||
                 (mon_vif.alu_mon_cb.mode == 0 && mon_vif.alu_mon_cb.cmd inside {6,7,8,9,10,11})) begin

          `uvm_info(get_full_name(),
            $sformatf("Virtual interface values from DUT to monitor (direct single-op) at %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, INP_VALID=%0d, CMD=%0d, RES=%0d, OFLOW=%0d, COUT=%0d, ERR=%0d, G=%0d, L=%0d, E=%0d",
                      $time,
                      mon_vif.alu_mon_cb.opa, mon_vif.alu_mon_cb.opb, mon_vif.alu_mon_cb.cin, mon_vif.alu_mon_cb.ce,
                      mon_vif.alu_mon_cb.mode, mon_vif.alu_mon_cb.inp_valid, mon_vif.alu_mon_cb.cmd,
                      mon_vif.alu_mon_cb.res, mon_vif.alu_mon_cb.oflow, mon_vif.alu_mon_cb.cout,
                      mon_vif.alu_mon_cb.err, mon_vif.alu_mon_cb.g, mon_vif.alu_mon_cb.l, mon_vif.alu_mon_cb.e),
            UVM_MEDIUM);

          // create, populate, write
          //mon_req = alu_seq_item::type_id::create("mon_req", this);

          mon_req.res    = mon_vif.alu_mon_cb.res;
          mon_req.err    = mon_vif.alu_mon_cb.err;
          mon_req.g      = mon_vif.alu_mon_cb.g;
          mon_req.l      = mon_vif.alu_mon_cb.l;
          mon_req.e      = mon_vif.alu_mon_cb.e;
          mon_req.oflow  = mon_vif.alu_mon_cb.oflow;
          mon_req.cout   = mon_vif.alu_mon_cb.cout;

          mon_req.opa       = mon_vif.alu_mon_cb.opa;
          mon_req.opb       = mon_vif.alu_mon_cb.opb;
          mon_req.cin       = mon_vif.alu_mon_cb.cin;
          mon_req.ce        = mon_vif.alu_mon_cb.ce;
          mon_req.mode      = mon_vif.alu_mon_cb.mode;
          mon_req.cmd       = mon_vif.alu_mon_cb.cmd;
          mon_req.inp_valid = mon_vif.alu_mon_cb.inp_valid;

          mon_port.write(mon_req);

          `uvm_info(get_full_name(),
            $sformatf("Monitor put values from DUT to scoreboard (direct single-op) @ %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, CMD=%0d, INP_VALID=%0d, RES=%0d, ERR=%0d, OFLOW=%0d, G=%0d, L=%0d, E=%0d",
                      $time,
                      mon_vif.alu_mon_cb.opa, mon_vif.alu_mon_cb.opb, mon_vif.alu_mon_cb.cin, mon_vif.alu_mon_cb.ce,
                      mon_vif.alu_mon_cb.mode, mon_vif.alu_mon_cb.cmd, mon_vif.alu_mon_cb.inp_valid,
                      mon_vif.alu_mon_cb.res, mon_vif.alu_mon_cb.err, mon_vif.alu_mon_cb.oflow,
                      mon_vif.alu_mon_cb.g, mon_vif.alu_mon_cb.l, mon_vif.alu_mon_cb.e),
            UVM_MEDIUM);

        end // else-if single-op direct

      end // if first-edge 01/10

      // --- else: direct 11 or 00 cases (capture immediately) ---
      else begin
        `uvm_info(get_full_name(),
          $sformatf("Virtual interface values from DUT to monitor at %0t (direct capture): OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, INP_VALID=%0d, CMD=%0d, RES=%0d, OFLOW=%0d, COUT=%0d, ERR=%0d, G=%0d, L=%0d, E=%0d",
                    $time,
                    mon_vif.alu_mon_cb.opa, mon_vif.alu_mon_cb.opb, mon_vif.alu_mon_cb.cin, mon_vif.alu_mon_cb.ce,
                    mon_vif.alu_mon_cb.mode, mon_vif.alu_mon_cb.inp_valid, mon_vif.alu_mon_cb.cmd,
                    mon_vif.alu_mon_cb.res, mon_vif.alu_mon_cb.oflow, mon_vif.alu_mon_cb.cout,
                    mon_vif.alu_mon_cb.err, mon_vif.alu_mon_cb.g, mon_vif.alu_mon_cb.l, mon_vif.alu_mon_cb.e),
          UVM_MEDIUM);

        //mon_req = alu_seq_item::type_id::create("mon_req", this);

        mon_req.res    = mon_vif.alu_mon_cb.res;
        mon_req.err    = mon_vif.alu_mon_cb.err;
        mon_req.g      = mon_vif.alu_mon_cb.g;
        mon_req.l      = mon_vif.alu_mon_cb.l;
        mon_req.e      = mon_vif.alu_mon_cb.e;
        mon_req.oflow  = mon_vif.alu_mon_cb.oflow;
        mon_req.cout   = mon_vif.alu_mon_cb.cout;

        mon_req.opa       = mon_vif.alu_mon_cb.opa;
        mon_req.opb       = mon_vif.alu_mon_cb.opb;
        mon_req.cin       = mon_vif.alu_mon_cb.cin;
        mon_req.ce        = mon_vif.alu_mon_cb.ce;
        mon_req.mode      = mon_vif.alu_mon_cb.mode;
        mon_req.cmd       = mon_vif.alu_mon_cb.cmd;
        mon_req.inp_valid = mon_vif.alu_mon_cb.inp_valid;

        mon_port.write(mon_req);

        `uvm_info(get_full_name(),
          $sformatf("Monitor put values from DUT to scoreboard @ %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, CMD=%0d, INP_VALID=%0d, RES=%0d, ERR=%0d, OFLOW=%0d, G=%0d, L=%0d, E=%0d",
                    $time,
                    mon_vif.alu_mon_cb.opa, mon_vif.alu_mon_cb.opb, mon_vif.alu_mon_cb.cin, mon_vif.alu_mon_cb.ce,
                    mon_vif.alu_mon_cb.mode, mon_vif.alu_mon_cb.cmd, mon_vif.alu_mon_cb.inp_valid,
                    mon_vif.alu_mon_cb.res, mon_vif.alu_mon_cb.err, mon_vif.alu_mon_cb.oflow,
                    mon_vif.alu_mon_cb.g, mon_vif.alu_mon_cb.l, mon_vif.alu_mon_cb.e),
          UVM_MEDIUM);

      end // else direct capture

    end // forever
  endtask

endclass
