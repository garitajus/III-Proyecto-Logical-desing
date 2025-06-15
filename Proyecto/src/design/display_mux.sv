module display_mux (
    input clk,
    input [15:0] data,
    output logic [3:0] anodes,
    output [6:0] seg
);
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