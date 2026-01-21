//=====================================================
// dut_env.sv
// Ambiente UVM com agent, scoreboard e coverage
//=====================================================

class dut_env extends uvm_env;
`uvm_component_utils(dut_env)

// Subcomponentes
dut_agent      agent;
dut_scoreboard sb;
dut_cov        cov;

function new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
    bit enable_cov = 1;
    super.build_phase(phase);

    `uvm_info("ENV", "Iniciando build_phase", UVM_LOW)

    agent = dut_agent::type_id::create("agent", this);
    sb    = dut_scoreboard::type_id::create("sb", this);

    // Permite habilitar ou desabilitar coverage via config_db
    void'(uvm_config_db#(bit)::get(this, "", "enable_cov", enable_cov));

    if (enable_cov) begin
        cov = dut_cov::type_id::create("cov", this);
        `uvm_info("ENV", "Coverage collector habilitado", UVM_LOW)
    end else begin
        `uvm_info("ENV", "Coverage collector desabilitado", UVM_LOW)
    end
endfunction

function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    `uvm_info("ENV", "Iniciando connect_phase", UVM_LOW)

    // Conecta o tráfego de referência (expected) do predictor --> scoreboard
    agent.expected_port.connect(sb.expected_export);

    // Conecta o tráfego observado (monitor) --> scoreboard
    agent.observed_port.connect(sb.actual_export);

    // Conecta o tráfego observado ao coverage collector
    if (cov != null)
        agent.observed_port.connect(cov.analysis_export);

    `uvm_info("ENV", "Connect phase concluido", UVM_LOW)
endfunction

endclass