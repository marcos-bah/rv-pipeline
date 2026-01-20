`ifndef DUT_DRIVER_SV
`define DUT_DRIVER_SV

class dut_driver extends uvm_driver#(dut_txn);
  `uvm_component_utils(dut_driver)
  
  virtual dut_if vif;
  
  // --------------------------------------------------
  // Construtor
  // --------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  // --------------------------------------------------
  // build_phase
  // --------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Driver nao recebeu a interface virtual");
    end
  endfunction
  
  // --------------------------------------------------
  // run_phase
  // --------------------------------------------------
  task run_phase(uvm_phase phase);
    dut_txn tx;
    
    forever begin
      // Pega próximo item da sequência
      seq_item_port.get_next_item(tx);
      
      // Inicia rastreamento da transação
      void'(tx.begin_tr());  // CORRIGIDO: adicionado void'()
      
      // Drive a transação
      drive_transaction(tx);
      
      // Finaliza rastreamento
      tx.end_tr();
      
      // Sinaliza conclusão
      seq_item_port.item_done();
    end
  endtask
  
  // --------------------------------------------------
  // Task para aplicar a transação na interface
  // --------------------------------------------------
  task drive_transaction(dut_txn tx);
    // Exemplo: aguarda alguns ciclos (fixo ou aleatório)
    // REMOVIDO: repeat (tx.cycles) - não existe esse campo
    
    // Espera 1 ciclo de clock
    @(posedge vif.clk);
    
    // Aqui você aplicaria os sinais na interface
    // Por exemplo, se tivesse sinais de controle:
    // vif.enable = 1;
    // vif.data_in = tx.some_data;
    
    // Para este caso específico (apenas observação via debug),
    // o driver pode não fazer nada ou apenas gerar delays
    `uvm_info("DRIVER", $sformatf("Driving transaction: inst=0x%08h", tx.inst), UVM_HIGH)
  endtask
  
endclass

`endif // DUT_DRIVER_SV