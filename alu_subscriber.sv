class alu_subscriber extends uvm_subscriber#(alu_sequence_item);
  `uvm_component_utils(alu_subscriber);

  // analysis imp declarations (renamed)
  `uvm_analysis_imp_decl(_a_mon)
  `uvm_analysis_imp_decl(_p_mon)

  // implementation handles (renamed) - keep your project's imp typedefs if used
  uvm_analysis_imp_a_mon#(alu_sequence_item, alu_subscriber) a_sub_imp;
  uvm_analysis_imp_p_mon#(alu_sequence_item, alu_subscriber) p_sub_imp;

  // sequence items / handles (renamed)
  alu_sequence_item a_mon_seq, p_mon_seq;

  // coverage numbers
  real a_mon_coverage, p_mon_coverage;

  // --- covergroups renamed ---
  covergroup a_mon_cov;
    INPUT_VALID: coverpoint a_mon_seq.inp_valid {
      bins valid_opa  = {2'b01};
      bins valid_opb  = {2'b10};
      bins valid_both = {2'b11};
      bins invalid    = {2'b00};
    }
    COMMAND: coverpoint a_mon_seq.cmd {
      bins arithmetic[]         = {[0:10]};
      bins logical[]            = {[0:13]};
      bins arithmetic_invalid[] = {[11:15]};
      bins logical_invalid[]    = {14,15};
    }
    MODE: coverpoint a_mon_seq.mode {
      bins arithmetic = {1};
      bins logical    = {0};
    }
    CLOCK_ENABLE: coverpoint a_mon_seq.ce {
      bins clock_enable_valid   = {1};
      bins clock_enable_invalid = {0};
    }
    OPERAND_A: coverpoint a_mon_seq.opa { bins opa[] = {[0:(2**`n)-1]}; }
    OPERAND_B: coverpoint a_mon_seq.opb { bins opb[] = {[0:(2**`n)-1]}; }
    CARRY_IN: coverpoint a_mon_seq.cin {
      bins cin_high = {1};
      bins cin_low  = {0};
    }
    MODE_CMD_: cross MODE, COMMAND;
  endgroup

  covergroup p_mon_cov;
    RESULT_CHECK: coverpoint p_mon_seq.res {
      bins result[] = {[0:(2**`n)-1]};
      option.auto_bin_max = 8;
    }
    CARR_OUT: coverpoint p_mon_seq.cout {
      bins cout_active   = {1};
      bins cout_inactive = {0};
    }
    OVERFLOW: coverpoint p_mon_seq.oflow {
      bins oflow_active   = {1};
      bins oflow_inactive = {0};
    }
    ERROR: coverpoint p_mon_seq.err { bins error_active = {1}; }
    GREATER: coverpoint p_mon_seq.g { bins greater_active = {1}; }
    EQUAL: coverpoint p_mon_seq.e { bins equal_active = {1}; }
    LESSER: coverpoint p_mon_seq.l { bins lesser_active = {1}; }
  endgroup

  // -----------------------
  function new(string name="alu_subscriber", uvm_component parent = null);
    super.new(name, parent);
    a_sub_imp = new("drv2sub_imp", this);
    p_sub_imp = new("mon2sub_imp", this);

    // instantiate covergroup objects (keeps same naming style as before)
    a_mon_cov = new();
    p_mon_cov = new();
  endfunction

  // default write (not used; base class has one)
  function void write(alu_sequence_item t);
    // intentionally empty (not used)
  endfunction

  // analysis callbacks renamed to match a_mon / p_mon
  function void write_a_mon(alu_sequence_item t);
    a_mon_seq = t;
    a_mon_cov.sample();
  endfunction

  function void write_p_mon(alu_sequence_item t);
    p_mon_seq = t;
    p_mon_cov.sample();
  endfunction

  // coverage extraction
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    a_mon_coverage = a_mon_cov.get_coverage();
    p_mon_coverage = p_mon_cov.get_coverage();
  endfunction

  // report
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),
      $sformatf("[INPUT] Coverage ------> %0.2f%%", a_mon_coverage), UVM_MEDIUM);
    `uvm_info(get_type_name(),
      $sformatf("[OUTPUT] Coverage -----> %0.2f%%", p_mon_coverage), UVM_MEDIUM);
  endfunction

endclass
