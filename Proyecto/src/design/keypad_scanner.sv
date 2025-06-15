module keypad_scanner (
    input clk, 
    output logic [3:0] col = 4'b0111,
    input [3:0] row, 
    output logic [3:0] key = 4'h0, 
    output logic key_pressed = 0 
);
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
