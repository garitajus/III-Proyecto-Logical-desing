module bin_to_bcd (
    input  logic [6:0] bin_ent,     // Entrada binaria (0 a 81)
    output logic [11:0] bcd_out     // Salida BCD {centenas, decenas, unidades}
);
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
            default: bcd_out = 12'hFFF; // Error: fuera de rango
        endcase
    end
endmodule
