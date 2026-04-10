// ============================================================
// Module: uart_tx
// Purpose: UART Transmitter — sends PUF response to laptop
//
// Protocol: 8N1 (8 data bits, No parity, 1 stop bit)
// Baud:     115200
// Clock:    100 MHz → CLKS_PER_BIT = 868
//
// Operation:
//   - When tx_start is asserted, begins transmitting tx_data
//   - Sends start bit (LOW), 8 data bits LSB first, stop bit
//   - tx_busy is HIGH during transmission
//   - tx_done pulses HIGH for 1 cycle when complete
//
// For PUF response transmission:
//   - puf_top sends 1 byte per PUF evaluation
//   - Byte format: {7'b0, response_bit}
//     (response bit in LSB, upper 7 bits zero)
//   - Python reads this byte and extracts bit 0
// ============================================================

`timescale 1ns / 1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 868  // 100MHz / 115200 baud
)(
    input  wire       clk,
    input  wire       tx_start,    // Pulse HIGH for 1 cycle to begin transmit
    input  wire [7:0] tx_data,     // Byte to transmit
    output reg        tx_serial,   // Serial output to USB-UART
    output reg        tx_busy,     // HIGH while transmitting
    output reg        tx_done      // Pulses HIGH for 1 cycle when done
);

    localparam IDLE    = 3'd0;
    localparam START   = 3'd1;
    localparam DATA    = 3'd2;
    localparam STOP    = 3'd3;
    localparam CLEANUP = 3'd4;

    reg [2:0]  state    = IDLE;
    reg [9:0]  clk_cnt  = 0;
    reg [2:0]  bit_idx  = 0;
    reg [7:0]  tx_shift = 0;   // Holds byte being transmitted

    always @(posedge clk) begin
        case (state)

            IDLE: begin
                tx_serial <= 1'b1;  // Line idle = HIGH
                tx_busy   <= 1'b0;
                tx_done   <= 1'b0;
                clk_cnt   <= 0;
                bit_idx   <= 0;

                if (tx_start) begin
                    tx_shift <= tx_data;
                    tx_busy  <= 1'b1;
                    state    <= START;
                end
            end

            // Send start bit (LOW)
            START: begin
                tx_serial <= 1'b0;

                if (clk_cnt == (CLKS_PER_BIT - 1)) begin
                    clk_cnt <= 0;
                    state   <= DATA;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            // Send 8 data bits, LSB first
            DATA: begin
                tx_serial <= tx_shift[bit_idx];

                if (clk_cnt == (CLKS_PER_BIT - 1)) begin
                    clk_cnt <= 0;

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

            // Send stop bit (HIGH)
            STOP: begin
                tx_serial <= 1'b1;

                if (clk_cnt == (CLKS_PER_BIT - 1)) begin
                    clk_cnt <= 0;
                    state   <= CLEANUP;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end

            CLEANUP: begin
                tx_done <= 1'b1;
                tx_busy <= 1'b0;
                state   <= IDLE;
            end

            default: state <= IDLE;

        endcase
    end

endmodule
