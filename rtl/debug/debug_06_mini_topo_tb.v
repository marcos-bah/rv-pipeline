// =============================================================================
// Debug Testbench 6: Mini-Topo (Pipeline Simplificado)
// =============================================================================
// Simula a parte relevante do topo.v para identificar o problema exato.
// Foca no fluxo: ID -> EX -> MEM com forwarding para FPU
// =============================================================================

module debug_mini_topo_tb;

    reg clk, rst;
    
    // Clock de 10ns
    always #5 clk = ~clk;
    
    // =========================================================================
    // ESTÁGIO ID: Instruction Decode
    // =========================================================================
    reg [31:0] Instr;  // Instrução atual no ID
    
    // Valores lidos do register file (simulados)
    reg [31:0] Ain, Bin;      // Valores inteiros
    reg [31:0] FAin, FBin;    // Valores float
    reg [31:0] ImmExt_ID;     // Imediato do ID
    
    // Sinais de controle do ID (simulados)
    reg RegWrite_ID, RegWriteF_ID;
    reg FPUAinSel_ID;
    reg [4:0] selFPU_ID;
    reg DSrc_ID;
    reg [2:0] ALUControl_ID;
    reg ALUSrc_ID;
    
    // =========================================================================
    // Pipeline ID -> EX (flip-flops)
    // =========================================================================
    reg [31:0] A, B, FA, FB;
    reg [31:0] ImmExt_EX;
    reg [4:0] Rs1_EX, Rs2_EX;
    reg [4:0] Rd_EX;
    reg RegWrite_EX, RegWriteF_EX;
    reg FPUAinSel_EX;
    reg [4:0] selFPU_EX;
    reg DSrc_EX;
    reg [2:0] ALUControl_EX;
    reg ALUSrc_EX;
    
    // Latch ID -> EX
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A <= 0; B <= 0; FA <= 0; FB <= 0;
            ImmExt_EX <= 0;
            Rs1_EX <= 0; Rs2_EX <= 0; Rd_EX <= 0;
            RegWrite_EX <= 0; RegWriteF_EX <= 0;
            FPUAinSel_EX <= 0; selFPU_EX <= 0; DSrc_EX <= 0;
            ALUControl_EX <= 0; ALUSrc_EX <= 0;
        end else begin
            A <= Ain;
            B <= Bin;
            FA <= FAin;
            FB <= FBin;
            ImmExt_EX <= ImmExt_ID;
            Rs1_EX <= Instr[19:15];
            Rs2_EX <= Instr[24:20];
            Rd_EX <= Instr[11:7];
            RegWrite_EX <= RegWrite_ID;
            RegWriteF_EX <= RegWriteF_ID;
            FPUAinSel_EX <= FPUAinSel_ID;
            selFPU_EX <= selFPU_ID;
            DSrc_EX <= DSrc_ID;
            ALUControl_EX <= ALUControl_ID;
            ALUSrc_EX <= ALUSrc_ID;
        end
    end
    
    // =========================================================================
    // Pipeline EX -> MEM (flip-flops)
    // =========================================================================
    reg [4:0] Rd_MEM;
    reg RegWrite_MEM, RegWriteF_MEM;
    reg [31:0] ALUResult_MEM;  // Resultado da ALU/FPU
    
    // =========================================================================
    // Pipeline MEM -> WB (flip-flops)
    // =========================================================================
    reg [4:0] Rd_WB;
    reg RegWrite_WB, RegWriteF_WB;
    reg [31:0] WB;
    
    // =========================================================================
    // Forwarding Unit
    // =========================================================================
    wire [1:0] ForwardA, ForwardB, ForwardFA, ForwardFB;
    
    Forwarding_Unit fwd_unit (
        .Rs1_EX(Rs1_EX),
        .Rs2_EX(Rs2_EX),
        .Rd_MEM(Rd_MEM),
        .RegWrite_MEM(RegWrite_MEM),
        .RegWriteF_MEM(RegWriteF_MEM),
        .Rd_WB(Rd_WB),
        .RegWrite_WB(RegWrite_WB),
        .RegWriteF_WB(RegWriteF_WB),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .ForwardFA(ForwardFA),
        .ForwardFB(ForwardFB)
    );
    
    // =========================================================================
    // MUXes de Forwarding
    // =========================================================================
    wire [31:0] SrcA_Fwd, SrcB_Fwd, SrcAF_Fwd, SrcBF_Fwd;
    
    mux3x1_32bits mux_fwd_A (
        .in00(A),              // Register file
        .in01(WB),             // Forward do WB
        .in10(ALUResult_MEM),  // Forward do MEM
        .sel(ForwardA),
        .out(SrcA_Fwd)
    );
    
    mux3x1_32bits mux_fwd_B (
        .in00(B),
        .in01(WB),
        .in10(ALUResult_MEM),
        .sel(ForwardB),
        .out(SrcB_Fwd)
    );
    
    mux3x1_32bits mux_fwd_FA (
        .in00(FA),
        .in01(WB),
        .in10(ALUResult_MEM),
        .sel(ForwardFA),
        .out(SrcAF_Fwd)
    );
    
    mux3x1_32bits mux_fwd_FB (
        .in00(FB),
        .in01(WB),
        .in10(ALUResult_MEM),
        .sel(ForwardFB),
        .out(SrcBF_Fwd)
    );
    
    // =========================================================================
    // Execute_Memory Stage
    // =========================================================================
    wire zero;
    wire [31:0] ReadData, muxpal_result;
    
    Execute_Memory EXMEM (
        .ImmExt(ImmExt_EX),
        .WriteData(SrcB_Fwd),
        .SrcA(SrcA_Fwd),
        .SrcAF(SrcAF_Fwd),
        .SrcBF(SrcBF_Fwd),
        .MemSrc(1'b0),
        .DSrc(DSrc_EX),
        .ALUControl(ALUControl_EX),
        .funct3(3'b010),
        .MemWrite(1'b0),
        .clk(clk),
        .ALUSrc(ALUSrc_EX),
        .FPUAinSel(FPUAinSel_EX),
        .selFPU(selFPU_EX),
        .zero(zero),
        .ReadData(ReadData),
        .muxpal_result(muxpal_result)
    );
    
    // =========================================================================
    // Latch EX -> MEM
    // =========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            Rd_MEM <= 0;
            RegWrite_MEM <= 0;
            RegWriteF_MEM <= 0;
            ALUResult_MEM <= 0;
        end else begin
            Rd_MEM <= Rd_EX;
            RegWrite_MEM <= RegWrite_EX;
            RegWriteF_MEM <= RegWriteF_EX;
            ALUResult_MEM <= muxpal_result;
        end
    end
    
    // =========================================================================
    // Latch MEM -> WB
    // =========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            Rd_WB <= 0;
            RegWrite_WB <= 0;
            RegWriteF_WB <= 0;
            WB <= 0;
        end else begin
            Rd_WB <= Rd_MEM;
            RegWrite_WB <= RegWrite_MEM;
            RegWriteF_WB <= RegWriteF_MEM;
            WB <= ALUResult_MEM;  // Simplificado, sem mux ResultSrc
        end
    end
    
    // =========================================================================
    // Teste
    // =========================================================================
    integer cycle;
    
    initial begin
        $dumpfile("debug_mini_topo.vcd");
        $dumpvars(0, debug_mini_topo_tb);
        
        $display("");
        $display("================================================================");
        $display("  Debug: Mini-Topo Pipeline");
        $display("================================================================");
        $display("");
        $display("Programa:");
        $display("  Ciclo 1: lui x10, 0x37800  (0x37800537)");
        $display("  Ciclo 2: fmv.w.x f9, x10   (0xF00504D3)");
        $display("");
        
        clk = 0;
        rst = 1;
        cycle = 0;
        
        // Inicialização
        Instr = 32'h0;
        Ain = 0; Bin = 0; FAin = 0; FBin = 0;
        ImmExt_ID = 0;
        RegWrite_ID = 0; RegWriteF_ID = 0;
        FPUAinSel_ID = 0; selFPU_ID = 0; DSrc_ID = 0;
        ALUControl_ID = 0; ALUSrc_ID = 0;
        
        #12 rst = 0;
        
        // =====================================================================
        // Ciclo 1: lui x10, 0x37800 entra no ID
        // =====================================================================
        @(posedge clk);
        cycle = cycle + 1;
        
        Instr = 32'h37800537;  // lui x10, 0x37800
        Ain = 32'h0;           // lui não lê registrador
        Bin = 32'h0;
        FAin = 32'h0;
        FBin = 32'h0;
        ImmExt_ID = 32'h37800000;  // Imediato U-type: {imm[31:12], 12'b0}
        
        // Controle para lui:
        RegWrite_ID = 1;       // Escreve em x10
        RegWriteF_ID = 0;
        FPUAinSel_ID = 0;
        selFPU_ID = 0;
        DSrc_ID = 0;           // Usa ALU
        ALUControl_ID = 3'b111; // LUI passthrough
        ALUSrc_ID = 1;         // Usa imediato
        
        $display("Ciclo %0d: lui x10 no ID", cycle);
        $display("         Instr = 0x%08h, Rd = %0d", Instr, Instr[11:7]);
        
        // =====================================================================
        // Ciclo 2: lui x10 no EX, fmv.w.x f9, x10 entra no ID
        // =====================================================================
        @(posedge clk);
        cycle = cycle + 1;
        
        Instr = 32'hF00504D3;  // fmv.w.x f9, x10
        Ain = 32'hxxxxxxxx;    // x10 ainda não foi escrito!
        Bin = 32'h0;
        FAin = 32'h0;
        FBin = 32'h0;
        ImmExt_ID = 32'h0;     // fmv.w.x não usa imediato
        
        // Controle para fmv.w.x:
        RegWrite_ID = 0;
        RegWriteF_ID = 1;      // Escreve em f9
        FPUAinSel_ID = 1;      // Seleciona entrada inteira
        selFPU_ID = 5'd12;     // fmv.w.x
        DSrc_ID = 1;           // Usa FPU
        ALUControl_ID = 3'b000;
        ALUSrc_ID = 0;
        
        $display("Ciclo %0d: lui x10 no EX, fmv.w.x no ID", cycle);
        $display("         Rd_EX = %0d, RegWrite_EX = %b", Rd_EX, RegWrite_EX);
        
        // Simula resultado do lui no EX (imediato = 0x37800000)
        // Nota: No topo real, isso viria da ALU com ALUControl=111
        
        // =====================================================================
        // Ciclo 3: lui x10 no MEM, fmv.w.x no EX (HAZARD!)
        // =====================================================================
        @(posedge clk);
        cycle = cycle + 1;
        
        Instr = 32'h00000013;  // NOP
        Ain = 32'h0;
        RegWrite_ID = 0;
        RegWriteF_ID = 0;
        
        #1; // Aguarda propagação combinacional
        
        $display("");
        $display("Ciclo %0d: lui x10 no MEM, fmv.w.x no EX (HAZARD!)", cycle);
        $display("============================================================");
        $display("");
        $display("Estado do Pipeline:");
        $display("  Rs1_EX = %0d (fmv.w.x lê x10)", Rs1_EX);
        $display("  Rd_MEM = %0d (lui escreveu x10)", Rd_MEM);
        $display("  RegWrite_MEM = %b", RegWrite_MEM);
        $display("  ALUResult_MEM = 0x%08h (resultado do lui)", ALUResult_MEM);
        $display("");
        $display("Forwarding Unit:");
        $display("  ForwardA = %b", ForwardA);
        $display("");
        $display("MUX de Forwarding:");
        $display("  A (reg file) = 0x%08h", A);
        $display("  SrcA_Fwd     = 0x%08h", SrcA_Fwd);
        $display("");
        $display("FPU Input:");
        $display("  FPUAinSel_EX = %b", FPUAinSel_EX);
        $display("  selFPU_EX    = %0d", selFPU_EX);
        $display("");
        $display("Execute_Memory Output:");
        $display("  muxpal_result = 0x%08h", muxpal_result);
        
        if (muxpal_result === 32'h37800000) begin
            $display("");
            $display("[PASS] muxpal_result = 0x37800000 (correto!)");
        end else begin
            $display("");
            $display("[FAIL] muxpal_result = 0x%08h, esperado 0x37800000", muxpal_result);
        end
        
        // =====================================================================
        // Ciclo 4: fmv.w.x no MEM
        // =====================================================================
        @(posedge clk);
        cycle = cycle + 1;
        
        #1;
        
        $display("");
        $display("Ciclo %0d: fmv.w.x no MEM", cycle);
        $display("  ALUResult_MEM (resultado do fmv.w.x) = 0x%08h", ALUResult_MEM);
        
        if (ALUResult_MEM === 32'h37800000) begin
            $display("[PASS] ALUResult_MEM = 0x37800000 (será escrito em f9)");
        end else begin
            $display("[FAIL] ALUResult_MEM = 0x%08h", ALUResult_MEM);
        end
        
        // =====================================================================
        // Ciclo 5: fmv.w.x no WB
        // =====================================================================
        @(posedge clk);
        cycle = cycle + 1;
        
        #1;
        
        $display("");
        $display("Ciclo %0d: fmv.w.x no WB", cycle);
        $display("  WB = 0x%08h (escrito em f9)", WB);
        $display("  Rd_WB = %0d, RegWriteF_WB = %b", Rd_WB, RegWriteF_WB);
        
        if (WB === 32'h37800000 && Rd_WB === 5'd9 && RegWriteF_WB === 1'b1) begin
            $display("[PASS] f9 = 0x37800000 (2^-16 em IEEE754)");
        end else begin
            $display("[FAIL] WB = 0x%08h, Rd_WB = %0d, RegWriteF_WB = %b", WB, Rd_WB, RegWriteF_WB);
        end
        
        $display("");
        $display("================================================================");
        $display("  Fim do teste");
        $display("================================================================");
        
        $finish;
    end

endmodule
