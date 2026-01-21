module top_tb;
    // sinais de top
    logic clk;
    logic rst;
    logic clk_load;

    // instancio a interface (liga aos nets clk,rst,clk_load)
    dut_if dut_if_inst(.clk(clk), .rst(rst), .clk_load(clk_load));

    // instancia DUT conectando sinais da interface
    topo dut_inst (
        .clk(clk),
        .rst(rst),
        .we(dut_if_inst.we),
        .clk_load(clk_load),
        .Instrucoes(dut_if_inst.Instrucoes),
        .ADDR_INST(dut_if_inst.ADDR_INST),
        .Dado(dut_if_inst.Dado)
    );

    // clock generator
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz estilo (ajuste conforme necessidade)
    end

    // reset and load clock
    initial begin
        rst = 1;
        clk_load = 0;
        #20 rst = 0;
        // opcional: gerar pulsos em clk_load para carregamento se seu DUT usar
    end

    initial begin
        // publicar a interface para o driver/agent/sequence UVM
        // ajuste o path "env.agent.driver" para o path correto do seu projeto UVM
        uvm_config_db#(virtual dut_if)::set(null, "env.agent.driver", "vif", dut_if_inst);
        // alternativa genérica (torna disponível por nome global):
        // uvm_config_db#(virtual dut_if)::set(null, "", "vif", dut_if_inst);

        // iniciar UVM
        run_test();
    end

endmodule
