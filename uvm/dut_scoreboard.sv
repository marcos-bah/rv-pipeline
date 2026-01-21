//=====================================================
// dut_scoreboard.sv
//=====================================================
`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class dut_scoreboard extends uvm_component;
    `uvm_component_utils(dut_scoreboard)
    
    // Fluxo esperado (predictor)
    uvm_analysis_imp_expected #(dut_txn, dut_scoreboard) expected_export;
    // Fluxo observado (monitor)
    uvm_analysis_imp_actual #(dut_txn, dut_scoreboard) actual_export;
    
    dut_txn exp_q[$];
    int total_compares;
    int errors;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        total_compares = 0;
        errors = 0;
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        expected_export = new("expected_export", this);
        actual_export   = new("actual_export", this);
    endfunction
    
    // -------------------------------
    // Recebe transacao esperada
    // -------------------------------
    function void write_expected(dut_txn tx);
        exp_q.push_back(tx);
    endfunction
    
    // -------------------------------
    // Recebe transacao observada
    // -------------------------------
    function void write_actual(dut_txn tx);
        dut_txn exp;
        if (exp_q.size() == 0) begin
            `uvm_error("SCOREBOARD", "Transacao observada sem referencia esperada")
            errors++;
            return;
        end
        
        exp = exp_q.pop_front();
        total_compares++;
        
        if (tx.Dado !== exp.Dado) begin
            errors++;
            `uvm_error("SCOREBOARD",
                $sformatf(
                    "Mismatch: esperado=%08x observado=%08x ciclo=%0d",
                    exp.Dado,
                    tx.Dado,
                    tx.cycle
                ))
        end
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD_REPORT",
            $sformatf("\n========== SCOREBOARD FINAL ==========\nComparacoes: %0d\nErros:       %0d\n=====================================\n", total_compares, errors),
            UVM_LOW
        );
        
        if (errors > 0)
            `uvm_error("SCOREBOARD_FINAL", "TESTE FALHOU")
        else
            `uvm_info("SCOREBOARD_FINAL", "TESTE PASSOU", UVM_LOW)
    endfunction
    
endclass