class alu_environment extends uvm_env;
  `uvm_component_utils(alu_environment)

  alu_agent        active_agt;
  alu_agent        passive_agt;
  alu_scoreboard   scb;
  alu_subscriber   sub;

  function new(string name="alu_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // configure agents as active / passive
    uvm_config_db#(uvm_active_passive_enum)::set(this, "active_agt",  "is_active", UVM_ACTIVE);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "passive_agt", "is_active", UVM_PASSIVE);

    // create components
    active_agt  = alu_agent::type_id::create("active_agt",  this);
    passive_agt = alu_agent::type_id::create("passive_agt", this);
    scb         = alu_scoreboard::type_id::create("scb", this);
    sub         = alu_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // connect active agent monitor -> scoreboard & subscriber
    active_agt.monitor.mon_port.connect(scb.a_agt_fifo.analysis_export);
    active_agt.monitor.mon_port.connect(sub.a_sub_imp);

    // connect passive agent monitor -> scoreboard & subscriber
    passive_agt.monitor.mon_port.connect(scb.p_agt_fifo.analysis_export);
    passive_agt.monitor.mon_port.connect(sub.p_sub_imp);
  endfunction

endclass
