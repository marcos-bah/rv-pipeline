module topo (
    input clk, rst,
    // Saídas para observação (necessárias para síntese)
    output [31:0] debug_WB,       // Resultado do Write Back
    output [31:0] debug_ALUResult, // Resultado da ALU
    output [31:0] debug_inst,     // Instrução atual
    output [4:0]  debug_WA,       // Endereço de escrita no RF
    output        debug_RegWrite  // Write Enable do Register File
);

// CUIDAR COM TIPOS REG E WIRE, MANTER REGS NOS FF`S APENAS

// sinais do IF
wire [31:0] branchOffset, inst, WB, ALUResult;
wire zeroFlag, branchFlag, flush, Branch;
wire RSWIRE; // seletor mux
wire WER2WIRE; // write enable do register file
wire [4:0] WA;
wire WEFWIRE2; // write enable float para entrada do rf
wire ASWIRE; // ALUSrc wire
// Fetch
InstructionFetch IF (
    .clk(clk),
    .rst(rst),
    .branchOffset(branchOffset),
    .zeroFlag(zeroFlag),
    .branchFlag(Branch),
    .inst(inst),
    .flush(flush)
);

// flip flop INST
reg [31:0] Instr;
always @ (posedge clk) Instr <= inst; // instrução no decode <= instrução no fetch

// Decode
wire [31:0] Ain, Bin, ImmExt;
wire [1:0] ResultSrc;
wire MemWrite, RegWrite, ALUSrc;
wire [2:0] ALUControl;
wire [2:0]F3WIRE;
wire [31:0] FAin, FBin; // Wire de entrada dos registradores fA e fB
wire [4:0] selFPU;
wire RegWriteF;
wire FPUAinSel;
wire MemSrc;
wire DSrc;

InstructionDecode ID (
    .clk(clk),
    .Instr(Instr),
    .WB(WB),
    .WA(WA),
    .WE(WER2WIRE),
    .Branch(branchFlag),
    .Ain(Ain), // FF A
    .Bin(Bin), // FF B
    .floatRegisterAin(FAin), //FF fA
    .floatRegisterBin(FBin), // FF fb
    .ImmExt(ImmExt), // FF IMM
    .ResultSrc(ResultSrc), // FF CTRL
    .MemWrite(MemWrite), // FF CTRL
    .FPUAinSel(FPUAinSel),
    .RegWrite(RegWrite), // FF CTRL
    .RegWriteF(RegWriteF), // FF CTRL (PRECISA INSTANCIAR O WIRE E FAZER O ROTEAMENTO POSTERIOR)
    .WEF(WEFWIRE2), // write enable para entrada do rf
    .selFPU(selFPU), // FF CTRL (PRECISA INSTANCIAR O WIRE E FAZER O ROTEAMENTO POSTERIOR)
    .MemSrc(MemSrc), // FF CTRL (PRECISA INSTANCIAR O WIRE E FAZER O ROTEAMENTO POSTERIOR)
    .DSrc(DSrc), // FF CTRL (PRECISA INSTANCIAR O WIRE E FAZER O ROTEAMENTO POSTERIOR)
    .ALUSrc(ALUSrc), // FF CTRL
    .ALUControl(ALUControl) // FF CTRL

);

// flip flops A, B, IMM, fA e fB
wire [31:0] Aout, Bout, FAout, FBout;
reg [31:0] A, B, IMM, FA, FB;
always @ (posedge clk) A <= Ain;
always @ (posedge clk) B <= Bin;
always @ (posedge clk) FA <= FAin;
always @ (posedge clk) FB <= FBin;
always @ (posedge clk) IMM <= ImmExt;

// flip flops para rs1 e rs2 (necessários para forwarding)
reg [4:0] Rs1_EX, Rs2_EX;
always @ (posedge clk) Rs1_EX <= Instr[19:15];
always @ (posedge clk) Rs2_EX <= Instr[24:20];

assign branchOffset = IMM;
assign Aout = A;
assign Bout = B;
assign FAout = FA;
assign FBout = FB;

// flip flop CTRL
reg [2:0] AC, F3;
reg [1:0] RS;
reg BF, WEM, WER, AS, MMS, MFAS, WERF, MUXAFPU; // mux mem sel e mux alu fpu sel
reg [4:0] II, FSEL;
wire [2:0] ACWIRE;
wire WEMWIRE, MMSWIRE, MFASWIRE, WERFWIRE, MUXAFPUWIRE;
wire [4:0] FSELWIRE;

always @ (posedge clk)
begin

    if (flush)
    begin
        BF <= 0; // Branch, posteriormente se torna branchflag
        WER <= 0; // WriteEnable Register
        WEM <= 0; // WriteEnable Memory
    end
    else
    begin
        BF <= branchFlag;
        RS <= ResultSrc;
        WEM <= MemWrite;
        WER <= RegWrite;
        AS <= ALUSrc;
        AC <= ALUControl;
        II <= Instr[11:7];
        F3 <= Instr[14:12];
        MMS <= MemSrc; // mux mem
        MFAS <= DSrc; // mux d
        WERF <= RegWriteF; // write enable F
        FSEL <= selFPU; // seletor fpu
        MUXAFPU <= FPUAinSel;
    end
end


assign Branch = BF;
assign ASWIRE = AS;
assign ACWIRE = AC;
assign WEMWIRE = WEM;
assign F3WIRE = F3;
assign FSELWIRE = FSEL;
assign WERFWIRE = WERF;
assign MFASWIRE = MFAS;
assign MMSWIRE = MMS;
assign MUXAFPUWIRE = MUXAFPU;

