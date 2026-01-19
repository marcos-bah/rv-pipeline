package tb_pkg;
// tb_package.sv
// Pacote contendo tipos compartilhados e a declaração da interface virtual usada pelo testbench UVM.
// Mantemos aqui typedefs e imports comuns para o ambiente.

`include "uvm_macros.svh"
import uvm_pkg::*;

// Typedef para a interface virtual que conecta driver/monitor ao DUT.
// Observação: a interface física `dut_if` está definida em `uvm/dut_if.sv`.
// Para evitar problemas de ordem de compilação, `files.f` especifica `dut_if.sv`
// antes deste pacote. Alternativamente você pode `include` o `dut_if.sv`
// diretamente dentro deste pacote, mas manter a interface num arquivo separado
// é uma prática mais modular.
typedef virtual dut_if dut_vif_if;

// Forward declarations de classes (opcional, as classes estarão em arquivos próprios)
// class dut_txn; endclass

endpackage : tb_pkg
