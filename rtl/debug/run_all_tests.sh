#!/bin/bash
# Script para executar todos os testbenches de debug

cd /home/marcosbarbosa/Documents/verilog/rv-pipeline

echo "=========================================="
echo "   Executando Testbenches de Debug"
echo "=========================================="
echo ""

PASS=0
FAIL=0

# Lista de testbenches
TESTS=(
    "debug_01_mux_fpu_input_tb.v:mux_2x1_32bits.v"
    "debug_02_fwd_fpu_integration_tb.v:forwarding_unit.v mux_3x1_32bits.v mux_2x1_32bits.v fpu.v adder.v multiply.v int2fp.v fp2int.v"
    "debug_03_pipeline_timing_tb.v:forwarding_unit.v mux_3x1_32bits.v mux_2x1_32bits.v fpu.v adder.v multiply.v int2fp.v fp2int.v"
    "debug_04_pipeline_no_nop_tb.v:forwarding_unit.v mux_3x1_32bits.v mux_2x1_32bits.v fpu.v adder.v multiply.v int2fp.v fp2int.v"
    "debug_05_execute_memory_tb.v:*.v"
    "debug_06_mini_topo_tb.v:*.v"
    "fpu_forwarding_tb.v:fpu.v forwarding_unit.v adder.v multiply.v int2fp.v fp2int.v"
)

for test_entry in "${TESTS[@]}"; do
    IFS=':' read -r testbench deps <<< "$test_entry"
    testname="${testbench%.v}"
    
    echo "--- Testando: $testname ---"
    
    # Monta comando de compilação
    if [ "$deps" = "*.v" ]; then
        CMD="iverilog -Wall -o build/$testname rtl/debug/$testbench rtl/*.v 2>/dev/null"
    else
        DEPS_FILES=""
        for dep in $deps; do
            DEPS_FILES="$DEPS_FILES rtl/$dep"
        done
        CMD="iverilog -Wall -o build/$testname rtl/debug/$testbench $DEPS_FILES 2>/dev/null"
    fi
    
    # Compila
    eval $CMD
    
    if [ $? -eq 0 ]; then
        # Executa e verifica resultado
        OUTPUT=$(vvp build/$testname 2>&1)
        
        if echo "$OUTPUT" | grep -q "\[FAIL\]"; then
            echo "  [FAIL]"
            FAIL=$((FAIL + 1))
        else
            echo "  [PASS]"
            PASS=$((PASS + 1))
        fi
    else
        echo "  [COMPILE ERROR]"
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "=========================================="
echo "   Resumo: $PASS passou, $FAIL falhou"
echo "=========================================="
