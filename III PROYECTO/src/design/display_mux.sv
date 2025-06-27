module display_mux (
    input  logic        clk,     // 27 MHz
    input  logic [15:0] data,    // {digit3, digit2, digit1, digit0}
    output logic [3:0]  anodes,  // Activo en bajo
    output logic [6:0]  seg
);
    logic [15:0] refresh_counter;
    logic [1:0] digit_select;
    logic [3:0] current_digit;

    always_ff @(posedge clk) begin
        if (refresh_counter == 27000 - 1) begin
            refresh_counter <= 0;
            digit_select <= digit_select + 1;
        end else begin
            refresh_counter <= refresh_counter + 1;
        end
    end

    always_comb begin
        case (digit_select)
            2'd0: begin anodes = 4'b1110; current_digit = data[3:0];   end
            2'd1: begin anodes = 4'b1101; current_digit = data[7:4];   end
            2'd2: begin anodes = 4'b1011; current_digit = data[11:8];  end
            2'd3: begin anodes = 4'b0111; current_digit = data[15:12]; end
            default: begin anodes = 4'b1111; current_digit = 4'hE;     end
        endcase
    end

    hex_to_7seg conv (
        .hex(current_digit),
        .seg(seg)
    );
endmodule
