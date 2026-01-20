`ifndef DUT_SEQUENCE_SV
`define DUT_SEQUENCE_SV

class dut_sequence extends uvm_sequence#(dut_txn);
  `uvm_object_utils(dut_sequence)
  
  // Número de transações a gerar
  int num_trans = 10;
  
  // --------------------------------------------------
  // Construtor
  // --------------------------------------------------
  function new(string name = "dut_sequence");
    super.new(name);
  endfunction
  
  // --------------------------------------------------
  // Body - corpo da sequência
  // --------------------------------------------------
  virtual task body();
    dut_txn tx;
    
    `uvm_info("SEQ", $sformatf("Iniciando sequencia com %0d transacoes", num_trans), UVM_MEDIUM)
    
    repeat (num_trans) begin
      tx = dut_txn::type_id::create("tx");
      
      start_item(tx);
      
      // Randomize a transação
      if (!tx.randomize()) begin
        `uvm_error("SEQ", "Randomizacao falhou")
      end
      
      finish_item(tx);
      
      `uvm_info("SEQ", $sformatf("Enviada transacao: %s", tx.convert2string()), UVM_HIGH)
    end
    
    `uvm_info("SEQ", "Sequencia finalizada", UVM_MEDIUM)
  endtask
  
endclass

`endif // DUT_SEQUENCE_SV