# Tercer proyecto, diseño lógico, Algoritmo de Booth- Multiplicador con signo, elaborado por: Abner López Méndez y Justin Garita Serrano 

## 1. Funcionamiento general del circuito y explicación de cada modulo:
- **Introducción**: El proyecto consiste en el diseño e implementación de una calculadora decimal en VHDL específicamente en SystemVerilog, desarrollada para una FPGA (la Tang Nano 9K). El sistema permite al usuario ingresar dos números decimales de un dígito mediante un teclado matricial hexadecimal 4x4, realizar su multiplicación en formato binario haciendo uso del algoritmo de Booth y visualizar tanto los números ingresados como el resultado de la operación en un display de 7 segmentos de 4 dígitos.
El sistema consta de tres subsistemas principales:
keypad scanner: detecta la tecla presionada por el usuario y genera un código BCD correspondiente. Se implementa un detector de flanco (key_pressed) para evitar múltiples registros de una misma tecla.
Control lógico (FSM): una máquina de estados finitos gestiona el flujo de operación del sistema, desde la captura del primer número (A), el segundo número (B), hasta la visualización de la multiplicación. Las teclas especiales permiten avanzar entre estados (#), colocar el signo negativo (A) o reiniciar el sistema (*).
Procesamiento y visualización:
Los números se almacenan en formato binario 
Un módulo de multiplicación realiza la operación en formato binario, generando un resultado de hasta 3 dígitos (centenas, decenas, unidades).
Un sistema de multiplexado de displays permite mostrar dinámicamente los dígitos en los 3 displays de 7 segmentos.
El diseño está pensado para operar con un reloj de 27 MHz y fue desarrollado con una estructura modular clara que facilita la síntesis y carga en una FPGA.

## 2. Definición general del problema, de los objetivos buscados y de las especificaciones planteadas en el enunciado:
En este proyecto se pide implementar un sistema digital integrado capaz de realizar operaciones aritméticas básicas con entrada mediante teclado matricial y visualización en displays de 7 segmentos, resolviendo los desafíos típicos en el desarrollo de interfaces de usuario. El problema principal radica en coordinar tres subsistemas clave: la captura confiable de entradas mediante un teclado matricial 4x4 (considerando el filtrado de rebotes), el procesamiento aritmético en formato binario (para mantener precisión decimal) y la visualización multiplexada en displays de 7 segmentos (que demanda refresco constante). Los objetivos específicos incluyen diseñar una calculadora básica que permita ingresar números de hasta dígito, realizar muktiplicaciones utilizando el algoritmo de Booth correctamente y mostrar resultados de hasta 3 dígitos, implementando técnicas robustas de sincronización y control de estados. Las especificaciones técnicas requieren operación a 27 MHz con reset asíncrono, manejo de entradas mediante un teclado matricial con teclas numéricas (0-9) y de control, visualización estable en displays de 7 segmentos con refresco a aproximadamente 1 kHz, y capacidad para sumar valores entre 0-999 produciendo resultados correctos en el rango 0-1998. El diseño debe ser eficiente en el uso de recursos lógicos, optimizado para implementación en FPGAs, cumpliendo con requisitos de consumo de potencia y área mediante técnicas de diseño modular y sincronización precisa de señales.

## 3. Explicación de los modulos:
- **Módulo de lectura del teclado**: Encabezado del módulo
```SystemVerilog
module keypad_scanner (
    input clk, 
    input [3:0] row, 
    output logic [3:0] key = 4'h0, 
    output logic key_pressed = 0
    output logic [3:0] col = 4'b0111,
);
```
Este módulo tiene como entradas el reloj del sistema, y las filas del teclado hexadecimal y como salidas la tecla ingresada codificada, las columnas del teclado y una bandera de cual es la tecla que se presionó.
```SystemVerilog
    parameter SCAN_DELAY = 1350;

    localparam SCAN = 2'b00;
    localparam WAIT = 2'b01;
    localparam DETECT = 2'b10;

    logic [1:0] state = SCAN;
    logic [1:0] col_select = 0;
    logic [15:0] counter = 0;
    logic [3:0] last_row;
    logic [3:0] row_debounced;
    logic [3:0] row_pressed;

    // Instancias del módulo debounce 
    debounce db_inst0 (
        .clk(clk),
        .rst(1'b1),
        .key(~row[0]),
        .key_pressed(row_pressed[0])
    );
    assign row_debounced[0] = ~row_pressed[0];

    debounce db_inst1 (
        .clk(clk),
        .rst(1'b1),
        .key(~row[1]),
        .key_pressed(row_pressed[1])
    );
    assign row_debounced[1] = ~row_pressed[1];

    debounce db_inst2 (
        .clk(clk),
        .rst(1'b1),
        .key(~row[2]),
        .key_pressed(row_pressed[2])
    );
    assign row_debounced[2] = ~row_pressed[2];

    debounce db_inst3 (
        .clk(clk),
        .rst(1'b1),
        .key(~row[3]),
        .key_pressed(row_pressed[3])
    );
    assign row_debounced[3] = ~row_pressed[3];

    always @(posedge clk) begin
        key_pressed <= 0;

        case (state)
            SCAN: begin
                col_select <= col_select + 1;
                case (col_select)
                    2'b00: col <= 4'b0111;
                    2'b01: col <= 4'b1011;
                    2'b10: col <= 4'b1101;
                    2'b11: col <= 4'b1110;
                endcase
                counter <= 0;
                state <= WAIT;
            end

            WAIT: begin
                if (counter == SCAN_DELAY) begin
                    state <= DETECT;
                    counter <= 0;
                end else begin
                    counter <= counter + 1;
                end
            end

            DETECT: begin
                if (row_debounced != 4'b1111) begin
                    last_row <= row_debounced;

                    case ({col_select, row_debounced})
                        6'b00_1110: key <= 4'h1;
                        6'b00_1101: key <= 4'h4;
                        6'b00_1011: key <= 4'h7;

                        6'b11_1110: key <= 4'h2;
                        6'b11_1101: key <= 4'h5;
                        6'b11_1011: key <= 4'h8;
                        6'b11_0111: key <= 4'h0;

                        6'b10_1110: key <= 4'h3;
                        6'b10_1101: key <= 4'h6;
                        6'b10_1011: key <= 4'h9;
                        6'b10_0111: key <= 4'hF;

                        6'b01_1110: key <= 4'hA;
                        6'b01_1101: key <= 4'hB;
                        6'b01_1011: key <= 4'hC;
                        6'b01_0111: key <= 4'hD;
                    endcase
                    
                    key_pressed <= 1;
                end
                state <= SCAN;
            end
        endcase
    end
endmodule

```
Este módulo implementa un escáner para el teclado 4x4 que se utilizó, instanciando por cada fila el módulo de anti-rebote que se explicará más adelante. Funciona activando secuencialmente cada una de las cuatro columnas del teclado (señal col, activas en bajo) mientras monitorea el estado de las cuatro filas (señal row). Cuando detecta una pulsación (fila activa en bajo), utiliza una máquina de estados de tres estados: SCAN (cambio de columna), WAIT (retardo de estabilización SCAN_DELAY) y DETECT (decodificación de tecla).
Cada fila pasa por un módulo debounce independiente para eliminar ruido mecánico, generando señales estables en row_debounced. La combinación de la columna activa (col_select) y la fila presionada se traduce a un código hexadecimal de 4 bits (key), con valores del 0x0 al 0xF. La salida key_pressed se activa durante un ciclo de reloj al detectar una tecla válida.


- **Módulo de eliminación de rebote**: Encabezado del módulo
```SystemVerilog
module debounce (
    input  logic clk,
    input  logic rst,          
    input  logic key,            
    output logic key_pressed     
);
```
Este módulo tiene como entradas el reset, el reloj del sistema, la tecla con la señal inestable y como salida la palabra ya estable lista para utilizar en los demás modulos.
```SystemVerilog
   parameter N = 6;
    parameter integer COUNT = 15_000_000; 

    logic [N-1:0] reg_sat, reg_next;
    logic SAMPLE1, SAMPLE2;
    logic reg_reset = (SAMPLE1 ^ SAMPLE2);
    logic reg_add   = ~reg_sat[N-1];

    logic [31:0] counter;
    logic active;

    always_comb begin
        case ({reg_reset, reg_add})
            2'b00: reg_next = reg_sat;
            2'b01: reg_next = reg_sat + 1;
            default: reg_next = {N{1'b0}};
        endcase
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            SAMPLE1        <= 0;
            SAMPLE2        <= 0;
            reg_sat       <= 0;
            key_pressed <= 0;
            active      <= 0;
            counter     <= 0;
        end else begin
            SAMPLE1  <= key;
            SAMPLE2  <= SAMPLE1;
            reg_sat <= reg_next;

            if (reg_sat[N-1] && SAMPLE2 && !active) begin
                key_pressed <= 1;
                active      <= 1;
                counter     <= 0;
            end else if (active) begin
                if (counter < COUNT) begin
                    counter <= counter + 1;
                end else begin
                    key_pressed <= 0;
                    active      <= 0;
                end
            end
        end
    end

endmodule
```
Este módulo elimina los rebotes (señal ruidosa) de botones mecánicos mediante un filtrado digital. Sincroniza la señal de entrada (key) con el reloj (clk) usando flip-flops, luego valida que el estado se mantenga estable durante 4 ciclos de reloj antes de registrar la pulsación en key_pressed. Incluye un reset (rst) para inicialización y es ideal para sistemas con relojes rápidos (como 27 MHz), garantizando que solo se detecten pulsaciones reales y evitando falsos triggers por vibraciones mecánicas.

- **Módulo de multiplexación de 7 segmentos**: Encabezado del módulo
```SystemVerilog
module display_mux (
    input clk,
    input [15:0] data,
    output logic [3:0] anodes,
    output [6:0] seg
);
```
Este módulo tiene como entradas el reloj del sistema, el número de 16 bits dividido en 4 numeros de 4 bits, miles, centenas, decenas y unidades. Cuenta con 4 salidas, para cada uno de los 4 displays de 7 segmentos controlados cada uno con un transistor PNP 2N4403, y la otra salida es cada uno de los 7 segmentos. 
```SystemVerilog
 logic [1:0] digit_select = 0;
    logic [3:0] current_digit;
    logic [15:0] refresh_counter = 0;
    
    hex_to_7seg converter(.hex(current_digit), .seg(seg));
    
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
        
        if (refresh_counter == 27000) begin // ~1kHz @27MHz
            refresh_counter <= 0;
            digit_select <= digit_select + 1;
            
            case (digit_select)
                2'b00: begin anodes <= 4'b1110; current_digit <= data[3:0]; end
                2'b01: begin anodes <= 4'b1101; current_digit <= data[7:4]; end
                2'b10: begin anodes <= 4'b1011; current_digit <= data[11:8]; end
                2'b11: begin anodes <= 4'b0111; current_digit <= data[15:12]; end
            endcase
        end
    end
endmodule
```
Este módulo implementa un multiplexor para controlar un display de 4 dígitos de 7 segmentos mediante barrido (multiplexación temporal). Trabaja con un reloj de sistema (27MHz) y alterna cíclicamente entre los cuatro dígitos a una frecuencia de aproximadamente 1kHz (cambiando cada 27,000 ciclos), activando secuencialmente cada ánodo (señal anodes, activo en bajo) mientras envía al bus común de segmentos (seg) el valor correspondiente del dato de entrada de 16 bits (data), convertido a código 7 segmentos mediante el módulo hex_to_7seg. El sistema divide el dato de entrada en cuatro nibbles (de 4 bits cada uno) que representan dígitos decimales, mostrándolos en rápida sucesión para crear la ilusión de visualización continua gracias a la persistencia visual (aproximadamente 250Hz por cada display). Esta técnica permite controlar múltiples dígitos con un mínimo de pines, optimizando los recursos del FPGA.

- **Modulo de conversión de hexadecimal a 7 segmentos**: Encabezado del módulo
```SystemVerilog
module hex_to_7seg (
    input [3:0] hex,
    output reg [6:0] 
);
```
Este módulo tiene como entrada las teclas en hexadecimal, y como salida esas mismas palabras pero codificadas para un display de 7 segmentos
```SystemVerilog
    always @(hex) begin
        case (hex)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001; 
            4'h2: seg = 7'b0100100; 
            4'h3: seg = 7'b0110000; 
            4'h4: seg = 7'b0011001; 
            4'h5: seg = 7'b0010010; 
            4'h6: seg = 7'b0000010; 
            4'h7: seg = 7'b1111000; 
            4'h8: seg = 7'b0000000; 
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000; 
            4'hB: seg = 7'b0000011; 
            4'hC: seg = 7'b1000110; 
            4'hD: seg = 7'b0100001; 
            4'hE: seg = 7'b1111110; 
            4'hF: seg = 7'b0111111; 

            default: seg = 7'b1111111; 
        endcase
    end         
endmodule
```
Este módulo convierte un valor hexadecimal de 4 bits (0-F) en su correspondiente patrón de encendido para un display de 7 segmentos, donde cada bit de la salida seg controla un segmento específico. Utiliza una lógica combinacional mediante una sentencia case que mapea cada valor hexadecimal a su configuración de segmentos correspondiente, activando los segmentos necesarios para formar el dígito deseado (el display es de ánodo común ). Por ejemplo, el valor 4'h0 (0 en hexadecimal) se traduce a 7'b1000000, lo que enciende todos los segmentos excepto el 'g', formando el número 0 en el display. El módulo incluye un caso default que apaga todos los segmentos si el valor de entrada no está en el rango esperado, asegurando un comportamiento predecible incluso con entradas no definidas.

- **Módulo de multiplicación**: Encabezado del módulo
```SystemVerilog
module booth_multiplier #(parameter N = 5)(
    input logic clk,
    input logic rst, 
    input logic start,
    input logic signed [N-1:0] multiplicand,
    input logic signed [N-1:0] multiplier,
    output logic signed [2*N-1:0] product,
    output logic done
); 
```
Este módulo tiene como entradas el multiplicando y el multiplicador 

```SystemVerilog
     typedef enum logic [1:0] { IDLE, CALC, SHIFT, FINISH } state_t;
    state_t state;

    logic signed [N:0]   AC;  
    logic signed [N-1:0] QR, BR; 
    logic                Q_1; 
    logic [$clog2(N)-1:0] SC; 

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state   <= IDLE;
            done    <= 1'b0;
            product <= 0;
            AC      <= 0;
            QR      <= 0;
            Q_1     <= 1'b0;
            SC      <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        AC    <= 0;
                        QR    <= multiplier;
                        BR    <= multiplicand;
                        Q_1   <= 1'b0;
                        SC    <= N;
                        state <= CALC;
                    end
                end

                CALC: begin
                    case ({QR[0], Q_1})
                        2'b01: AC <= AC + BR;
                        2'b10: AC <= AC - BR;
                        default: ;
                    endcase
                    state <= SHIFT;
                end

                SHIFT: begin
                    
                    Q_1      <= QR[0];
                    QR       <= {AC[0], QR[N-1:1]};
                    AC       <= {AC[N], AC[N:1]}; 
                    
                    SC <= SC - 1;
                    if (SC == 1) begin 
                        state <= FINISH;
                    end else begin
                        state <= CALC;
                    end
                end

                FINISH: begin
                 
                    product <= {AC[N-1:0], QR};
                    done  <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
```
Este modulo implementa el algoritmo de Booth para realizar una multiplicación de números con signo en complemento a 2 de 5 bits. Utilizando una FSM (IDLE, CALC, SHIFT, FINISH), controla el proceso de multiplicación, en cada ciclo, evalúa los bits del multiplicador (según la regla de Booth) para sumar o restar el multiplicando al acumulador (AC), realiza desplazamientos aritméticos y repite el proceso hasta completar N iteraciones. Finalmente, concatena los registros AC y QR para formar el producto de 2*N bits y señala que la operación fue completada con la señal DONE.

- **Modulo convertidor de BCD a Binario**: Encabezado del módulo
```SystemVerilog
module bcd_to_bin (
    input  logic [3:0] units_bcd,        
    input  logic       sign,              
    output logic signed [4:0] bin_out 
);
```
Este módulo tiene como entrada el numero en formato BCD y tiene como salida ese número BCD convertido a Binario
```SystemVerilog
    logic [4:0] unsigned_bin;

    always_comb begin
        unsigned_bin = {1'b0, units_bcd};
        if (sign)
            bin_out = -$signed(unsigned_bin);
        else
            bin_out = $signed(unsigned_bin);
    end

```
Este módulo convierte un dígito BCD del 0 al 9 a su representación binaria en comolemento a 2. Si la entrada sing es 1, el módulo calcula el valor negativo del número BCD, si es 0, mantiene su valor original. La salida es un número binario de 5 bits con signo, capaz de representar números del -9 al 9. La conversión se realiza por medio de la extensión de bits y aplicación condicional del signo usando complemento a 2.

- **Modulo convertidor de Binario a BCD**: Encabezado del módulo
 ```SystemVerilog
module bin_to_bcd (
    input  logic [6:0] bin_ent,     
    output logic [11:0] bcd_out     
);
```
La entrada de este modulo es un número binario y su salida es un número en formato BCD
```SystemVerilog
    always_comb begin
        case (bin_ent)
            7'd0:  bcd_out = 12'h000;
            7'd1:  bcd_out = 12'h001;
            7'd2:  bcd_out = 12'h002;
            7'd3:  bcd_out = 12'h003;
            7'd4:  bcd_out = 12'h004;
            7'd5:  bcd_out = 12'h005;
            7'd6:  bcd_out = 12'h006;
            7'd7:  bcd_out = 12'h007;
            7'd8:  bcd_out = 12'h008;
            7'd9:  bcd_out = 12'h009;
            7'd10: bcd_out = 12'h010;
            7'd11: bcd_out = 12'h011;
            7'd12: bcd_out = 12'h012;
            7'd13: bcd_out = 12'h013;
            7'd14: bcd_out = 12'h014;
            7'd15: bcd_out = 12'h015;
            7'd16: bcd_out = 12'h016;
            7'd17: bcd_out = 12'h017;
            7'd18: bcd_out = 12'h018;
            7'd19: bcd_out = 12'h019;
            7'd20: bcd_out = 12'h020;
            7'd21: bcd_out = 12'h021;
            7'd22: bcd_out = 12'h022;
            7'd23: bcd_out = 12'h023;
            7'd24: bcd_out = 12'h024;
            7'd25: bcd_out = 12'h025;
            7'd26: bcd_out = 12'h026;
            7'd27: bcd_out = 12'h027;
            7'd28: bcd_out = 12'h028;
            7'd29: bcd_out = 12'h029;
            7'd30: bcd_out = 12'h030;
            7'd31: bcd_out = 12'h031;
            7'd32: bcd_out = 12'h032;
            7'd33: bcd_out = 12'h033;
            7'd34: bcd_out = 12'h034;
            7'd35: bcd_out = 12'h035;
            7'd36: bcd_out = 12'h036;
            7'd37: bcd_out = 12'h037;
            7'd38: bcd_out = 12'h038;
            7'd39: bcd_out = 12'h039;
            7'd40: bcd_out = 12'h040;
            7'd41: bcd_out = 12'h041;
            7'd42: bcd_out = 12'h042;
            7'd43: bcd_out = 12'h043;
            7'd44: bcd_out = 12'h044;
            7'd45: bcd_out = 12'h045;
            7'd46: bcd_out = 12'h046;
            7'd47: bcd_out = 12'h047;
            7'd48: bcd_out = 12'h048;
            7'd49: bcd_out = 12'h049;
            7'd50: bcd_out = 12'h050;
            7'd51: bcd_out = 12'h051;
            7'd52: bcd_out = 12'h052;
            7'd53: bcd_out = 12'h053;
            7'd54: bcd_out = 12'h054;
            7'd55: bcd_out = 12'h055;
            7'd56: bcd_out = 12'h056;
            7'd57: bcd_out = 12'h057;
            7'd58: bcd_out = 12'h058;
            7'd59: bcd_out = 12'h059;
            7'd60: bcd_out = 12'h060;
            7'd61: bcd_out = 12'h061;
            7'd62: bcd_out = 12'h062;
            7'd63: bcd_out = 12'h063;
            7'd64: bcd_out = 12'h064;
            7'd65: bcd_out = 12'h065;
            7'd66: bcd_out = 12'h066;
            7'd67: bcd_out = 12'h067;
            7'd68: bcd_out = 12'h068;
            7'd69: bcd_out = 12'h069;
            7'd70: bcd_out = 12'h070;
            7'd71: bcd_out = 12'h071;
            7'd72: bcd_out = 12'h072;
            7'd73: bcd_out = 12'h073;
            7'd74: bcd_out = 12'h074;
            7'd75: bcd_out = 12'h075;
            7'd76: bcd_out = 12'h076;
            7'd77: bcd_out = 12'h077;
            7'd78: bcd_out = 12'h078;
            7'd79: bcd_out = 12'h079;
            7'd80: bcd_out = 12'h080;
            7'd81: bcd_out = 12'h081;
            default: bcd_out = 12'hFFF; 
        endcase
    end

```
Este modulo se encarga de convertir un número binario de 7 bits (0 al 81) en su equivalente BCD de 12 bits, organizado en centenas, decenas y ub¿nidades. Utiliza la tabla de búsqueda (LUT) implementada con un case, que asigna diractamente cada valor binario de entrada a su representación BCD correspondiente. Si la entrada está fuera de ranfo válido devuelve los displays en 000. Es un diseño combinacional.

- **Modulo Principal del diseño**: Encabezado del módulo
```SystemVerilog
module top(
    input logic clk,        
    input logic rst,        
    output logic [3:0] an, 
    output logic [6:0] seg, 
    output logic [3:0] columnas, 
    input  logic [3:0] filas     
);
```
Este modulo tiene como entradas el clk y el rst. Como salidas tiene las salidas para cada ánodo, cada segmento, las columnas del teclado y una entrada de las filas del teclado.

```SystemVerilog
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
        if (key_strobe && key == 4'hF) begin 
            case (state)
                S_INPUT_A:    next_state = S_INPUT_B;
                S_INPUT_B:    next_state = S_MUL_RESULT;
                S_MUL_RESULT: next_state = S_INPUT_A;
            endcase
        end
    end

    logic [3:0] A_bcd, B_bcd;
    logic A_sign, B_sign;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            A_bcd <= 4'd0; A_sign <= 1'b0;
            B_bcd <= 4'd0; B_sign <= 1'b0;
        end else if (key_strobe) begin
            case (key)
                4'hE: begin 
                    A_bcd <= 4'd0; A_sign <= 1'b0;
                    B_bcd <= 4'd0; B_sign <= 1'b0;
                end
                4'hA: begin 
                    if (state == S_INPUT_A) A_sign <= 1'b1;
                    else if (state == S_INPUT_B) B_sign <= 1'b1;
                end
                4'hB: begin 
                    if (state == S_INPUT_A) A_sign <= 1'b0;
                    else if (state == S_INPUT_B) B_sign <= 1'b0;
                end
                4'h0, 4'h1, 4'h2, 4'h3, 4'h4,
                4'h5, 4'h6, 4'h7, 4'h8, 4'h9: begin
                    if (state == S_INPUT_A) A_bcd <= key;
                    else if (state == S_INPUT_B) B_bcd <= key;
                end
                default: ; 
            endcase
        end
    end

    logic signed [4:0] A_bin, B_bin;
    bcd_to_bin convA (.units_bcd(A_bcd), .sign(A_sign), .bin_out(A_bin));
    bcd_to_bin convB (.units_bcd(B_bcd), .sign(B_sign), .bin_out(B_bin));

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

    logic [6:0] result_abs;
    assign result_abs = (result < 0) ? -result : result;

    logic [11:0] result_bcd;
    bin_to_bcd bcd_converter (
        .bin_ent(result_abs),
        .bcd_out(result_bcd)
    );

    logic [3:0] signo;
    assign signo = (result < 0) ? 4'hA : 4'hF; // A = '-', F = blanco

    logic [15:0] display_data;
    always_comb begin
        case (state)
            S_INPUT_A: begin
                if (A_sign)
                    display_data = {8'hBBB, 4'hA, A_bcd};  
                else
                    display_data = {8'hBBB, 4'hB, A_bcd};       
            end
            S_INPUT_B: begin
                if (B_sign)
                   display_data = {8'hBBB, 4'hA, B_bcd};  
                else
                    display_data = {8'hBBB, 4'hB, B_bcd};       
            end
           S_MUL_RESULT: begin
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
```
El módulo top integra una calculadora basada en el algoritmo de Booth que permite ingresar dos números con signo (0-9) mediante un teclado matricial 4×4, convertirlos de BCD a binario, multiplicarlos usando el módulo booth_multiplier, y mostrar el resultado en un display de 7 segmentos. El sistema, controlado por una FSM (Máquina de Estados Finitos), maneja tres estados: entrada del primer operando (S_INPUT_A), entrada del segundo operando (S_INPUT_B) y visualización del resultado (S_MUL_RESULT). Los datos se procesan en tiempo real, convirtiendo el resultado binario a BCD para su visualización, incluyendo el signo negativo si es necesario. El diseño utiliza multiplexación de displays para mostrar dígitos individuales y señales de control para teclas especiales (como # para avanzar, * para resetear, A para colocar el negativo).

## 4. Diagramas de bloques de cada subsistema y su funcionamiento fundamental.

Anti reobte. [Ver pdf del Debounce](assets/debounce.pdf)

![Debounce](assets/debounce.jpeg) 

Escáner del teclado. [Ver pdf del keypad_scanner](assets/key_scanner.pdf)

![Keypad Scanner](assets/keypad_scanner.jpeg)

Multiplexación para los 7 segmentos. [Ver pdf del Display Mux](assets/display_mux.pdf)

![Display Mux](assets/display_mux.png)

Módulo de los 7 segementos. [Ver pdf del Hex to 7seg](assets/hex_to_7seg.pdf)

![Hex to seg](assets/hex_to_seg.png)

Módulo encargado para pasar el número de BCD a binario. [Ver pdf del BCD_to_bin](assets/bcd_to_bin.pdf)

![BCD sumador](assets/bcd_to_bin.jpeg)

Módulo encargado para pasar el número de binario a BCD. [Ver pdf del bin_to_BCD](assets/bin_to_bcd.pdf)

![BCD sumador](assets/bin_to_bcd.jpeg)

Módulo encargado de realizar la multiplicación. [Ver pdf de la FSM_BOOTH](assets/booth_multiplier.pdf)

![BCD sumador](assets/mult.jpeg)

Módulo Top. [Ver pdf del Top](assets/top.pdf)

Este módulo al ser tan grande no se pudo redimensionar

![Módulo top](assets/top.jpeg)

## 5. Diagramas de estado de las FSM diseñadas, según descritos en la sección anterior.

#### Máquina de estado para el escáner del teclado
Esta FSM controla el escaneo del teclado matricial 4x4.
![FSM_scanner](assets/FSM_scanner.png)

#### Máquina de estado del top
Según el estado actual, decides si registrar un número, hacer la multiplicación, mostrar el resultado o reiniciar.
![FSM_top](assets/FSM_top.png)

#### Máquina de estado para la multiplicación
Se realiza una multiplicación de dos números con signo usando el algoritmo de Booth controlado por una FSM secuencial.
![FSM_top](assets/FSM_mult.png)

## 6. Ejemplo y análisis de una simulación funcional del sistema completo, desde el estímulo de entrada hasta el manejo de los 7 segmentos.


![prueba de referencia](assets/GTKwave.jpg)

```Verilog
VCD info: dumpfile simulation.vcd opened for output.
Ingresando número A: 123
Presionando tecla:  3
Presionando tecla:  2
Presionando tecla:  1
Presionando tecla especial: f (#)
Ingresando número B: 456
Presionando tecla:  6
Presionando tecla:  5
Presionando tecla:  4
Presionando tecla especial: f (#)
Verificando suma: 123 + 456 = 579
~~~~~~~~~~Reiniciando...~~~~~~~~~~
Presionando tecla especial: e (*)
Ingresando nuevo número A: 789
Presionando tecla:  9
Presionando tecla:  8
Presionando tecla:  7
Presionando tecla especial: f (#)
Ingresando nuevo número B: 123
Presionando tecla:  3
Presionando tecla:  2
Presionando tecla:  1
Presionando tecla especial: f (#)
Verificando suma: 789 + 123 = 912
Simulaci├│n completada
../sim/tb_top.sv:90: $finish called at 4600000 (1ps)
```
El módulo top implementa un sistema de captura y multiplicación de dos números decimales de un dígito ingresados desde un teclado matricial 4x4. Utiliza una máquina de estados finitos (FSM) con tres estados: ingreso del primer número (A), ingreso del segundo número (B) y visualización del resultado de la multiplicación. A medida que se presionan teclas numéricas, los dígitos se registran desplazándolos hacia la izquierda, y al presionar la tecla # (código F) se cambia de estado. Una vez capturados ambos números, se realiza la multiplicación en formato binario en complemento a 2 y se muestra el resultado en un display de 7 segmentos multiplexado. Todo el sistema se sincroniza con un reloj de 27 MHz y permite reiniciar la operación mediante la tecla * (código E). En esta ocación no logramos diseñar un testbench funcional, sin embargo, todos los módulos fueron testeados uno a uno, asegurando su correcto funcionamiento 

## 7. Análisis de consumo de recursos en la FPGA (LUTs, FFs, etc.) y del consumo de potencia que reporta las herramientas.

```verilog
=== top ===

   Number of wires:                490
   Number of wire bits:           2049
   Number of public wires:         490
   Number of public wire bits:    2049
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:               1059
     ALU                           354
     DFF                             8
     DFFC                            8
     DFFCE                          35
     DFFE                           18
     DFFP                            2
     DFFR                           17
     DFFRE                         169
     DFFS                            4
     DFFSE                           4
     GND                             1
     IBUF                            6
     LUT1                          105
     LUT2                           58
     LUT3                           53
     LUT4                          119
     MUX2_LUT5                      53
     MUX2_LUT6                      20
     MUX2_LUT7                       9
     OBUF                           15
     VCC                             1
```

Esta implementación corresponde a una calculadora digital con soporte para multiplicación con signo mediante el algoritmo de Booth, capaz de operar sobre operandos ingresados desde un teclado matricial. El diseño sintetiza 490 señales públicas, sumando 2049 bits, y un total de 1059 celdas lógicas.
Destacan 354 unidades ALU, reflejando la actividad aritmética que incluye no solo la multiplicación secuencial tipo Booth, sino también la conversión de datos BCD↔binario y el cálculo de valor absoluto. La gestión de control y almacenamiento temporal se realiza mediante 269 flip-flops de distintos tipos (DFF, DFFR, DFFRE, DFFCE, etc.), necesarios para implementar la máquina de estados finitos (FSM), la secuencia de entrada de operandos y el control del multiplicador.
En cuanto a la lógica combinacional, se utilizan 335 LUTs de 1 a 4 entradas, donde predominan las LUT4 (119) y LUT1 (105), lo cual sugiere la presencia de funciones condicionales y decodificación de estados simples. Se emplean 82 multiplexores construidos con LUTs (como MUX2_LUT5 hasta MUX2_LUT7), esenciales para controlar el flujo de datos entre operandos, signo, y resultado final.
El diseño también integra 6 buffers de entrada (IBUF), 15 buffers de salida (OBUF) y las correspondientes señales de alimentación (GND y VCC). No se utilizan memorias RAM o ROM, lo cual indica que todo el almacenamiento se gestiona con registros distribuidos.

Realizando una medición directamente en la FPGA se determinó que la corriente que entrega es de aproximadamente 16.08mA, realizando el cálculo de potencia se determinó que la potencia consumida es de alrededor de 53.064mW 

## 8. Reporte de velocidades máximas de reloj posibles en el diseño.
```verilog
Info: Annotating ports with timing budgets for target frequency 27.00 MHz
Info: Checksum: 0xd5798977

Info: Device utilisation:
Info: 	                 VCC:     1/    1   100%
Info: 	               SLICE:   958/ 8640    11%
Info: 	                 IOB:    21/  274     7%
Info: 	                ODDR:     0/  274     0%
Info: 	           MUX2_LUT5:    53/ 4320     1%
Info: 	           MUX2_LUT6:    20/ 2160     0%
Info: 	           MUX2_LUT7:     9/ 1080     0%
Info: 	           MUX2_LUT8:     0/ 1056     0%
Info: 	                 GND:     1/    1   100%
Info: 	                RAMW:     0/  270     0%
Info: 	                 GSR:     1/    1   100%
Info: 	                 OSC:     0/    1     0%
Info: 	                rPLL:     0/    2     0%
```

## 9. Análisis de principales problemas hallados durante el trabajo y de las soluciones aplicadas.
Siguiente se enumeran los diversos problemas que se tuvieron a lo largo de la construcción de este proyecto y de igual forma cómo se solventaron.
#### 1.  Anti rebote, corrección y funcionalidad.
Para el módulo de antirrebote se tuvo que realizar una corrección con respecto al deseño, ya que, el diseño anterior no era funcional al 100%, en esta ocasión se optó por un diseño más claro y directo igualmente haciendo uso de FFs y registros para poder estabilizar la onda y verificar que realmente se presionó una tecla.
#### 2.  FSM para la multiplicación. 
La FSM que se implementó en el módulo top, fue una de las tareas más difíciles de completar ya que, en muchas ocaciones el sistema no respondía al teclado, o simplemente mostraba números al azar, sin embargo, por último pudimos realizar un correcto diseño de la FSM funcional.
#### 3.  Módulo para pasar un número de binario a formato BCD.
Este módulo presentó problemas, ya que, en todo¿as la implementaciones secuenciales que realizamos a la hora de dar el resultado de la multiplicacón mostraba resultados en hexadecimal por alguna razón, por último se optó por realizar el diseño de manera combinacional por medio de un LUT, donde se hace a ¨pie¨ pero en este caso fue la única forma en la que el diseño fue funcional.

## 10. Referencias
[0] Behzad R. *Fundamentals of Microelectronics*. Wiley, 2da edición, 2013.

[1] Floyd Thomas L. *Dispositivos Electrónicos*. Pearson Prentice Hall, 8va edición, 2008.

[2] Andrew House. Hex Keypad Explanation. Nov. de 2009. url: https://www-ug.eecg.toronto.edu/
 msl/nios_devices/datasheets/hex_expl.pdf.
 
[3] David Medina. Video tutorial para principiantes. Flujo abierto para TangNano 9k. Jul. de 2024. url:
 https://www.youtube.com/watch?v=AKO-SaOM7BA.
 
[4] David Medina. Wiki tutorial sobre el uso de la TangNano 9k y el flujo abierto de herramientas. Mayo de
 2024. url: https://github.com/DJosueMM/open_source_fpga_environment/wiki.

[5] Visual Electric. (2019, enero 14). State Machines - coding in Verilog with testbench and implementation on an FPGA [Video]. YouTube. https://youtu.be/tzxaf-CNU3Q

[6] Ekeeda. (2021, abril 3). HEX Keypad Interface using FPGA Theory [Video]. YouTube. https://youtu.be/eFP238KZaHo



