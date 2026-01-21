module adder(a,b,op,results , compare);

 input op;
 input [31:0]a,b; //[31]Sign ,[30:23] Exponent ,[22:0]mantissa ,
 output reg[31:0]results;

 reg [7:0]a_exp , b_exp , r_exp;
 reg [31:0]a_m, b_m, r_m,prm;
 reg [1:0] mag;
 output reg [1:0] compare;
 integer i;
 reg state;


 always @(*)
 begin
 // Caso especial: ambos operandos são zero
 if (a[30:0] == 31'd0 && b[30:0] == 31'd0) begin
     results = 32'd0;
     compare = 2'd2; // iguais
 end
 // Caso especial: a é zero
 else if (a[30:0] == 31'd0) begin
     results = op ? {~b[31], b[30:0]} : b; // Se subtração, nega B
     compare = 2'd1; // a < b
 end
 // Caso especial: b é zero
 else if (b[30:0] == 31'd0) begin
     results = a;
     compare = 2'd0; // a > b
 end
 else begin
 //Decompose
 a_exp = a[30:23];
 a_m = {9'b000000001 , a[22:0]};
 b_exp = b[30:23];
 b_m = {9'b000000001 , b[22:0]};

 //Sort/Align

 if (a_exp > b_exp) begin
 mag = 0;
 b_m = b_m >> (a_exp - b_exp);
 b_exp = b_exp + (a_exp - b_exp);
 // Compare considerando sinais
 if (a[31] == 1'b0 && b[31] == 1'b0)
     compare = 0; // a > b (ambos positivos, |a| > |b|)
 else if (a[31] == 1'b1 && b[31] == 1'b1)
     compare = 1; // a < b (ambos negativos, |a| > |b| significa a mais negativo)
 else if (a[31] == 1'b0)
     compare = 0; // a positivo, b negativo -> a > b
 else
     compare = 1; // a negativo, b positivo -> a < b

end
else if (a_exp < b_exp)

begin
mag = 1;
a_m = a_m >> (b_exp - a_exp);
a_exp = a_exp + (b_exp - a_exp);
// Compare considerando sinais
if (a[31] == 1'b0 && b[31] == 1'b0)
    compare = 1; // a < b (ambos positivos, |b| > |a|)
else if (a[31] == 1'b1 && b[31] == 1'b1)
    compare = 0; // a > b (ambos negativos, |b| > |a| significa b mais negativo)
else if (a[31] == 1'b0)
    compare = 0; // a positivo, b negativo -> a > b
else
    compare = 1; // a negativo, b positivo -> a < b

end
else begin
mag = 2;

if (a_m > b_m) begin
    // |a| > |b|
    if (a[31] == 1'b0 && b[31] == 1'b0)
        compare = 0; // ambos positivos -> a > b
    else if (a[31] == 1'b1 && b[31] == 1'b1)
        compare = 1; // ambos negativos -> a < b
    else if (a[31] == 1'b0)
        compare = 0; // a positivo -> a > b
    else
        compare = 1; // a negativo -> a < b
end
else if (a_m < b_m) begin
    // |b| > |a|
    if (a[31] == 1'b0 && b[31] == 1'b0)
        compare = 1; // ambos positivos -> a < b
    else if (a[31] == 1'b1 && b[31] == 1'b1)
        compare = 0; // ambos negativos -> a > b
    else if (a[31] == 1'b0)
        compare = 0; // a positivo -> a > b
    else
        compare = 1; // a negativo -> a < b
end
else begin
    compare = 2; // a == b
end
end

//Add
if((a[31]==b[31] && !op) || (a[31]!=b[31] && op))
    begin
        results[31] = a[31];
        r_m = a_m + b_m;
end
else if((a[31]!=b[31] && !op) || (a[31]==b[31] && op))
begin
if(mag==0)
begin
r_m = a_m - b_m;
// Se op=1 (subtração) e ambos negativos: resultado mantém sinal de a
// Se op=1 e sinais diferentes: resultado positivo se a positivo
// Se op=0 (adição) e sinais diferentes: resultado tem sinal de a (maior magnitude)
results[31] = op ? a[31] : a[31];
end
else if (mag==1)
begin
r_m = b_m - a_m;
// Se op=1 e ambos negativos: resultado positivo (b tem menor magnitude, então -a - (-b) = -a + b, e |b|>|a| então positivo)
// Se op=1 e sinais diferentes: resultado tem sinal oposto de b
// Se op=0 e sinais diferentes: resultado tem sinal de b (maior magnitude)
results[31] = op ? ~b[31] : b[31];
end
else if (mag==2)
begin
if(a_m >= b_m)
begin
r_m = a_m - b_m;
results[31] = op ? a[31] : a[31];
end
else if (a_m < b_m)

begin
 r_m = b_m - a_m;
 results[31] = op ? ~b[31] : b[31];
 end
 else begin r_m = b_m - a_m; results[31] = 1'b0; end
 end
 else begin r_m = b_m - a_m; results[31] = 1'b0; end
 end
 else begin r_m = b_m - a_m; results[31] = 1'b0; end

 //Normalize
 // Verifica se o resultado é zero
 if (r_m == 32'd0) begin
     results = 32'd0; // Zero IEEE 754
 end
 else begin
     state = 1;
     i = 31;
        for (int k = 31; k >= 0; k = k - 1) begin
            if (r_m[k]) begin
                i = k;
                break;
            end
end


     r_exp = a_exp + i-22;

     if((i-22) > 0)
     prm = r_m >> $unsigned((i-22));
     else if((i-22) < 0)
     prm = r_m << $unsigned((22-i));
     else
     prm = r_m;

     //compose
     results[30:23] = r_exp;
     results[22:0] = prm[22:0];
 end
 end // end do else begin (casos não-zero)
 end

 endmodule
