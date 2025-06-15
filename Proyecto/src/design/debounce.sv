module debounce (
    input  logic clk,           // Reloj del sistema de 27 MHz
    input  logic rst,         // rst activo en bajo (activo cuando es 0)
    input  logic key,     // Señal de entrada del botón (con rebotes)
    output logic key_pressed     // Señal de salida del botón ya "filtrada", sin rebotes
);

    
    logic [16:0]  count;    // Contador de 17 bits
    logic estable;           // Valor eestable actual del botón
    logic ff_1, ff_2, ff_3, ff_4;
    
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            ff_1 <= 1'b0; 
            ff_2 <= 1'b0;
            ff_4 <= 1'b0;
        end else begin
            ff_1 <= key;
            ff_2 <= ff_1;
            ff_4 <= ff_2;
        end
    end

    assign estable = ff_1 & ff_2 & ff_4;

    // Lógica de debounce:
    // Solo si la señal sincronizada se mantiene distinta al valor "eestable" por más de DEBOUNCE_COUNT ciclos, se considera un cambio válido.
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
             count <= '0; // rst del contador
            //estable <= 1'b0;   // Valor eestable inicial del botón (asumido como 0)
            ff_3 <= 1'b0;
        end else begin
            if (estable) begin           // sync_ff[1] != estable
                // Si la señal actual no coincide con la eestable, empezamos a contar
                if ( count == 3'b100) begin        //DEBOUNCE_COUNT
                    // Si se mantiene por suficiente tiempo, aceptamos el nuevo valor
                     count <= '0;
                    ff_3 <= 1'b1; // Actualizamos la salida eestable
                end else begin
                    // Aún no alcanza el conteo requerido, seguimos contando
                     count <=  count + 1'b1;
                    ff_3 <= 1'b0;
                end
            end else begin
                // Si la señal es igual al valor eestable, reiniciamos el contador
                 count <= '0;
                ff_3 <= 1'b0;
            end
        end
    end

    // Asignamos la señal eestable como salida del módulo
    assign key_pressed = ff_3;
    
endmodule