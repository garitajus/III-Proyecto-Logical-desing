module top(
    input logic clk,         // Reloj de 27 MHz
    input logic rst,         // Reset activo en bajo
    output logic [3:0] an,   // Ánodos del display (asumiendo 4 dígitos para el resultado)
    output logic [6:0] seg,  // Segmentos del display
    output logic [3:0] columnas, // Columnas del teclado
    input logic [3:0] filas    // Filas del teclado
);
    // Señales del teclado
    logic [3:0] key;
    logic key_pressed;
    logic key_pressed_prev; // Para detectar flancos de subida de key_pressed
    logic key_strobe;       // Pulso de un ciclo cuando se presiona una tecla nueva

    // Estados para la máquina de estados de ingreso/cálculo
    typedef enum logic [1:0] {
        STATE_INPUT_A,      // Ingresando número A
        STATE_INPUT_B,      // Ingresando número B
        STATE_SHOW_SUM      // Mostrando la suma
    } operation_state_t;

    operation_state_t current_state, next_state;

    // Números A y B (3 dígitos BCD cada uno)
    logic [3:0] A0, A1, A2; // Unidades, decenas, centenas de A
    logic [3:0] B0, B1, B2; // Unidades, decenas, centenas de B

    // Resultado de la suma (4 dígitos BCD)
    logic [15:0] sum_result; // {miles, centenas, decenas, unidades}

    // Datos a mostrar en el display (4 dígitos)
    logic [15:0] display_data;

    // Instancia del escáner del teclado
    keypad_scanner scanner(
        .clk(clk),
        .col(columnas),
        .row(filas),
        .key(key),          // Código de la tecla presionada
        .key_pressed(key_pressed) // Indicador de tecla presionada (puede durar varios ciclos)
    );

    // Detector de Flanco para Tecla Presionada
    // Genera un pulso de un ciclo 'key_strobe' cuando 'key_pressed' se activa
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            key_pressed_prev <= 1'b0;
            key_strobe <= 1'b0;
        end else begin
            key_pressed_prev <= key_pressed;
            // key_strobe es alto solo si key_pressed es alto AHORA y era bajo ANTES
            key_strobe <= key_pressed && !key_pressed_prev;
        end
    end

    // Lógica de Estado y Registro de Números
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= STATE_INPUT_A; // Estado inicial: ingresar A
            A0 <= 4'd0; A1 <= 4'd0; A2 <= 4'd0;
            B0 <= 4'd0; B1 <= 4'd0; B2 <= 4'd0;
        end else begin
            current_state <= next_state; // Actualizar estado

            // Solo registrar cambios si hay un pulso de tecla nueva (key_strobe)
            if (key_strobe) begin
                case (key)
                    // Tecla '*' (4'hE): Reiniciar todo
                    4'hE: begin
                        A0 <= 4'd0; A1 <= 4'd0; A2 <= 4'd0;
                        B0 <= 4'd0; B1 <= 4'd0; B2 <= 4'd0;
                        // El estado se reiniciará en la lógica de siguiente estado
                    end

                    // Tecla '#' (4'hF): Cambiar de estado o calcular
                    4'hF: begin
                        // La transición de estado se maneja en la lógica de siguiente estado
                    end

                    // Teclas numéricas (0-9)
                    default: begin
                        if (current_state == STATE_INPUT_A) begin
                            // Ingreso para A: desplazamiento izquierda
                            A2 <= A1;
                            A1 <= A0;
                            A0 <= key; // Asumiendo que 'key' contiene el valor BCD 0-9
                        end else if (current_state == STATE_INPUT_B) begin
                            // Ingreso para B: desplazamiento izquierda
                            B2 <= B1;
                            B1 <= B0;
                            B0 <= key; // Asumiendo que 'key' contiene el valor BCD 0-9
                        end
                        // No hacer nada si estamos en STATE_SHOW_SUM
                    end
                endcase
            end
        end
    end

    // Lógica de Siguiente Estado (Combinacional)
    always_comb begin
        next_state = current_state; // Por defecto, mantener el estado actual

        if (!rst) begin // Manejo explícito del reset asíncrono en la lógica combinacional
           next_state = STATE_INPUT_A;
        end else if (key_strobe) begin // Transición solo en flanco de tecla
            case (key)
                4'hE: begin // '*' Reiniciar
                    next_state = STATE_INPUT_A;
                end
                4'hF: begin // '#' Transición
                    case (current_state)
                        STATE_INPUT_A: next_state = STATE_INPUT_B; // De A -> B
                        STATE_INPUT_B: next_state = STATE_SHOW_SUM; // De B -> Suma
                        STATE_SHOW_SUM: next_state = STATE_INPUT_A; // De Suma -> A (para nuevo cálculo)
                        default: next_state = STATE_INPUT_A; // Estado inválido -> A
                    endcase
                end
                 // Para teclas numéricas, no cambiamos de estado
                default: begin
                    // Si se presiona un número mientras se muestra la suma, iniciar nueva entrada A
                    if (current_state == STATE_SHOW_SUM) begin
                         next_state = STATE_INPUT_A;
                         // Nota: El número presionado se registrará en A0 en el siguiente ciclo
                         // debido a la lógica en always_ff. Podríamos ajustar esto si
                         // quisiéramos borrar A antes, pero el comportamiento actual es razonable.
                    end else begin
                         next_state = current_state; // Mantener estado al ingresar dígitos
                    end
                end
            endcase
        end
    end

    // Instancia del Sumador BCD
    // Combina los dígitos de A y B para el sumador
    logic [11:0] bcd_A = {A2, A1, A0};
    logic [11:0] bcd_B = {B2, B1, B0};

    bcd_sumador sumador (
        .bcd_1(bcd_A),
        .bcd_2(bcd_B),
        .resultado_bcd(sum_result) // Salida directa del sumador (4 dígitos BCD)
    );

    // Lógica de Selección para el Display (Combinacional)
    always_comb begin
        case (current_state)
            STATE_INPUT_A:  display_data = {4'd0, A2, A1, A0}; // Muestra A (rellena con 0 a la izquierda)
            STATE_INPUT_B:  display_data = {4'd0, B2, B1, B0}; // Muestra B (rellena con 0 a la izquierda)
            STATE_SHOW_SUM: display_data = sum_result;         // Muestra la suma (4 dígitos)
            default:        display_data = 16'hFFFF;           // Indicador de estado inválido (ej: todos los segmentos encendidos)
        endcase
    end

  
    // Instancia del Display Multiplexado
    display_mux display (
        .clk(clk),
        .data(display_data), // Pasa el dato seleccionado al display
        .anodes(an),         // Controla qué dígito se enciende
        .seg(seg)            // Controla qué segmentos se encienden
    );

endmodule