// flip flops D e M (movidos para antes do forwarding)
reg [31:0] ALUR;
reg [31:0] MR;
reg [31:0] ALU_MEM, MR_MEM; // registros intermediários EX→MEM
wire [31:0] ALURWIRE, MRWIRE;
assign ALURWIRE = ALUR;
assign MRWIRE = MR;

// flip flop para rd no estágio MEM (EX→MEM)
reg [4:0] II_MEM;
reg WER_MEM, WEF_MEM;
reg [1:0] RS_MEM;
always @(posedge clk) begin
    II_MEM <= II;
    WER_MEM <= WER;
    WEF_MEM <= WERF;
    RS_MEM <= RS;
end

// flip flop controle WB (movidos para antes do forwarding)
reg [31:0] RS2; // Ver se é necessario tantos bits, aparentemente são necessários apenas 2
reg [4:0] II2;
reg WER2, WEF2;

assign RSWIRE = RS2; // seletor mux
assign WER2WIRE = WER2; // write enable do register file
assign WA = II2;
assign WEFWIRE2 = WEF2;

// Wires para rd no estágio MEM (para forwarding)
wire [4:0] Rd_MEM;
assign Rd_MEM = II_MEM; // II_MEM contém rd do estágio MEM

// Sinais de forwarding
wire [1:0] ForwardA, ForwardB, ForwardFA, ForwardFB;

// Forwarding Unit
Forwarding_Unit FWD_UNIT (
    .Rs1_EX(Rs1_EX),
    .Rs2_EX(Rs2_EX),
    .Rd_MEM(Rd_MEM),
    .RegWrite_MEM(WER_MEM),
    .RegWriteF_MEM(WEF_MEM),
    .Rd_WB(II2),
    .RegWrite_WB(WER2),
    .RegWriteF_WB(WEF2),
    .ForwardA(ForwardA),
    .ForwardB(ForwardB),
    .ForwardFA(ForwardFA),
    .ForwardFB(ForwardFB)
);

// Muxes de forwarding para registradores inteiros (ALU)
wire [31:0] SrcA_Fwd, SrcB_Fwd;

mux3x1_32bits mux_fwd_A (
    .in00(Aout),      // Sem forwarding (valor do register file)
    .in01(WB),        // Forward do WB
    .in10(ALU_MEM),   // Forward do MEM (resultado registrado)
    .sel(ForwardA),
    .out(SrcA_Fwd)
);

mux3x1_32bits mux_fwd_B (
    .in00(Bout),      // Sem forwarding
    .in01(WB),        // Forward do WB
    .in10(ALU_MEM),   // Forward do MEM
    .sel(ForwardB),
    .out(SrcB_Fwd)
);

// Muxes de forwarding para registradores float (FPU)
wire [31:0] SrcAF_Fwd, SrcBF_Fwd;

mux3x1_32bits mux_fwd_FA (
    .in00(FAout),     // Sem forwarding
    .in01(WB),        // Forward do WB
    .in10(ALU_MEM),   // Forward do MEM
    .sel(ForwardFA),
    .out(SrcAF_Fwd)
);

mux3x1_32bits mux_fwd_FB (
    .in00(FBout),     // Sem forwarding
    .in01(WB),        // Forward do WB
    .in10(ALU_MEM),   // Forward do MEM
    .sel(ForwardFB),
    .out(SrcBF_Fwd)
);

wire [31:0] ReadData;
Execute_Memory EXMEM (
    .ImmExt(branchOffset),
    .WriteData(SrcB_Fwd),     // Usa valor com forwarding aplicado
    .SrcA(SrcA_Fwd),          // Usa valor com forwarding aplicado
    .SrcAF(SrcAF_Fwd),        // Usa valor com forwarding aplicado
    .SrcBF(SrcBF_Fwd),        // Usa valor com forwarding aplicado
    .MemSrc(MMSWIRE),
    .DSrc(MFASWIRE),
    .selFPU(FSELWIRE),
    .FPUAinSel(MUXAFPUWIRE),
    .ALUControl(ACWIRE),
    .MemWrite(WEMWIRE),
    .clk(clk),
    .ALUSrc(ASWIRE),
    .zero(zeroFlag),
    .ReadData(ReadData),
    .muxpal_result(ALUResult),
    .funct3(F3WIRE)
);

// Atualização dos flip flops D e M (EX→MEM)
always @ (posedge clk) ALU_MEM <= ALUResult; // ALU Result EX→MEM
always @ (posedge clk) MR_MEM <= ReadData; // Memory Result EX→MEM

// Atualização dos flip flops D e M (MEM→WB)
always @ (posedge clk) ALUR <= ALU_MEM; // ALU Result MEM→WB
always @ (posedge clk) MR <= MR_MEM; // Memory Result MEM→WB

// Atualização dos flip flops de controle WB
always @ (posedge clk)
begin
        RS2 <= RS_MEM;
        WER2 <= WER_MEM;
        II2 <= II_MEM;
        WEF2 <= WEF_MEM;
end

mux2x1_32bits muxout (
  .inA(ALURWIRE),
  .inB(MRWIRE),
  .sel(RSWIRE),
  .out(WB)
);

// Conexão das saídas de debug para síntese
assign debug_WB = WB;
assign debug_ALUResult = ALUResult;
assign debug_inst = inst;
assign debug_WA = WA;
assign debug_RegWrite = WER2WIRE;

endmodule
