`timescale 1ns / 1ps

// Modulo superior del sistema.
//
// Por ahora conecta directamente las entradas externas con la ALU. Los
// modulos de UART y control se agregaran posteriormente en este nivel, sin
// modificar la interfaz interna de la ALU.
module system_top #(
    parameter LENGTH_BITS = 8,
    parameter LENGTH_OPT  = 6
) (
    input  wire [LENGTH_BITS-1:0] i_dato_A,
    input  wire [LENGTH_BITS-1:0] i_dato_B,
    input  wire [LENGTH_OPT-1:0]  i_opt,

    output wire [LENGTH_BITS-1:0] o_result,
    output wire                   o_zero,
    output wire                   o_carry,
    output wire                   o_overflow
);

    // Senales internas de interconexion con la ALU. En una etapa posterior,
    // los operandos y el opcode podran provenir del bloque de control/UART.
    wire [LENGTH_BITS-1:0] alu_result;
    wire                   alu_zero;
    wire                   alu_carry;
    wire                   alu_overflow;

    ALU #(
        .LENGTH_BITS (LENGTH_BITS),
        .LENGTH_OPT  (LENGTH_OPT)
    ) u_alu (
        .i_dato_A   (i_dato_A),
        .i_dato_B   (i_dato_B),
        .i_opt      (i_opt),
        .o_result   (alu_result),
        .o_zero     (alu_zero),
        .o_carry    (alu_carry),
        .o_overflow (alu_overflow)
    );

    assign o_result   = alu_result;
    assign o_zero     = alu_zero;
    assign o_carry    = alu_carry;
    assign o_overflow = alu_overflow;

endmodule
