// ============================================================
// Module: uart_rx
// Purpose: UART Receiver — receives serial data from laptop
//
// Protocol: 8N1 (8 data bits, No parity, 1 stop bit)
// Baud:     115200
// Clock:    100 MHz → CLKS_PER_BIT = 868
//
// Operation:
//   - Waits for start bit (line goes LOW)
//   - Samples each bit at the CENTER of the bit period
//     (sampling at center maximizes noise margin)
//   - After 8 bits received, asserts rx_done for 1 cycle
//   - rx_data holds the received byte
//
// For 64-bit challenge collection:
//   - Python sends 8 bytes (64 bits) sequentially
//   - puf_top.v assembles them into one 64-bit challenge
//   - MSB sent first (Big Endian byte order)
// ============================================================

`timescale 1ns / 1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 868  // 100MHz / 115200 baud
)(
    input  wire       clk,
    input  wire       rx_serial,   // Serial input from USB-UART
    output reg  [7:0] rx_data,     // Received byte
    output reg        rx_done      // Pulses HIGH for 1 cycle when byte ready
);

    // --------------------------------------------------------
    // States
    // --------------------------------------------------------
    localparam IDLE    = 3'd0;  // Waiting for start bit
    localparam START   = 3'd1;  // Detected start bit, verify it
    localparam DATA    = 3'd2;  // Receiving 8 data bits
    localparam STOP    = 3'd3;  // Receiving stop bit
    localparam CLEANUP = 3'd4;  // Assert rx_done for 1 cycle

    reg [2:0]  state    = IDLE;
    reg [9:0]  clk_cnt  = 0;    // Clock cycle counter within one bit period
    reg [2:0]  bit_idx  = 0;    // Which data bit we are receiving (0-7)
    reg [7:0]  rx_shift = 0;    // Shift register accumulating received bits

    // Double-register the RX line to prevent metastability
    // This is standard practice for any asynchronous input
    reg rx_d1 = 1'b1;
    reg rx_d2 = 1'b1;

    always @(posedge clk) begin
        rx_d1 <= rx_serial;
        rx_d2 <= rx_d1;
    end

    always @(posedge clk) begin
        case (state)

            // ------------------------------------------------
            // IDLE: Line is HIGH. Wait for it to go LOW
            // (LOW = start bit beginning)
            // ------------------------------------------------
            IDLE: begin
                rx_done <= 1'b0;
                clk_cnt <= 0;
                bit_idx <= 0;

                if (rx_d2 == 1'b0)
                    state <= START;
            end

            // ------------------------------------------------
            // START: Verify start bit is still LOW at midpoint
            // We wait CLKS_PER_BIT/2 cycles to reach the
            // center of the start bit before sampling.
            // If line has gone HIGH again, it was noise — abort.
            // ------------------------------------------------
            START: begin
                if (clk_cnt == (CLKS_PER_BIT/2 - 1)) begin
                    if (rx_d2 == 1'b0) begin
                        clk_cnt <= 0;
                        state   <= DATA;
                    end else begin
                        state <= IDLE;  // Was noise, not a real start bit
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            // ------------------------------------------------
            // DATA: Sample 8 bits at center of each bit period
            // LSB received first (standard UART)
            // ------------------------------------------------
            DATA: begin
                if (clk_cnt == (CLKS_PER_BIT - 1)) begin
                    clk_cnt            <= 0;
                    rx_shift[bit_idx]  <= rx_d2;  // Sample at bit center

                    if (bit_idx == 3'd7) begin
                        bit_idx <= 0;
                        state   <= STOP;
                    end else begin
                        bit_idx <= bit_idx + 1;
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            // ------------------------------------------------
            // STOP: Wait for stop bit (line should be HIGH)
            // Sample at center of stop bit period
            // ------------------------------------------------
            STOP: begin
                if (clk_cnt == (CLKS_PER_BIT - 1)) begin
                    clk_cnt <= 0;
                    rx_data <= rx_shift;
                    state   <= CLEANUP;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            // ------------------------------------------------
            // CLEANUP: Assert rx_done for exactly 1 cycle
            // then return to IDLE to receive next byte
            // ------------------------------------------------
            CLEANUP: begin
                rx_done <= 1'b1;
                state   <= IDLE;
            end

            default: state <= IDLE;

        endcase
    end

endmodule
