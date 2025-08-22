//------------------------------------------------------------------------------
// Base test (renamed to alu_test)  runs a default sequence
//------------------------------------------------------------------------------
class alu_test extends uvm_test;
  `uvm_component_utils(alu_test)

  alu_environment env;

  function new(string name = "alu_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = alu_environment::type_id::create("env", this);
  endfunction

  // Base run_phase runs a default sequence (alu_sequence)
  virtual task run_phase(uvm_phase phase);
    alu_sequence seq;

    phase.raise_objection(this);
      seq = alu_sequence::type_id::create("seq", this);
      `uvm_info(get_type_name(), $sformatf("Base test starting default sequence %s on %s", seq.get_type_name(), env.active_agt.seqr.get_full_name()), UVM_LOW);
      seq.start(env.active_agt.seqr);
    phase.drop_objection(this);

    `uvm_info(get_type_name(), "Base test finished default sequence", UVM_LOW);
  endtask
endclass

//------------------------------------------------------------------------------
// alu_single_operand_logical_test
//------------------------------------------------------------------------------
// Runs the base seq first (via super.run_phase), then its own sequence
class alu_single_operand_logical_test extends alu_test;
  `uvm_component_utils(alu_single_operand_logical_test)

  alu_single_operand_logical seq;

  function new(string name = "alu_single_operand_logical_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    // run base test sequence first
    super.run_phase(phase);

    // then run this test's sequence
    phase.raise_objection(this);
      seq = alu_single_operand_logical::type_id::create("seq", this);
      `uvm_info(get_type_name(), $sformatf("Starting seq %s on %s", seq.get_type_name(), env.active_agt.seqr.get_full_name()), UVM_LOW);
      seq.start(env.active_agt.seqr);
    phase.drop_objection(this);

    `uvm_info(get_type_name(), "alu_single_operand_logical_test finished", UVM_LOW);
  endtask
endclass

//------------------------------------------------------------------------------
// alu_single_operand_arithmetic_test
//------------------------------------------------------------------------------
class alu_single_operand_arithmetic_test extends alu_test;
  `uvm_component_utils(alu_single_operand_arithmetic_test)

  alu_single_operand_arithmetic seq;

  function new(string name = "alu_single_operand_arithmetic_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    // run base seq
    super.run_phase(phase);

    // run test seq
    phase.raise_objection(this);
      seq = alu_single_operand_arithmetic::type_id::create("seq", this);
      `uvm_info(get_type_name(), $sformatf("Starting seq %s on %s", seq.get_type_name(), env.active_agt.seqr.get_full_name()), UVM_LOW);
      seq.start(env.active_agt.seqr);
    phase.drop_objection(this);

    `uvm_info(get_type_name(), "alu_single_operand_arithmetic_test finished", UVM_LOW);
  endtask
endclass

//------------------------------------------------------------------------------
// alu_multiple_operand_arithmetic_test
//------------------------------------------------------------------------------
class alu_multiple_operand_arithmetic_test extends alu_test;
  `uvm_component_utils(alu_multiple_operand_arithmetic_test)

  alu_multiple_operand_arithmetic seq;

  function new(string name = "alu_multiple_operand_arithmetic_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    // run base seq
    super.run_phase(phase);

    // run test seq
    phase.raise_objection(this);
      seq = alu_multiple_operand_arithmetic::type_id::create("seq", this);
      `uvm_info(get_type_name(), $sformatf("Starting seq %s on %s", seq.get_type_name(), env.active_agt.seqr.get_full_name()), UVM_LOW);
      seq.start(env.active_agt.seqr);
    phase.drop_objection(this);

    `uvm_info(get_type_name(), "alu_multiple_operand_arithmetic_test finished", UVM_LOW);
  endtask
endclass

//------------------------------------------------------------------------------
// alu_multiple_operand_logical_test
//------------------------------------------------------------------------------
class alu_multiple_operand_logical_test extends alu_test;
  `uvm_component_utils(alu_multiple_operand_logical_test)

  alu_multiple_operand_logical seq;

  function new(string name = "alu_multiple_operand_logical_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    // run base seq
    super.run_phase(phase);

    // run test seq
    phase.raise_objection(this);
      seq = alu_multiple_operand_logical::type_id::create("seq", this);
      `uvm_info(get_type_name(), $sformatf("Starting seq %s on %s", seq.get_type_name(), env.active_agt.seqr.get_full_name()), UVM_LOW);
      seq.start(env.active_agt.seqr);
    phase.drop_objection(this);

    `uvm_info(get_type_name(), "alu_multiple_operand_logical_test finished", UVM_LOW);
  endtask
endclass

//------------------------------------------------------------------------------
// alu_multiplication_test
//------------------------------------------------------------------------------
class alu_multiplication_test extends alu_test;
  `uvm_component_utils(alu_multiplication_test)

  alu_multiplication seq;

  function new(string name = "alu_multiplication_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    // run base seq
    super.run_phase(phase);

    // run test seq
    phase.raise_objection(this);
      seq = alu_multiplication::type_id::create("seq", this);
      `uvm_info(get_type_name(), $sformatf("Starting seq %s on %s", seq.get_type_name(), env.active_agt.seqr.get_full_name()), UVM_LOW);
      seq.start(env.active_agt.seqr);
    phase.drop_objection(this);

    `uvm_info(get_type_name(), "alu_multiplication_test finished", UVM_LOW);
  endtask
endclass

//------------------------------------------------------------------------------
// alu_regression_test
//------------------------------------------------------------------------------
class alu_regression_test extends alu_test;
  `uvm_component_utils(alu_regression_test)

  alu_regression seq;

  function new(string name = "alu_regression_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    // run base seq
    super.run_phase(phase);

    // run test seq
    phase.raise_objection(this);
      seq = alu_regression::type_id::create("seq", this);
      `uvm_info(get_type_name(), $sformatf("Starting seq %s on %s", seq.get_type_name(), env.active_agt.seqr.get_full_name()), UVM_LOW);
      seq.start(env.active_agt.seqr);
    phase.drop_objection(this);

    `uvm_info(get_type_name(), "alu_regression_test finished", UVM_LOW);
  endtask
endclass
