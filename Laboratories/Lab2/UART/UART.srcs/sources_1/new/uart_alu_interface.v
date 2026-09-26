`timescale 1ns / 1ps

// Controla el protocolo entre UART y ALU.
// Recibe:   A, B, opcode.
// Responde: resultado, flags {5'b0, overflow, carry, zero}.
module uart_alu_interface #(
    // Cantidad de bits de los operandos, resultado y bytes UART.
    parameter DATA_BITS = 8,
    // Cantidad de bits usados para seleccionar la operacion de la ALU.
    parameter OPT_BITS  = 6
) (
    // Reloj y reset sincrono del sistema.
    input  wire                 i_clk,
    input  wire                 i_reset,

    // Salida del receptor UART. i_rx_done vale 1 durante un ciclo cuando
    // i_rx_data contiene un byte nuevo.
    input  wire [DATA_BITS-1:0] i_rx_data,
    input  wire                 i_rx_done,

    // Interfaz con el transmisor UART. o_tx_start solicita el envio de
    // o_tx_data; i_tx_done avisa que la trama termino de transmitirse.
    input  wire                 i_tx_done,
    output reg  [DATA_BITS-1:0] o_tx_data,
    output reg                  o_tx_start,

    // Registros que alimentan directamente a la ALU combinacional.
    output reg  [DATA_BITS-1:0] o_alu_a,
    output reg  [DATA_BITS-1:0] o_alu_b,
    output reg  [OPT_BITS-1:0]  o_alu_op,

    // Resultado y flags producidos por la ALU.
    input  wire [DATA_BITS-1:0] i_alu_result,
    input  wire                 i_alu_zero,
    input  wire                 i_alu_carry,
    input  wire                 i_alu_overflow
);

    // FSM del protocolo: recibe A, B y opcode; luego transmite resultado
    // y flags, esperando que TX termine antes de continuar.
    localparam [2:0] WAIT_A      = 3'd0,
                     WAIT_B      = 3'd1,
                     WAIT_OPCODE = 3'd2,
                     SEND_RESULT = 3'd3,
                     WAIT_RESULT = 3'd4,
                     SEND_FLAGS  = 3'd5,
                     WAIT_FLAGS  = 3'd6;

    reg [2:0] state;

    always @(posedge i_clk) begin
        // El reset cancela cualquier operacion incompleta y vuelve a esperar A.
        if (i_reset) begin
            state      <= WAIT_A;
            o_alu_a    <= {DATA_BITS{1'b0}};
            o_alu_b    <= {DATA_BITS{1'b0}};
            o_alu_op   <= {OPT_BITS{1'b0}};
            o_tx_data  <= {DATA_BITS{1'b0}};
            o_tx_start <= 1'b0;
        end else begin
            // Valor por defecto: tx_start es un pulso de un solo ciclo.
            o_tx_start <= 1'b0;

            case (state)
                // Primer byte recibido: operando A.
                WAIT_A:
                    if (i_rx_done) begin
                        o_alu_a <= i_rx_data;
                        state   <= WAIT_B;
                    end

                // Segundo byte recibido: operando B.
                WAIT_B:
                    if (i_rx_done) begin
                        o_alu_b <= i_rx_data;
                        state   <= WAIT_OPCODE;
                    end

                // Tercer byte recibido: opcode. Solo se usan sus bits bajos.
                WAIT_OPCODE:
                    if (i_rx_done) begin
                        o_alu_op <= i_rx_data[OPT_BITS-1:0];
                        state    <= SEND_RESULT;
                    end

                // La ALU ya tiene A, B y opcode estables. Se carga el resultado
                // en TX y se genera el pulso que inicia la transmision.
                SEND_RESULT: begin
                    o_tx_data  <= i_alu_result;
                    o_tx_start <= 1'b1;
                    state      <= WAIT_RESULT;
                end

                // No se avanza hasta que TX termine de enviar el resultado.
                WAIT_RESULT:
                    if (i_tx_done)
                        state <= SEND_FLAGS;

                // Segundo byte de respuesta:
                // [7:3] = 0, [2] = overflow, [1] = carry, [0] = zero.
                SEND_FLAGS: begin
                    o_tx_data  <= {{(DATA_BITS-3){1'b0}},
                                   i_alu_overflow, i_alu_carry, i_alu_zero};
                    o_tx_start <= 1'b1;
                    state      <= WAIT_FLAGS;
                end

                // Al terminar los flags, comienza una nueva operacion.
                WAIT_FLAGS:
                    if (i_tx_done)
                        state <= WAIT_A;

                // Recuperacion simple ante un estado invalido.
                default:
                    state <= WAIT_A;
            endcase
        end
    end

endmodule
