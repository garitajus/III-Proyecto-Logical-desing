`timescale 1ns / 1ps

module tb_top();

    // Declaración de señales
    reg clk;
    reg rst;
    wire [3:0] an;
    wire [6:0] seg;
    wire [3:0] columnas;
    reg [3:0] filas;

    // Instancia del módulo top
    top uut (
        .clk(clk),
        .rst(rst),
        .an(an),
        .seg(seg),
        .columnas(columnas),
        .filas(filas)
    );

    // Generación del reloj de 27 MHz
    initial begin
        clk = 0;
        forever #18.52 clk = ~clk; // 27 MHz: período de ~37.04 ns, mitad ~18.52 ns
    end

    // Inicialización y reset
    initial begin
        // Inicializar entradas
        rst = 0;
        filas = 4'b1111; // Ninguna fila presionada inicialmente

        // Aplicar reset
        #100;
        rst = 1;
        #100;

        // Comenzar la simulación
        test_sequence();
    end

    // Secuencia de prueba
    task test_sequence();
        begin
            // Prueba 1: Ingresar número A (123)
            $display("Ingresando número A: 123");
            ingresar_numero(4'h3); // 3
            ingresar_numero(4'h2); // 2
            ingresar_numero(4'h1); // 1
            presionar_tecla(4'hF); // Cambiar a estado de entrada B

            // Prueba 2: Ingresar número B (456)
            $display("Ingresando número B: 456");
            ingresar_numero(4'h6); // 6
            ingresar_numero(4'h5); // 5
            ingresar_numero(4'h4); // 4
            presionar_tecla(4'hF); // Calcular suma

            // Prueba 3: Verificar suma (123 + 456 = 579)
            $display("Verificando suma: 123 + 456 = 579");
            // Aquí puedes agregar comprobaciones para verificar la salida en el display

            // Prueba 4: Reiniciar
            $display("~~~~~~~~~~Reiniciando...~~~~~~~~~~");
            presionar_tecla(4'hE); // Reiniciar

            // Prueba 5: Ingresar nuevo número A (789)
            $display("Ingresando nuevo número A: 789");
            ingresar_numero(4'h9); // 9
            ingresar_numero(4'h8); // 8
            ingresar_numero(4'h7); // 7
            presionar_tecla(4'hF); // Cambiar a estado de entrada B

            // Prueba 6: Ingresar nuevo número B (123)
            $display("Ingresando nuevo número B: 123");
            ingresar_numero(4'h3); // 3
            ingresar_numero(4'h2); // 2
            ingresar_numero(4'h1); // 1
            presionar_tecla(4'hF); // Calcular suma

            // Prueba 7: Verificar suma (789 + 123 = 912)
            $display("Verificando suma: 789 + 123 = 912");
            // Aquí puedes agregar comprobaciones para verificar la salida en el display

            // Finalizar simulación
            #1000;
            $display("Simulación completada");
            $finish;
        end
    endtask

    // Tarea para ingresar un número
    task ingresar_numero(input [3:0] numero);
        begin
            $display("Presionando tecla: %d", numero);
            filas = ~(1 << numero); // Simular la presión de una tecla
            #100;
            filas = 4'b1111; // Soltar la tecla
            #100;
        end
    endtask

    // Tarea para presionar una tecla especial (* o #)
    task presionar_tecla(input [3:0] tecla);
        begin
            $display("Presionando tecla especial: %h", tecla);
            filas = ~(1 << tecla); // Simular la presión de una tecla
            #100;
            filas = 4'b1111; // Soltar la tecla
            #100;
        end
    endtask

    // Configuración para generar el archivo VCD
    initial begin
        $dumpfile("simulation.vcd"); // Nombre del archivo VCD
        $dumpvars(0, tb_top); // Volcar todas las variables en el testbench
    end

endmodule
