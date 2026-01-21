//=====================================================
// dut_seq.sv
// Sequence para pipeline com carga via clk_load
//=====================================================

class dut_sequence extends uvm_sequence #(dut_txn);
`uvm_object_utils(dut_sequence)

int num_cycles = 100;

virtual dut_if vif;

logic [31:0] program_mem[];

int load_wait = 1;

function new(string name = "dut_sequence");
  super.new(name);
endfunction

function void set_program(logic [31:0] prog[]);
  int i;
  program_mem = new[prog.size()];
  for (i = 0; i < prog.size(); i++)
    program_mem[i] = prog[i];
endfunction

virtual task body();
  dut_txn tx;
  int i;

  // Obter interface via config_db (deve estar configurada pelo sequencer ou globalmente)
  if (!uvm_config_db#(virtual dut_if)::get(m_sequencer, "", "vif", vif)) begin
    if (!uvm_config_db#(virtual dut_if)::get(null, "", "vif", vif)) begin
      `uvm_error("SEQ", "Virtual interface vif nao encontrada")
      return;
    end
  end

  // Aguardar fim do reset
  wait(vif.rst == 0);
  @(posedge vif.clk);
  #10; // Pequeno delay após reset

  // -------------------------------
  // FASE 1: CARGA DO PROGRAMA
  // -------------------------------
  if (program_mem.size() > 0) begin
    `uvm_info("SEQ",
              $sformatf("Carregando %0d instrucoes via clk_load",
                        program_mem.size()),
              UVM_LOW)

    vif.we = 1;
    @(posedge vif.clk_load);

    for (i = 0; i < program_mem.size(); i++) begin
      vif.ADDR_INST   = i << 2;
      vif.Instrucoes = program_mem[i];
      @(posedge vif.clk_load);
      repeat (load_wait - 1) @(posedge vif.clk_load);
    end

    vif.we = 0;
    @(posedge vif.clk_load);

    `uvm_info("SEQ", "Carga do programa concluida", UVM_LOW)
  end

  // -------------------------------
  // FASE 2: EXECUCAO DO PIPELINE
  // -------------------------------
  vif.we = 0;

  `uvm_info("SEQ",
            $sformatf("Iniciando execucao do pipeline por %0d ciclos",
                      num_cycles),
            UVM_LOW)

  repeat (num_cycles) begin
    @(posedge vif.clk);
    tx = dut_txn::type_id::create("tx");
    tx.sample_time = $time;
    start_item(tx);
    finish_item(tx);
  end

  `uvm_info("SEQ", "Execucao do pipeline finalizada", UVM_LOW)

endtask

endclass
