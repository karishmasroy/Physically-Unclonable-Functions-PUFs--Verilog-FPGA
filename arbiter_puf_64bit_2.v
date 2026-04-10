`timescale 1ns / 1ps

(* DONT_TOUCH = "TRUE" *)
module arbiter_puf_64bit (
    input  wire        sys_clk,   
    input  wire        rst,       
    input  wire        trigger,   
    input  wire [63:0] challenge, 
    output wire [7:0]  response,  // 8-bit output
    output reg         valid      
);

    genvar r, i;
    generate
        // Create 8 parallel rows
        for (r = 0; r < 8; r = r + 1) begin : puf_rows
            wire [64:0] top_wire;
            wire [64:0] bot_wire;
            
            assign top_wire[0] = trigger;
            assign bot_wire[0] = trigger;

            // 64 switch stages per row
            for (i = 0; i < 64; i = i + 1) begin : puf_stages
                (* DONT_TOUCH = "TRUE" *)
                puf_stage stage_inst (
                    .in_top(top_wire[i]),
                    .in_bot(bot_wire[i]),
                    .challenge_bit(challenge[i]),
                    .out_top(top_wire[i+1]),
                    .out_bot(bot_wire[i+1])
                );
            end

            // Each row has its own dedicated Arbiter
            (* DONT_TOUCH = "TRUE" *)
            FDRE #( .INIT(1'b0) ) puf_arbiter_inst (
                .Q  (response[r]),     
                .C  (bot_wire[64]), 
                .D  (top_wire[64]), 
                .CE (1'b1),          
                .R  (rst)            
            );
        end
    endgenerate

    // Master Timing Logic for 8-bit collection
    reg [7:0] valid_cnt;
    always @(posedge sys_clk) begin
        if (rst) begin
            valid <= 1'b0;
            valid_cnt <= 0;
        end else if (trigger) begin
            valid_cnt <= 1;
            valid     <= 1'b0;
        end else if (valid_cnt > 0 && valid_cnt < 8'd120) begin
            valid_cnt <= valid_cnt + 1;
            valid     <= (valid_cnt == 8'd119);
        end
    end
endmodule