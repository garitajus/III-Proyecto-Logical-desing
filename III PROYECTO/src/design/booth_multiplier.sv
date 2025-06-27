module booth_multiplier #(parameter N = 5)(
    input logic clk,
    input logic rst, // CORREGIDO: Reset activo en bajo para consistencia
    input logic start,
    input logic signed [N-1:0] multiplicand,
    input logic signed [N-1:0] multiplier,
    output logic signed [2*N-1:0] product,
    output logic done
);
    typedef enum logic [1:0] { IDLE, CALC, SHIFT, FINISH } state_t;
    state_t state;

    logic signed [N:0]   AC; // acumulador 
    logic signed [N-1:0] QR, BR; // QR multiplicador que de desplaza, BR guarda el multiplicando sin modificarlo
    logic                Q_1; // refiere al bit extra que mantiene el ultimo bit desplazado de QR, regla de booth 
    logic [$clog2(N)-1:0] SC; // Contador de secuencia, necesita contar hasta N y cuanta hacia 0

    always_ff @(posedge clk or negedge rst) begin // CORREGIDO: negedge rst
        if (!rst) begin // CORREGIDO: Lógica para reset activo en bajo
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
                    // CORRECCIÓN DEFINITIVA: Implementación explícita y robusta del desplazamiento aritmético
                    Q_1      <= QR[0];
                    QR       <= {AC[0], QR[N-1:1]};
                    AC       <= {AC[N], AC[N:1]}; // Desplazamiento aritmético (se preserva el bit de signo AC[N])
                    
                    SC <= SC - 1;
                    if (SC == 1) begin // Cuando el contador llega a 1, es la última iteración
                        state <= FINISH;
                    end else begin
                        state <= CALC;
                    end
                end

                FINISH: begin
                    // La asignación original era correcta. El producto son los N bits bajos de AC y QR.
                    product <= {AC[N-1:0], QR};
                    done  <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule