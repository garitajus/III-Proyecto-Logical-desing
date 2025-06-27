module keypad_scanner (
    input clk,
    output logic [3:0] col,
    input  [3:0] row,
    output logic [3:0] key,
    output logic key_pressed
);
    parameter SCAN_DELAY = 1350;

    localparam SCAN    = 2'b00;
    localparam WAIT    = 2'b01;
    localparam DETECT  = 2'b10;
    localparam RELEASE = 2'b11;

    logic [1:0] state = SCAN;
    logic [1:0] col_select = 0;
    logic [15:0] counter = 0;
    logic [3:0] row_pressed;

    // Instanciar debounce para cada fila (activo bajo)
    // rst = 1 (no reset)
    debounce db0(.clk(clk), .rst(1'b1), .key(~row[0]), .key_pressed(row_pressed[0]));
    debounce db1(.clk(clk), .rst(1'b1), .key(~row[1]), .key_pressed(row_pressed[1]));
    debounce db2(.clk(clk), .rst(1'b1), .key(~row[2]), .key_pressed(row_pressed[2]));
    debounce db3(.clk(clk), .rst(1'b1), .key(~row[3]), .key_pressed(row_pressed[3]));

    // filas presionadas están en 1 (tecla presionada)
    logic any_key_pressed = |row_pressed;

    always_ff @(posedge clk) begin
        key_pressed <= 0;

        case(state)
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
                end else
                    counter <= counter + 1;
            end

            DETECT: begin
                if (any_key_pressed) begin
                    // Detectar qué fila está presionada (prioridad fila más baja)
                    case (row_pressed)
                        4'b0001: key <= decode_key(col_select, 0);
                        4'b0010: key <= decode_key(col_select, 1);
                        4'b0100: key <= decode_key(col_select, 2);
                        4'b1000: key <= decode_key(col_select, 3);
                        default: key <= 4'h0;
                    endcase
                    key_pressed <= 1;
                    state <= RELEASE;
                end else
                    state <= SCAN;
            end

            RELEASE: begin
                if (!any_key_pressed)
                    state <= SCAN;
                else
                    key_pressed <= 1;  // mantener la señal mientras sueltes
            end
        endcase
    end

    // Función para decodificar tecla según columna y fila
    function automatic [3:0] decode_key(input logic [1:0] col_sel, input logic [1:0] row_sel);
        begin
            case ({col_sel, row_sel})
                4'b0000: decode_key = 4'h1;
                4'b0001: decode_key = 4'h4;
                4'b0010: decode_key = 4'h7;
                4'b0011: decode_key = 4'hE;

                4'b0100: decode_key = 4'hA;
                4'b0101: decode_key = 4'hB;
                4'b0110: decode_key = 4'hC;
                4'b0111: decode_key = 4'hD;

                4'b1000: decode_key = 4'h3;
                4'b1001: decode_key = 4'h6;
                4'b1010: decode_key = 4'h9;
                4'b1011: decode_key = 4'hF;

                4'b1100: decode_key = 4'h2;
                4'b1101: decode_key = 4'h5;
                4'b1110: decode_key = 4'h8;
                4'b1111: decode_key = 4'h0;

                default: decode_key = 4'h0;
            endcase
        end
    endfunction

endmodule