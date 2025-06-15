module bcd_sumador (
    input [11:0] bcd_1,  // 3 dígitos BCD: {centenas, decenas, unidades}
    input [11:0] bcd_2,
    output [15:0] resultado_bcd  // 4 dígitos BCD: {miles, centenas, decenas, unidades}
);
    // variables internas para dividir el numero en unidades, decenas y centenas 
    logic [3:0] unidades_1 = bcd_1[3:0];
    logic [3:0] decenas_1 = bcd_1[7:4];
    logic [3:0] centenas_1 = bcd_1[11:8];

    logic [3:0] unidades_2 = bcd_2[3:0];
    logic [3:0] decenas_2 = bcd_2[7:4];
    logic [3:0] centenas_2 = bcd_2[11:8];


    // se utilizan MUX 2:1 
    // Suma de unidades
    logic [4:0] suma_unidades = unidades_1 + unidades_2;
    logic [3:0] unidades_final = (suma_unidades > 9) ? suma_unidades - 10 : suma_unidades;
    logic acarreo_unidades = (suma_unidades > 9);

    // Suma de decenas + acarreo
    logic [4:0] suma_decenas = decenas_1 + decenas_2 + acarreo_unidades;
    logic [3:0] decenas_final = (suma_decenas > 9) ? suma_decenas - 10 : suma_decenas;
    logic acarreo_decenas = (suma_decenas > 9);

    // Suma de centenas + acarreo
    logic [4:0] suma_centenas = centenas_1 + centenas_2 + acarreo_decenas;
    logic [3:0] centenas_final = (suma_centenas > 9) ? suma_centenas - 10 : suma_centenas;
    logic acarreo_centenas = (suma_centenas > 9);

    // Resultado final (4 dígitos BCD)
    assign resultado_bcd = {acarreo_centenas, centenas_final, decenas_final, unidades_final};

endmodule
