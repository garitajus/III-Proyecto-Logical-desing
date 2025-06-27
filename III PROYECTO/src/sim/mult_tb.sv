`timescale 1ns / 1ps

module mult_tb;

    // Parámetros
    parameter N = 8;
    parameter CLK_PERIOD = 10;

    // Señales
    logic clk;
    logic rst;
    logic [N-1:0] A, B;
    logic load_A, load_B, load_add, shift_HQ_LQ_Q_1, add_sub;
    logic [1:0] Q_LSB;
    logic [2*N-1:0] Y;

    // Instancia del DUT
    mult #(N) dut (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .mult_control({load_A, load_B, load_add, shift_HQ_LQ_Q_1, add_sub}),
        .Q_LSB(Q_LSB),
        .Y(Y)
    );

    // Generador de reloj
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Tarea para ejecutar algoritmo Booth
    task automatic booth_multiply(input logic [N-1:0] opA, input logic [N-1:0] opB, input int expected_result);
        begin
            // Inicializar señales
            rst = 1;
            load_A = 0;
            load_B = 0;
            load_add = 0;
            shift_HQ_LQ_Q_1 = 0;
            add_sub = 0;
            A = opA;
            B = opB;

            #(CLK_PERIOD);
            rst = 0;

            // Cargar M y B en el DUT
            load_A = 1;
            #(CLK_PERIOD);
            load_A = 0;

            load_B = 1;
            #(CLK_PERIOD);
            load_B = 0;

            // Ciclos Booth
            for (int i = 0; i < N; i++) begin
                case (Q_LSB)
                    2'b01: begin // Sumar M
                        add_sub = 1;
                        load_add = 1;
                        #(CLK_PERIOD);
                        load_add = 0;
                    end
                    2'b10: begin // Restar M
                        add_sub = 0;
                        load_add = 1;
                        #(CLK_PERIOD);
                        load_add = 0;
                    end
                    default: ; // No operación
                endcase

                // Desplazar
                shift_HQ_LQ_Q_1 = 1;
                #(CLK_PERIOD);
                shift_HQ_LQ_Q_1 = 0;
            end

            #(CLK_PERIOD); // Esperar actualización final

            if ($signed(Y) === expected_result) begin
                $display("Prueba pasada: %0d * %0d = %0d", $signed(opA), $signed(opB), $signed(Y));
            end else begin
                $display("Prueba fallida: %0d * %0d. Esperado %0d, obtenido %0d", $signed(opA), $signed(opB), expected_result, $signed(Y));
            end
        end
    endtask

    // Bloque principal
    initial begin
        // Esperar que todo se estabilice
        #(CLK_PERIOD * 2);

        // Casos de prueba
        booth_multiply(3, 4, 12);
        booth_multiply(5, -3, -15);
        booth_multiply(0, 7, 0);
        booth_multiply(127, 127, 16129);
        booth_multiply(-8, -2, 16);
        booth_multiply(-9, 3, -27);
        booth_multiply(6, -7, -42);
        booth_multiply(-5, -5, 25);

        #(CLK_PERIOD);
        $finish;
    end

endmodule
