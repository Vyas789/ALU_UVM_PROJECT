class alu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(alu_scoreboard)

  // renamed FIFOs
  uvm_tlm_analysis_fifo #(alu_sequence_item) a_agt_fifo;
  uvm_tlm_analysis_fifo #(alu_sequence_item) p_agt_fifo;

  // interface handle for reference (reset/clk access)
  virtual alu_intf vif_ref;

  // sequence items (using new name alu_sequence_item)
  alu_sequence_item in_seq, ref_seq, mon_out_seq;

  int shift_value, got, inside_16;
  localparam int required_bits = $clog2(`n);

  // for CE latching logic
  logic [`n:0] prev_res;
  logic prev_oflow, prev_cout, prev_g, prev_l, prev_e, prev_err;

  function new(string name="alu_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a_agt_fifo = new("a_agt_fifo", this);
    p_agt_fifo = new("p_agt_fifo", this);

    if (!uvm_config_db#(virtual alu_intf)::get(this, "", "vif", vif_ref)) begin
      `uvm_fatal(get_full_name(), "Scoreboard didn't get interface handle");
    end
  endfunction

  // reference model computes expected outputs into ref_seq
  task reference_model_process(input alu_sequence_item in_seq, inout alu_sequence_item ref_seq);
  // debug/info
  `uvm_info(get_full_name(), $sformatf("Inside the ref model task at %0t", $time), UVM_LOW);

  // initialize outputs to 'z'
  ref_seq.res   = 9'bz;
  ref_seq.oflow = 1'bz;
  ref_seq.cout  = 1'bz;
  ref_seq.g     = 1'bz;
  ref_seq.l     = 1'bz;
  ref_seq.e     = 1'bz;
  ref_seq.err   = 1'bz;

  // If in reset -> keep outputs 'z'
  if (vif_ref.alu_ref_cb.rst == 1) begin
    // outputs already 'z' - nothing to do
  end else begin
    // not in reset
    if (in_seq.ce == 1) begin
      // CE == 1 path

      // First: check first-edge cases where inp_valid was 01 or 10 (possible multi-cycle)
      if ((in_seq.inp_valid == 2'b01) || (in_seq.inp_valid == 2'b10)) begin

        // only handle if command is from the two-operand set
        if ( ((in_seq.mode == 1) && (in_seq.cmd inside {0,1,2,3,8,9,10})) ||
             ((in_seq.mode == 0) && (in_seq.cmd inside {0,1,2,3,4,5,12,13})) ) begin

          `uvm_info(get_full_name(),
            $sformatf("Reference model got values at %0t: OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, INP_VALID=%0d, CMD=%0d",
                      $time, in_seq.opa, in_seq.opb, in_seq.cin, in_seq.ce, in_seq.mode, in_seq.inp_valid, in_seq.cmd),
            UVM_MEDIUM);

          got = 0;
          // if inp_valid already became 11, compute result
          if (in_seq.inp_valid == 2'b11) begin
            got = 1;
            if (in_seq.mode == 1) begin
              case (in_seq.cmd)
                `ADD: begin
                  `uvm_info(get_full_name(), "INSIDE 16 CYCLE ADD OPERATION", UVM_LOW);
                  ref_seq.res  = (in_seq.opa + in_seq.opb);
                  ref_seq.cout = ref_seq.res[`n] ? 1 : 0;
                end
                `SUB: begin
                  ref_seq.res  = (in_seq.opa - in_seq.opb);
                  ref_seq.oflow = (in_seq.opa < in_seq.opb) ? 1 : 0;
                end
                `ADD_CIN: begin
                  ref_seq.res  = (in_seq.opa + in_seq.opb + in_seq.cin);
                  ref_seq.cout = ref_seq.res[`n] ? 1 : 0;
                end
                `SUB_CIN: begin
                  ref_seq.res  = (in_seq.opa - in_seq.opb - in_seq.cin);
                  ref_seq.oflow = ((in_seq.opa < in_seq.opb) || ((in_seq.opa == in_seq.opb) && in_seq.cin)) ? 1 : 0;
                end
                `CMP: begin
                  ref_seq.e = (in_seq.opa == in_seq.opb) ? 1'b1 : 1'b0;
                  ref_seq.g = (in_seq.opa > in_seq.opb) ? 1'b1 : 1'b0;
                  ref_seq.l = (in_seq.opa < in_seq.opb) ? 1'b1 : 1'b0;
                end
                `INC_MUL: ref_seq.res = (in_seq.opa + 1) * (in_seq.opb + 1);
                `SHIFT_MUL: ref_seq.res = (in_seq.opa << 1) * (in_seq.opb);
                default: begin
                  ref_seq.res   = 9'bz;
                  ref_seq.oflow = 1'bz;
                  ref_seq.cout  = 1'bz;
                  ref_seq.err   = 1'bz;
                  ref_seq.g     = 1'bz;
                  ref_seq.l     = 1'bz;
                  ref_seq.e     = 1'bz;
                end
              endcase
            end else begin
              // mode == 0 logical two-operand ops
              case (in_seq.cmd)
                `AND:  ref_seq.res = {1'b0, (in_seq.opa & in_seq.opb)};
                `NAND: ref_seq.res = {1'b0, ~(in_seq.opa & in_seq.opb)};
                `OR:   ref_seq.res = {1'b0, (in_seq.opa | in_seq.opb)};
                `NOR:  ref_seq.res = {1'b0, ~(in_seq.opa | in_seq.opb)};
                `XOR:  ref_seq.res = {1'b0, (in_seq.opa ^ in_seq.opb)};
                `XNOR: ref_seq.res = {1'b0, ~(in_seq.opa ^ in_seq.opb)};
                `ROL_A_B: begin
                  shift_value = in_seq.opb[required_bits-1:0];
                  ref_seq.res = {1'b0, ((in_seq.opa << shift_value) | (in_seq.opa >> (`n - shift_value)))};
                  if (in_seq.opb > `n-1) ref_seq.err = 1;
                end
                `ROR_A_B: begin
                  shift_value = in_seq.opb[required_bits-1:0];
                  ref_seq.res = {1'b0, ((in_seq.opa >> shift_value) | (in_seq.opa << (`n - shift_value)))};
                  if (in_seq.opb > `n-1) ref_seq.err = 1;
                end
                default: begin
                  ref_seq.res   = 9'bz;
                  ref_seq.oflow = 1'bz;
                  ref_seq.cout  = 1'bz;
                  ref_seq.g     = 1'bz;
                  ref_seq.l     = 1'bz;
                  ref_seq.e     = 1'bz;
                  ref_seq.err   = 1'bz;
                end
              endcase
            end // end mode check
          end // end if inp_valid==11

          if (got != 1) ref_seq.err = 1'b1;

        end // end two-operand command set check

      end // end first-edge 01/10

      // single-operand immediate-result command sets (direct single-op)
      else if ((in_seq.mode == 1 && in_seq.cmd inside {4,5,6,7}) ||
               (in_seq.mode == 0 && in_seq.cmd inside {6,7,8,9,10,11})) begin

        if (in_seq.mode == 1) begin
          if (in_seq.inp_valid == 2'b01) begin
            case (in_seq.cmd)
              `INC_A: ref_seq.res = in_seq.opa + 1;
              `DEC_A: ref_seq.res = in_seq.opa - 1;
              default: begin
                ref_seq.res   = 9'bz;
                ref_seq.oflow = 1'bz;
                ref_seq.cout  = 1'bz;
                ref_seq.g     = 1'bz;
                ref_seq.l     = 1'bz;
                ref_seq.e     = 1'bz;
                ref_seq.err   = 1'bz;
              end
            endcase
          end else begin // inp_valid == 2'b10
            case (in_seq.cmd)
              `INC_B: ref_seq.res = in_seq.opb + 1;
              `DEC_B: ref_seq.res = in_seq.opb - 1;
              default: begin
                ref_seq.res   = 9'bz;
                ref_seq.oflow = 1'bz;
                ref_seq.cout  = 1'bz;
                ref_seq.g     = 1'bz;
                ref_seq.l     = 1'bz;
                ref_seq.e     = 1'bz;
                ref_seq.err   = 1'bz;
              end
            endcase
          end
        end else begin
          // mode == 0 single-operand logicals
          if (in_seq.inp_valid == 2'b01) begin
            case (in_seq.cmd)
              `NOT_A:  ref_seq.res = {1'b0, ~in_seq.opa};
              `SHR1_A: ref_seq.res = {1'b0, (in_seq.opa >> 1)};
              `SHL1_A: ref_seq.res = {1'b0, (in_seq.opa << 1)};
              default: begin
                ref_seq.res   = 9'bz;
                ref_seq.oflow = 1'bz;
                ref_seq.cout  = 1'bz;
                ref_seq.g     = 1'bz;
                ref_seq.l     = 1'bz;
                ref_seq.e     = 1'bz;
                ref_seq.err   = 1'bz;
              end
            endcase
          end else begin
            case (in_seq.cmd)
              `NOT_B:  ref_seq.res = {1'b0, ~in_seq.opb};
              `SHR1_B: ref_seq.res = {1'b0, (in_seq.opb >> 1)};
              `SHL1_B: ref_seq.res = {1'b0, (in_seq.opb << 1)};
              default: begin
                ref_seq.res   = 9'bz;
                ref_seq.oflow = 1'bz;
                ref_seq.cout  = 1'bz;
                ref_seq.g     = 1'bz;
                ref_seq.l     = 1'bz;
                ref_seq.e     = 1'bz;
                ref_seq.err   = 1'bz;
              end
            endcase
          end
        end // end single-op handling

      end // end else-if single-op sets

      // direct two-operand case when inp_valid==11 (immediate result)
      else if (in_seq.inp_valid == 2'b11) begin

        if (in_seq.mode == 1) begin
          case (in_seq.cmd)
            `ADD: begin
              `uvm_info(get_full_name(), $sformatf("Direct 11 ADD at %0t", $time), UVM_LOW);
              ref_seq.res  = (in_seq.opa + in_seq.opb);
              ref_seq.cout = ref_seq.res[`n] ? 1 : 0;
            end
            `SUB: begin
              ref_seq.res  = (in_seq.opa - in_seq.opb);
              ref_seq.oflow = (in_seq.opa < in_seq.opb) ? 1 : 0;
            end
            `ADD_CIN: begin
              ref_seq.res  = (in_seq.opa + in_seq.opb + in_seq.cin);
              ref_seq.cout = ref_seq.res[`n] ? 1 : 0;
            end
            `SUB_CIN: begin
              ref_seq.res  = (in_seq.opa - in_seq.opb - in_seq.cin);
              ref_seq.oflow = ((in_seq.opa < in_seq.opb) || ((in_seq.opa == in_seq.opb) && in_seq.cin)) ? 1 : 0;
            end
            `CMP: begin
              ref_seq.e = (in_seq.opa == in_seq.opb) ? 1'b1 : 1'b0;
              ref_seq.g = (in_seq.opa > in_seq.opb) ? 1'b1 : 1'b0;
              ref_seq.l = (in_seq.opa < in_seq.opb) ? 1'b1 : 1'b0;
            end
            `INC_MUL: ref_seq.res = (in_seq.opa + 1) * (in_seq.opb + 1);
            `SHIFT_MUL: ref_seq.res = (in_seq.opa << 1) * (in_seq.opb);
            `INC_A: ref_seq.res = in_seq.opa + 1;
            `DEC_A: ref_seq.res = in_seq.opa - 1;
            `INC_B: ref_seq.res = in_seq.opb + 1;
            `DEC_B: ref_seq.res = in_seq.opb - 1;
            default: begin
              ref_seq.res   = 9'bz;
              ref_seq.oflow = 1'bz;
              ref_seq.cout  = 1'bz;
              ref_seq.g     = 1'bz;
              ref_seq.l     = 1'bz;
              ref_seq.e     = 1'bz;
              ref_seq.err   = 1'bz;
            end
          endcase
        end else begin
          // mode == 0 logical direct 11
          case (in_seq.cmd)
            `AND:  ref_seq.res = {1'b0, (in_seq.opa & in_seq.opb)};
            `NAND: ref_seq.res = {1'b0, ~(in_seq.opa & in_seq.opb)};
            `OR:   ref_seq.res = {1'b0, (in_seq.opa | in_seq.opb)};
            `NOR:  ref_seq.res = {1'b0, ~(in_seq.opa | in_seq.opb)};
            `XOR:  ref_seq.res = {1'b0, (in_seq.opa ^ in_seq.opb)};
            `XNOR: ref_seq.res = {1'b0, ~(in_seq.opa ^ in_seq.opb)};
            `ROL_A_B: begin
              shift_value = in_seq.opb[required_bits-1:0];
              ref_seq.res = {1'b0, ((in_seq.opa << shift_value) | (in_seq.opa >> (`n - shift_value)))};
              if (in_seq.opb > `n-1) ref_seq.err = 1;
            end
            `ROR_A_B: begin
              shift_value = in_seq.opb[required_bits-1:0];
              ref_seq.res = {1'b0, ((in_seq.opa >> shift_value) | (in_seq.opa << (`n - shift_value)))};
              if (in_seq.opb > `n-1) ref_seq.err = 1;
            end
            `NOT_A: ref_seq.res = {1'b0, ~in_seq.opa};
            `NOT_B: ref_seq.res = {1'b0, ~in_seq.opb};
            `SHR1_A: ref_seq.res = {1'b0, (in_seq.opa >> 1)};
            `SHL1_A: ref_seq.res = {1'b0, (in_seq.opa << 1)};
            `SHR1_B: ref_seq.res = {1'b0, (in_seq.opb >> 1)};
            `SHL1_B: ref_seq.res = {1'b0, (in_seq.opb << 1)};
            default: begin
              ref_seq.res   = 9'bz;
              ref_seq.oflow = 1'bz;
              ref_seq.cout  = 1'bz;
              ref_seq.g     = 1'bz;
              ref_seq.l     = 1'bz;
              ref_seq.e     = 1'bz;
              ref_seq.err   = 1'bz;
            end
          endcase
        end

      end // end direct inp_valid==11

      // else for inp_valid == 00 (still inside CE==1)
      else begin
        ref_seq.res   = prev_res;
        ref_seq.oflow = prev_oflow;
        ref_seq.cout  = prev_cout;
        ref_seq.g     = prev_g;
        ref_seq.l     = prev_l;
        ref_seq.e     = prev_e;
        ref_seq.err   = prev_err;
      end

    end else begin
      // CE == 0 path: pass previous latched values
      ref_seq.res   = prev_res;
      ref_seq.oflow = prev_oflow;
      ref_seq.cout  = prev_cout;
      ref_seq.g     = prev_g;
      ref_seq.l     = prev_l;
      ref_seq.e     = prev_e;
      ref_seq.err   = prev_err;
    end // end CE if

  end // end reset else

  // final debug display
  `uvm_info(get_full_name(),
    $sformatf("Reference model putting values to scoreboard at %0t : OPA=%0d, OPB=%0d, CIN=%0d, CE=%0d, MODE=%0d, CMD=%0d, INP_VALID=%0d, RES=%0d, ERR=%0d, COUT=%0d, OFLOW=%0d, G=%0d, L=%0d, E=%0d",
              $time, in_seq.opa, in_seq.opb, in_seq.cin, in_seq.ce, in_seq.mode, in_seq.cmd, in_seq.inp_valid,
              ref_seq.res, ref_seq.err, ref_seq.cout, ref_seq.oflow, ref_seq.g, ref_seq.l, ref_seq.e),
    UVM_MEDIUM);

endtask


  // main scoreboard run_phase: consume actuators, run reference model, compare with monitor
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    repeat (1) @(vif_ref.alu_ref_cb);

    forever begin
      $display("Inside forever begin loop of scoreboard at %0t", $time);

      // get item from active agent FIFO (renamed)
      a_agt_fifo.get(in_seq);
      `uvm_info("DRV2REF", $sformatf("Got: %s", in_seq.sprint()), UVM_LOW);

      // create a fresh ref_seq item and call reference model
      ref_seq = alu_sequence_item::type_id::create("ref_seq", this);
      $display("Giving call to the reference model task at %0t", $time);
      reference_model_process(in_seq, ref_seq); // compute reference outputs
      $display("Reference model gave result as: %0d", ref_seq.res);

      // latch previous outputs for CE/00 handling
      prev_res    = ref_seq.res;
      prev_err    = ref_seq.err;
      prev_oflow  = ref_seq.oflow;
      prev_cout   = ref_seq.cout;
      prev_g      = ref_seq.g;
      prev_l      = ref_seq.l;
      prev_e      = ref_seq.e;

      // get corresponding monitor item from passive agent FIFO (renamed)
      p_agt_fifo.get(mon_out_seq);
      `uvm_info("MON2SCB", $sformatf("Got: %s", mon_out_seq.sprint()), UVM_LOW);

      // Comparisons and UVM reporting
      if (ref_seq.res === mon_out_seq.res) begin
        `uvm_info(get_full_name(), $sformatf("RES Comparison Pass: REF=%0d || MON=%0d", ref_seq.res, mon_out_seq.res), UVM_LOW);
      end else begin
        `uvm_error(get_full_name(), $sformatf("RES Comparison Fail: REF=%0d || MON=%0d", ref_seq.res, mon_out_seq.res));
      end

      if (ref_seq.cout === mon_out_seq.cout) begin
        `uvm_info(get_full_name(), $sformatf("COUT Comparison Pass: REF=%0d || MON=%0d", ref_seq.cout, mon_out_seq.cout), UVM_LOW);
      end else begin
        `uvm_error(get_full_name(), $sformatf("COUT Comparison Fail: REF=%0d || MON=%0d", ref_seq.cout, mon_out_seq.cout));
      end

      if (ref_seq.oflow === mon_out_seq.oflow) begin
        `uvm_info(get_full_name(), $sformatf("OFLOW Comparison Pass: REF=%0d || MON=%0d", ref_seq.oflow, mon_out_seq.oflow), UVM_LOW);
      end else begin
        `uvm_error(get_full_name(), $sformatf("OFLOW Comparison Fail: REF=%0d || MON=%0d", ref_seq.oflow, mon_out_seq.oflow));
      end

      if (ref_seq.err === mon_out_seq.err) begin
        `uvm_info(get_full_name(), $sformatf("ERR Comparison Pass: REF=%0d || MON=%0d", ref_seq.err, mon_out_seq.err), UVM_LOW);
      end else begin
        `uvm_error(get_full_name(), $sformatf("ERR Comparison Fail: REF=%0d || MON=%0d", ref_seq.err, mon_out_seq.err));
      end

      if (ref_seq.g === mon_out_seq.g) begin
        `uvm_info(get_full_name(), $sformatf("G Comparison Pass: REF=%0d || MON=%0d", ref_seq.g, mon_out_seq.g), UVM_LOW);
      end else begin
        `uvm_error(get_full_name(), $sformatf("G Comparison Fail: REF=%0d || MON=%0d", ref_seq.g, mon_out_seq.g));
      end

      if (ref_seq.l === mon_out_seq.l) begin
        `uvm_info(get_full_name(), $sformatf("L Comparison Pass: REF=%0d || MON=%0d", ref_seq.l, mon_out_seq.l), UVM_LOW);
      end else begin
        `uvm_error(get_full_name(), $sformatf("L Comparison Fail: REF=%0d || MON=%0d", ref_seq.l, mon_out_seq.l));
      end

      if (ref_seq.e === mon_out_seq.e) begin
        `uvm_info(get_full_name(), $sformatf("E Comparison Pass: REF=%0d || MON=%0d", ref_seq.e, mon_out_seq.e), UVM_LOW);
      end else begin
        `uvm_error(get_full_name(), $sformatf("E Comparison Fail: REF=%0d || MON=%0d", ref_seq.e, mon_out_seq.e));
      end

    end // forever
  endtask

endclass
