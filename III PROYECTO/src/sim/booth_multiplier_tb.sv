`timescale 1ns/1ps

module booth_multiplier_tb;

    parameter N = 5;

    logic clk;
    logic rst;
    logic start;
    logic signed [N-1:0] multiplicand;
    logic signed [N-1:0] multiplier;
    logic signed [2*N-1:0] product;
    logic done;

    // Instancia del DUT (Device Under Test)
    booth_multiplier #(.N(N)) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .product(product),
        .done(done)
    );

    // Reloj simple
    always #5 clk = ~clk;

    // Procedimiento de prueba
    initial begin
        // Inicialización
        clk = 0;
        rst = 1;
        start = 0;
        multiplicand = 0;
        multiplier = 0;
        #20;
        rst = 0;

        // Prueba 1: 9 * 1 = 9
        test_case(5'sd9, 5'sd1);

        // Prueba 2: 9 * -1 = -9
        test_case(5'sd9, -5'sd1);

        // Prueba 3: -9 * 2 = -18
        test_case(-5'sd9, 5'sd2);

        // Prueba 4: -3 * -4 = 12
        test_case(-5'sd3, -5'sd4);

        // Prueba 5: 7 * 0 = 0
        test_case(5'sd7, 5'sd0);

        // Prueba 6: 0 * -6 = 0
        test_case(5'sd0, -5'sd6);

        $display("Todas las pruebas completadas.");
        $finish;
    end

    task test_case(input signed [N-1:0] A, input signed [N-1:0] B);
        begin
            multiplicand = A;
            multiplier = B;
            start = 1;
            @(posedge clk);
            start = 0;

            // Esperar a que done se active
            wait (done == 1);
            @(posedge clk); // Esperar un ciclo más por estabilidad

            $display("A = %0d, B = %0d, Producto = %0d", A, B, product);
        end
    endtask

endmodule
