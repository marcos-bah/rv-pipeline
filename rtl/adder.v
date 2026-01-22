module adder(a, b, op, results, compare);

    input op;
    input [31:0] a, b; // [31]Sign, [30:23] Exponent, [22:0] Mantissa
    output reg [31:0] results;
    output reg [1:0] compare;

    reg [7:0] a_exp, b_exp, r_exp;
    reg [23:0] a_m, b_m; // 24 bits: 1 bit implícito + 23 bits mantissa
    reg [24:0] r_m; // 25 bits para overflow
    reg [24:0] r_m_shifted;
    reg [1:0] mag;
    integer shift_amt;

    always @(*) begin
        // Caso especial: ambos operandos são zero
        if (a[30:0] == 31'd0 && b[30:0] == 31'd0) begin
            results = 32'd0;
            compare = 2'd2; // iguais
        end
        // Caso especial: a é zero
        else if (a[30:0] == 31'd0) begin
            results = op ? {~b[31], b[30:0]} : b;
            compare = 2'd1; // a < b (considerando magnitude)
        end
        // Caso especial: b é zero
        else if (b[30:0] == 31'd0) begin
            results = a;
            compare = 2'd0; // a > b
        end
        else begin
            // Decompose - adiciona bit implícito
            a_exp = a[30:23];
            a_m = {1'b1, a[22:0]}; // bit implícito
            b_exp = b[30:23];
            b_m = {1'b1, b[22:0]}; // bit implícito

            // Align - alinha os expoentes
            if (a_exp > b_exp) begin
                mag = 2'd0;
                b_m = b_m >> (a_exp - b_exp);
                r_exp = a_exp;
            end
            else if (a_exp < b_exp) begin
                mag = 2'd1;
                a_m = a_m >> (b_exp - a_exp);
                r_exp = b_exp;
            end
            else begin
                mag = 2'd2;
                r_exp = a_exp;
            end

            // Determina a operação efetiva e calcula
            if ((a[31] == b[31] && !op) || (a[31] != b[31] && op)) begin
                // Adição efetiva
                r_m = a_m + b_m;
                results[31] = a[31];
            end
            else begin
                // Subtração efetiva
                if (a_m >= b_m) begin
                    r_m = a_m - b_m;
                    results[31] = a[31];
                end
                else begin
                    r_m = b_m - a_m;
                    results[31] = op ? ~b[31] : b[31];
                end
            end

            // Comparação considerando sinais e magnitudes
            if (a[31] != b[31]) begin
                compare = a[31] ? 2'd1 : 2'd0; // negativo < positivo
            end
            else begin
                if (mag == 2'd0)
                    compare = a[31] ? 2'd1 : 2'd0; // se ambos negativos, maior exp = menor valor
                else if (mag == 2'd1)
                    compare = a[31] ? 2'd0 : 2'd1;
                else begin
                    if (a_m > b_m)
                        compare = a[31] ? 2'd1 : 2'd0;
                    else if (a_m < b_m)
                        compare = a[31] ? 2'd0 : 2'd1;
                    else
                        compare = 2'd2; // iguais
                end
            end

            // Normalize
            if (r_m == 25'd0) begin
                results = 32'd0;
            end
            else begin
                // Encontra o bit mais significativo e calcula shift
                if (r_m[24]) shift_amt = 1;
                else if (r_m[23]) shift_amt = 0;
                else if (r_m[22]) shift_amt = -1;
                else if (r_m[21]) shift_amt = -2;
                else if (r_m[20]) shift_amt = -3;
                else if (r_m[19]) shift_amt = -4;
                else if (r_m[18]) shift_amt = -5;
                else if (r_m[17]) shift_amt = -6;
                else if (r_m[16]) shift_amt = -7;
                else if (r_m[15]) shift_amt = -8;
                else if (r_m[14]) shift_amt = -9;
                else if (r_m[13]) shift_amt = -10;
                else if (r_m[12]) shift_amt = -11;
                else if (r_m[11]) shift_amt = -12;
                else if (r_m[10]) shift_amt = -13;
                else if (r_m[9]) shift_amt = -14;
                else if (r_m[8]) shift_amt = -15;
                else if (r_m[7]) shift_amt = -16;
                else if (r_m[6]) shift_amt = -17;
                else if (r_m[5]) shift_amt = -18;
                else if (r_m[4]) shift_amt = -19;
                else if (r_m[3]) shift_amt = -20;
                else if (r_m[2]) shift_amt = -21;
                else if (r_m[1]) shift_amt = -22;
                else shift_amt = -23;

                // Aplica normalização
                if (shift_amt > 0) begin
                    // Overflow - shift right
                    r_m_shifted = r_m >> shift_amt;
                    r_exp = r_exp + shift_amt;
                end
                else if (shift_amt < 0) begin
                    // Underflow - shift left
                    if (r_exp > (-shift_amt)) begin
                        r_m_shifted = r_m << (-shift_amt);
                        r_exp = r_exp + shift_amt;
                    end
                    else begin
                        // Resultado denormalizado/zero
                        results = 32'd0;
                        r_m_shifted = 25'd0;
                    end
                end
                else begin
                    // Já normalizado
                    r_m_shifted = r_m;
                end

                // Compõe resultado
                if (r_m_shifted != 25'd0) begin
                    results[30:23] = r_exp;
                    results[22:0] = r_m_shifted[22:0];
                end
            end
        end
    end

endmodule