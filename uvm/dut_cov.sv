class dut_cov extends uvm_subscriber#(dut_txn);
    `uvm_component_utils(dut_cov)
    
    // Mirror dos campos reais da transacao
    logic        we;           // changed from bit -> logic
    logic [31:0] Dado;        // changed from bit [31:0] -> logic [31:0]
    logic        rst;          // changed from bit -> logic
    
    // Covergroup principal
    covergroup dut_cg;
        option.per_instance = 1; // ensure instance-local coverage
        
        // Escrita habilitada ou nao
        coverpoint we {
            bins write_on  = {1};
            bins write_off = {0};
        }
        
        // Reset observado
        coverpoint rst {
            bins reset_on  = {1};
            bins reset_off = {0};
        }
        
        // Dado valido (nao X/Z)
        coverpoint Dado {
            bins zero     = {32'h00000000};
            bins max      = {32'hFFFFFFFF};
            bins specific = {32'h12345678};
            bins nonzero  = default;
        }
        
        // Cross: escrita durante reset (indesejado)
        cross we, rst {
            illegal_bins write_during_reset =
                binsof(we) intersect {1} &&
                binsof(rst) intersect {1};
        }
    endgroup
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        dut_cg = new();
    endfunction
    
    // Recebe transacoes do monitor
    function void write(dut_txn t);
        if (t == null) begin
            `uvm_error("COV", "Transacao recebida e nula!")
            return;
        end
        
        we   = t.we;
        Dado = t.Dado;
        rst  = t.rst;

        t.convert2string();
        
        `uvm_info("COV", $sformatf("Transacao recebida: we=%b, Dado=%h, rst=%b", we, Dado, rst), UVM_LOW)
        dut_cg.sample();
    endfunction
    
    function void report_phase(uvm_phase phase);
        real cov;
        super.report_phase(phase);
        cov = dut_cg.get_coverage();
        `uvm_info("COVERAGE_REPORT", $sformatf("\n========== DUT COVERAGE ==========\nCobertura funcional: %.2f%%\nCobertura de escrita: %.2f%%\nCobertura de reset: %.2f%%\nCobertura de dado: %.2f%%\n=================================\n", cov, dut_cg.we.get_coverage(), dut_cg.rst.get_coverage(), dut_cg.Dado.get_coverage()), UVM_LOW);
    endfunction
    
endclass