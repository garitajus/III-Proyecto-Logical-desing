module bcd_to_bin (
    input  logic [3:0] units_bcd,        // solo unidades 0..9
    input  logic       sign,              // 0 = positivo, 1 = negativo
    output logic signed [4:0] bin_out    // rango -9..9 cabe en 5 bits con signo
);
    logic [4:0] unsigned_bin;

    always_comb begin
        // Extender a 5 bits sin signo para poder convertir a signed
        unsigned_bin = {1'b0, units_bcd};
        
        // Aplicar signo
        if (sign)
            bin_out = -$signed(unsigned_bin);
        else
            bin_out = $signed(unsigned_bin);
    end
endmodule
