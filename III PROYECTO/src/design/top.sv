// ==================================================================
//  Proyecto: Calculadora de Multiplicación por Booth
//
//  Autores : Abner López, Justin Garita
//  Universidad: Instituto Técnologico de Costa Rica
//  Fecha   : I Semestre 2025
//
//  Descripción:
//    Módulo top que integra los siguientes subsistemas:
//      - Escaneo de teclado matricial 4×4 (keypad_scanner)
//      - FSM de ingreso de dos operandos con signo
//      - Conversión BCD→binario (bcd_to_bin)
//      - Multiplicación por Booth (booth_multiplier)
//      - Conversión binario→BCD (bin_to_bcd)
//      - Control de display multiplexado de 4 dígitos (display_mux)
//
//    Permite ingresar dos números de 0–9 (con signo) y calcular su producto,
//    mostrando signo y valor en un display de 7 segmentos.
// ==================================================================
module top(
    input logic clk,        // Reloj de 27 MHz
    input logic rst,        // Reset activo en bajo
    output logic [3:0] an,  // Ánodos del display
    output logic [6:0] seg, // Segmentos del display
    output logic [3:0] columnas, // Columnas del teclado
    input  logic [3:0] filas     // Filas del teclado
);

    // --- Señales del teclado ---
    logic [3:0] key;
    logic key_pressed, key_prev, key_strobe;

    keypad_scanner scanner (
        .clk(clk),
        .col(columnas),
        .row(filas),
        .key(key),
        .key_pressed(key_pressed)
    );

    // Pulso de tecla única
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            key_prev   <= 1'b0;
            key_strobe <= 1'b0;
        end else begin
            key_prev   <= key_pressed;
            key_strobe <= key_pressed && !key_prev;
        end
    end

    // --- FSM para controlar flujo ---
    typedef enum logic [1:0] {
        S_INPUT_A,
        S_INPUT_B,
        S_MUL_RESULT
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            state <= S_INPUT_A;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        if (key_strobe && key == 4'hF) begin  // '#' avanza estado
            case (state)
                S_INPUT_A:    next_state = S_INPUT_B;
                S_INPUT_B:    next_state = S_MUL_RESULT;
                S_MUL_RESULT: next_state = S_INPUT_A;
            endcase
        end
    end

    // --- Entradas de A y B ---
    logic [3:0] A_bcd, B_bcd;
    logic A_sign, B_sign;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            A_bcd <= 4'd0; A_sign <= 1'b0;
            B_bcd <= 4'd0; B_sign <= 1'b0;
        end else if (key_strobe) begin
            case (key)
                4'hE: begin // '*' reinicia entradas
                    A_bcd <= 4'd0; A_sign <= 1'b0;
                    B_bcd <= 4'd0; B_sign <= 1'b0;
                end
                4'hA: begin // tecla A = negativo
                    if (state == S_INPUT_A) A_sign <= 1'b1;
                    else if (state == S_INPUT_B) B_sign <= 1'b1;
                end
                4'hB: begin // tecla B = positivo
                    if (state == S_INPUT_A) A_sign <= 1'b0;
                    else if (state == S_INPUT_B) B_sign <= 1'b0;
                end
                // Comparación explícita para 0–9
                4'h0, 4'h1, 4'h2, 4'h3, 4'h4,
                4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin
                    if (state == S_INPUT_A) A_bcd <= key;
                    else if (state == S_INPUT_B) B_bcd <= key;
                end
                default: ; // Ignorar letras C, D, etc.
            endcase
        end
    end

    // --- Conversión BCD -> Binario ---
    logic signed [4:0] A_bin, B_bin;
    bcd_to_bin convA (.units_bcd(A_bcd), .sign(A_sign), .bin_out(A_bin));
    bcd_to_bin convB (.units_bcd(B_bcd), .sign(B_sign), .bin_out(B_bin));

    // --- Multiplicador Booth ---
    logic start_mul, done_mul;
    logic signed [9:0] result;

    booth_multiplier #(.N(5)) mul (
        .clk(clk),
        .rst(rst),
        .start(start_mul),
        .multiplicand(A_bin),
        .multiplier(B_bin),
        .product(result),
        .done(done_mul)
    );

    always_ff @(posedge clk or negedge rst) begin // cuando # inicia la multiplicación 
        if (!rst)
            start_mul <= 1'b0;
        else
            start_mul <= (key_strobe && key == 4'hF && state == S_INPUT_B);
    end

    // --- Resultado a BCD ---
    logic [6:0] result_abs;
    assign result_abs = (result < 0) ? -result : result;

    logic [11:0] result_bcd;
    bin_to_bcd bcd_converter (
        .bin_ent(result_abs),
        .bcd_out(result_bcd)
    );

    logic [3:0] signo;
    assign signo = (result < 0) ? 4'hA : 4'hF; // A = '-', F = blanco

    // --- Display final ---
    logic [15:0] display_data;
    always_comb begin
        case (state)
            S_INPUT_A: begin
                if (A_sign)
                    display_data = {8'hBBB, 4'hA, A_bcd};  // -A
                else
                    display_data = {8'hBBB, 4'hB, A_bcd};       // A
            end
            S_INPUT_B: begin
                if (B_sign)
                   display_data = {8'hBBB, 4'hA, B_bcd};  // -B
                else
                    display_data = {8'hBBB, 4'hB, B_bcd};       // B
            end
           S_MUL_RESULT: begin
            // Apagar dígito más a la izquierda (an[3]), luego mostrar: signo, decena, unidad
             display_data = {4'hF, signo, result_bcd[7:0]};
            end

            default: display_data = 16'hFFFF;
        endcase
    end


    display_mux display (
        .clk(clk),
        .data(display_data),
        .anodes(an),
        .seg(seg)
    );
endmodule
