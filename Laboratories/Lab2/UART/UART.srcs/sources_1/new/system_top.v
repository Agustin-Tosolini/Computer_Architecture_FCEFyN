`timescale 1ns / 1ps

module system_top #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 9600,
    parameter DATA_BITS = 8,
    parameter OPT_BITS  = 6
) (
    input  wire i_clk,
    input  wire i_reset,
    input  wire i_rx,
    output wire o_tx
);

    wire                 s_tick;
    wire [DATA_BITS-1:0] rx_data;
    wire                 rx_done;
    wire [DATA_BITS-1:0] tx_data;
    wire                 tx_start;
    wire                 tx_done;

    wire [DATA_BITS-1:0] alu_a;
    wire [DATA_BITS-1:0] alu_b;
    wire [OPT_BITS-1:0]  alu_op;
    wire [DATA_BITS-1:0] alu_result;
    wire                 alu_zero;
    wire                 alu_carry;
    wire                 alu_overflow;

    baud_rate_generator #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE),
        .OVERSAMP  (16)
    ) u_baud (
        .i_clk   (i_clk),
        .i_reset (i_reset),
        .o_tick  (s_tick)
    );

    rx_fsmd #(
        .DATA_BITS (DATA_BITS),
        .SB_TICK   (16)
    ) u_rx (
        .i_clk     (i_clk),
        .i_reset   (i_reset),
        .i_s_tick  (s_tick),
        .i_rx      (i_rx),
        .o_rx_done (rx_done),
        .o_dout    (rx_data)
    );

    uart_alu_interface #(
        .DATA_BITS (DATA_BITS),
        .OPT_BITS  (OPT_BITS)
    ) u_interface (
        .i_clk          (i_clk),
        .i_reset        (i_reset),
        .i_rx_data      (rx_data),
        .i_rx_done      (rx_done),
        .i_tx_done      (tx_done),
        .o_tx_data      (tx_data),
        .o_tx_start     (tx_start),
        .o_alu_a        (alu_a),
        .o_alu_b        (alu_b),
        .o_alu_op       (alu_op),
        .i_alu_result   (alu_result),
        .i_alu_zero     (alu_zero),
        .i_alu_carry    (alu_carry),
        .i_alu_overflow (alu_overflow)
    );

    ALU #(
        .LENGTH_BITS (DATA_BITS),
        .LENGTH_OPT  (OPT_BITS)
    ) u_alu (
        .i_dato_A   (alu_a),
        .i_dato_B   (alu_b),
        .i_opt      (alu_op),
        .o_result   (alu_result),
        .o_zero     (alu_zero),
        .o_carry    (alu_carry),
        .o_overflow (alu_overflow)
    );

    tx_fsmd #(
        .DATA_BITS (DATA_BITS),
        .STOP_BITS (1)
    ) u_tx (
        .i_clk      (i_clk),
        .i_reset    (i_reset),
        .i_s_tick   (s_tick),
        .i_tx_start (tx_start),
        .i_din      (tx_data),
        .o_tx_done  (tx_done),
        .o_tx       (o_tx)
    );

endmodule
