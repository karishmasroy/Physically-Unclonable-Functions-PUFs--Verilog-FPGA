`timescale 1ns / 1ps

module puf_top (
    input  wire       clk_in,       
    input  wire       cpu_reset,    
    input  wire       uart_rxd,     
    output wire       uart_txd,     
    output wire [3:0] led           
);

    wire clk_100;
    IBUF clk_ibuf (.I(clk_in), .O(clk_100));
    wire global_rst = cpu_reset; 

    // UART
    wire [7:0] rx_data;
    wire rx_done, tx_busy, tx_done;
    reg  tx_start;
    reg  [7:0] tx_data;
    
    uart_rx #(.CLKS_PER_BIT(868)) urx (.clk(clk_100), .rx_serial(uart_rxd), .rx_data(rx_data), .rx_done(rx_done));
    uart_tx #(.CLKS_PER_BIT(868)) utx (.clk(clk_100), .tx_start(tx_start), .tx_data(tx_data), .tx_serial(uart_txd), .tx_busy(tx_busy), .tx_done(tx_done));

    // PUF Instance (8 rows)
    reg  puf_trigger, puf_rst_internal;
    reg  [63:0] puf_challenge;
    wire [7:0]  puf_response;
    wire puf_valid;

    arbiter_puf_64bit puf_inst (
        .sys_clk(clk_100), .rst(puf_rst_internal || global_rst), 
        .trigger(puf_trigger), .challenge(puf_challenge), 
        .response(puf_response), .valid(puf_valid)
    );

    // --- 8-XOR Logic ---
    // The '^' operator XORs all bits of the vector together
    wire xor_final_bit = ^puf_response; 

    localparam WAIT_SYNC = 3'b000, RX_CHALL = 3'b001, EVALUATE = 3'b010, SEND_RESP = 3'b011;
    reg [2:0] state = WAIT_SYNC;
    reg [3:0] byte_cnt = 0;
    reg [63:0] ch_buffer = 0;
    reg [7:0] timing_cnt = 0;
    localparam SYNC_BYTE = 8'h5A;

    reg rx_done_prev = 0;
    wire rx_done_edge = (rx_done && !rx_done_prev);

    always @(posedge clk_100) begin
        rx_done_prev <= rx_done;
        puf_trigger <= 0; tx_start <= 0; puf_rst_internal <= 0;

        if (global_rst) begin 
            state <= WAIT_SYNC; byte_cnt <= 0; timing_cnt <= 0;
        end else begin
            case (state)
                WAIT_SYNC: if (rx_done_edge && rx_data == SYNC_BYTE) state <= RX_CHALL;
                RX_CHALL: if (rx_done_edge) begin
                    ch_buffer <= {ch_buffer[55:0], rx_data};
                    if (byte_cnt == 7) begin 
                        puf_challenge <= {ch_buffer[55:0], rx_data}; 
                        state <= EVALUATE; byte_cnt <= 0; timing_cnt <= 0;
                    end else byte_cnt <= byte_cnt + 1;
                end
                EVALUATE: begin
                    timing_cnt <= timing_cnt + 1;
                    if (timing_cnt < 10) puf_rst_internal <= 1;
                    else if (timing_cnt == 20) puf_trigger <= 1;
                    else if (timing_cnt == 120) begin
                        tx_data <= {7'b0, xor_final_bit}; // Send 1-bit result
                        tx_start <= 1; state <= SEND_RESP; 
                    end
                end
                SEND_RESP: if (tx_done) state <= WAIT_SYNC;
            endcase
        end
    end
    
    assign led[0] = (state == WAIT_SYNC);
    assign led[1] = (state == EVALUATE);
    assign led[2] = xor_final_bit; 
    assign led[3] = tx_busy;
endmodule