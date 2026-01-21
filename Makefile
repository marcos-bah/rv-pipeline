# ============================================
# Makefile para Pipeline RISC-V com FPU
# ============================================

# Diretórios
RTL_DIR     = rtl
TB_DIR      = rtl/tb
LOG_DIR     = logs
BUILD_DIR   = build

# Compilador
IVERILOG    = iverilog
VVP         = vvp

# Arquivos fonte
RTL_SRC     = $(wildcard $(RTL_DIR)/*.v)
TB_SRC      = $(wildcard $(TB_DIR)/*.v)

# Flags
IVFLAGS     = -Wall

# Cores para output
GREEN       = \033[0;32m
RED         = \033[0;31m
YELLOW      = \033[0;33m
NC          = \033[0m

# ============================================
# Targets principais
# ============================================

.PHONY: all clean test test_all help

help:
	@echo "============================================"
	@echo "  Pipeline RISC-V - Makefile"
	@echo "============================================"
	@echo ""
	@echo "Comandos disponíveis:"
	@echo "  make test_simple    - Teste rápido de validação"
	@echo "  make test_topo      - Teste completo do pipeline"
	@echo "  make test_all       - Executa todos os testes"
	@echo "  make test_fwd       - Teste da Forwarding Unit"
	@echo "  make test_fpu       - Teste da FPU"
	@echo "  make test_fpu_fwd   - Teste FPU + Forwarding integrado"
	@echo "  make test_alu       - Teste da ALU"
	@echo "  make test_decoder   - Teste do Main Decoder"
	@echo "  make test_signext   - Teste do Sign Extend"
	@echo "  make test_rf        - Teste do Register File"
	@echo "  make clean          - Remove arquivos gerados"
	@echo "  make logs           - Mostra logs dos testes"
	@echo ""

# ============================================
# Testes individuais
# ============================================

test_simple: $(BUILD_DIR)
	@echo "$(YELLOW)[COMPILANDO]$(NC) Teste simples do pipeline..."
	@$(IVERILOG) $(IVFLAGS) -o $(BUILD_DIR)/test_simple $(TB_DIR)/topo_simple_tb.v $(RTL_SRC) 2>&1 | tee $(LOG_DIR)/compile_simple.log
	@echo "$(YELLOW)[EXECUTANDO]$(NC) Teste simples..."
	@$(VVP) $(BUILD_DIR)/test_simple 2>&1 | tee $(LOG_DIR)/test_simple.log

test_topo: $(BUILD_DIR)
	@echo "$(YELLOW)[COMPILANDO]$(NC) Teste completo do pipeline..."
	@$(IVERILOG) $(IVFLAGS) -o $(BUILD_DIR)/test_topo $(TB_DIR)/topo_tb.v $(RTL_SRC) 2>&1 | tee $(LOG_DIR)/compile_topo.log
	@echo "$(YELLOW)[EXECUTANDO]$(NC) Teste completo..."
	@$(VVP) $(BUILD_DIR)/test_topo 2>&1 | tee $(LOG_DIR)/test_topo.log

test_fwd: $(BUILD_DIR)
	@echo "$(YELLOW)[COMPILANDO]$(NC) Teste da Forwarding Unit..."
	@$(IVERILOG) $(IVFLAGS) -o $(BUILD_DIR)/test_fwd $(TB_DIR)/forwarding_unit_tb.v $(RTL_DIR)/forwarding_unit.v 2>&1 | tee $(LOG_DIR)/compile_fwd.log
	@echo "$(YELLOW)[EXECUTANDO]$(NC) Teste Forwarding..."
	@$(VVP) $(BUILD_DIR)/test_fwd 2>&1 | tee $(LOG_DIR)/test_fwd.log

test_fpu: $(BUILD_DIR)
	@echo "$(YELLOW)[COMPILANDO]$(NC) Teste da FPU..."
	@$(IVERILOG) $(IVFLAGS) -o $(BUILD_DIR)/test_fpu $(TB_DIR)/fpu_tb.v $(RTL_DIR)/fpu.v $(RTL_DIR)/adder.v $(RTL_DIR)/multiply.v $(RTL_DIR)/int2fp.v $(RTL_DIR)/fp2int.v 2>&1 | tee $(LOG_DIR)/compile_fpu.log
	@echo "$(YELLOW)[EXECUTANDO]$(NC) Teste FPU..."

test_fpu_fwd: $(BUILD_DIR)
	@echo "$(YELLOW)[COMPILANDO]$(NC) Teste da FPU + Forwarding..."
	@$(IVERILOG) $(IVFLAGS) -o $(BUILD_DIR)/test_fpu_fwd $(TB_DIR)/fpu_forwarding_tb.v $(RTL_DIR)/fpu.v $(RTL_DIR)/forwarding_unit.v $(RTL_DIR)/adder.v $(RTL_DIR)/multiply.v $(RTL_DIR)/int2fp.v $(RTL_DIR)/fp2int.v 2>&1 | tee $(LOG_DIR)/compile_fpu_fwd.log
	@echo "$(YELLOW)[EXECUTANDO]$(NC) Teste FPU + Forwarding..."
	@$(VVP) $(BUILD_DIR)/test_fpu_fwd 2>&1 | tee $(LOG_DIR)/test_fpu_fwd.log"
	@$(VVP) $(BUILD_DIR)/test_fpu 2>&1 | tee $(LOG_DIR)/test_fpu.log

test_alu: $(BUILD_DIR)
	@echo "$(YELLOW)[COMPILANDO]$(NC) Teste da ALU..."
	@$(IVERILOG) $(IVFLAGS) -o $(BUILD_DIR)/test_alu $(TB_DIR)/alu_tb.v $(RTL_DIR)/alu.v 2>&1 | tee $(LOG_DIR)/compile_alu.log
	@echo "$(YELLOW)[EXECUTANDO]$(NC) Teste ALU..."
	@$(VVP) $(BUILD_DIR)/test_alu 2>&1 | tee $(LOG_DIR)/test_alu.log

test_decoder: $(BUILD_DIR)
	@echo "$(YELLOW)[COMPILANDO]$(NC) Teste do Main Decoder..."
	@$(IVERILOG) $(IVFLAGS) -o $(BUILD_DIR)/test_decoder $(TB_DIR)/main_decoder_tb.v $(RTL_DIR)/main_decoder.v 2>&1 | tee $(LOG_DIR)/compile_decoder.log
	@echo "$(YELLOW)[EXECUTANDO]$(NC) Teste Decoder..."
	@$(VVP) $(BUILD_DIR)/test_decoder 2>&1 | tee $(LOG_DIR)/test_decoder.log

test_signext: $(BUILD_DIR)
	@echo "$(YELLOW)[COMPILANDO]$(NC) Teste do Sign Extend..."
	@$(IVERILOG) $(IVFLAGS) -o $(BUILD_DIR)/test_signext $(TB_DIR)/sign_extend_tb.v $(RTL_DIR)/sign_extend.v 2>&1 | tee $(LOG_DIR)/compile_signext.log
	@echo "$(YELLOW)[EXECUTANDO]$(NC) Teste Sign Extend..."
	@$(VVP) $(BUILD_DIR)/test_signext 2>&1 | tee $(LOG_DIR)/test_signext.log

test_rf: $(BUILD_DIR)
	@echo "$(YELLOW)[COMPILANDO]$(NC) Teste do Register File..."
	@$(IVERILOG) $(IVFLAGS) -o $(BUILD_DIR)/test_rf $(TB_DIR)/register_file_tb.v $(RTL_DIR)/register_file.v 2>&1 | tee $(LOG_DIR)/compile_rf.log
	@echo "$(YELLOW)[EXECUTANDO]$(NC) Teste Register File..."
	@$(VVP) $(BUILD_DIR)/test_rf 2>&1 | tee $(LOG_DIR)/test_rf.log

# ============================================
# Executar todos os testes
# ============================================

test_all: $(BUILD_DIR)
	@echo "============================================"
	@echo "  EXECUTANDO TODOS OS TESTES"
	@echo "============================================"
	@echo ""
	@$(MAKE) test_fwd --no-print-directory
	@echo ""
	@$(MAKE) test_fpu --no-print-directory
	@echo ""
	@$(MAKE) test_alu --no-print-directory
	@echo ""
	@$(MAKE) test_decoder --no-print-directory
	@echo ""
	@$(MAKE) test_signext --no-print-directory
	@echo ""
	@$(MAKE) test_rf --no-print-directory
	@echo ""
	@$(MAKE) test_simple --no-print-directory
	@echo ""
	@echo "============================================"
	@echo "  RESUMO DOS TESTES"
	@echo "============================================"
	@echo ""
	@grep -h "Passou:" $(LOG_DIR)/test_*.log 2>/dev/null || echo "Nenhum resultado encontrado"
	@echo ""

# ============================================
# Utilitários
# ============================================

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR) $(LOG_DIR)

logs:
	@echo "============================================"
	@echo "  LOGS DOS TESTES"
	@echo "============================================"
	@ls -la $(LOG_DIR)/*.log 2>/dev/null || echo "Nenhum log encontrado"

# ============================================
# Waveform (GTKWave)
# ============================================

wave: test_topo
	@echo "$(YELLOW)[ABRINDO]$(NC) GTKWave..."
	@gtkwave topo_tb.vcd &

# Makefile para simular com Xcelium (xrun)
XRUN = xrun
UVM_HOME=/apps/cds/XCELIUM2409/tools.lnx86/methodology/UVM/CDNS-1.2
XRUN_FLAGS = -uvmhome $(UVM_HOME) -uvm -coverage all -sv -64bit -access +rwc -clean -nowarn DLCPTH

# Arquivo contendo os modulos do projeto
FILELIST = files.f

all:
	$(XRUN) $(XRUN_FLAGS) -f $(FILELIST) +UVM_TESTNAME=dut_test +UVM_NO_RELNOTES

gui:
	$(XRUN) $(XRUN_FLAGS) -f $(FILELIST) -gui +UVM_TESTNAME=dut_test +UVM_NO_RELNOTES

clean:
	rm -rf xrun.history xcelium.d INCA_libs *.log *.key *.shm *.vcd *.vpd worklib csrc