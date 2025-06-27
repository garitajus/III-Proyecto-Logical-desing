typedef struct packed {
    logic load_A;
    logic load_B;
    logic load_add;
    logic shift_HQ_LQ_Q_1;
    logic add_sub;
} mult_control_t;

module mult #(
    parameter N = 8
)(
    input  logic clk,
    input  logic rst,
    input  logic signed [N-1:0] A,
    input  logic signed [N-1:0] B,
    input  mult_control_t mult_control,
    output logic [1:0] Q_LSB,
    output logic signed [2*N-1:0] Y
);

    // Declaración de señales internas
    logic signed [N-1:0] M;
    logic signed [N-1:0] adder_sub_out;
    logic signed [2*N:0] shift;
    logic signed [N-1:0] HQ, LQ;
    logic Q_1;

    // Registro M
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            M <= '0;
        else if (mult_control.load_A)
            M <= A;
    end

    // Partes HQ, LQ, Q_1 del registro de desplazamiento
    assign HQ  = shift[2*N:N+1];
    assign LQ  = shift[N:1];
    assign Q_1 = shift[0];

    // Lógica de suma/resta (¡invertida para coincidir con Booth!)
    always_comb begin
        if (mult_control.add_sub)
            adder_sub_out = HQ - M; // Cuando Q[0]Q[-1] = 10 → resta
        else
            adder_sub_out = HQ + M; // Cuando Q[0]Q[-1] = 01 → suma
    end

    // Registro de desplazamiento
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            shift <= '0;
        else if (mult_control.shift_HQ_LQ_Q_1)
            shift <= {shift[2*N], shift[2*N:1]}; // Desplazamiento aritmético
        else begin
            if (mult_control.load_B)
                shift[N:1] <= B; // Carga B en LQ
            if (mult_control.load_add)
                shift[2*N:N+1] <= adder_sub_out; // Carga resultado en HQ
        end
    end

    // Salidas
    assign Q_LSB = {Q_1, LQ[0]};
    assign Y = $signed({HQ, LQ}); // IMPORTANTE: salida firmada

endmodule
