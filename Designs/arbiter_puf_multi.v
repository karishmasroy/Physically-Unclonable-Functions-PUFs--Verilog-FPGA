`timescale 1ns / 1ps

module switch_block #(
    parameter DELAY_PATH0 = 1, // Delay for crossing 0
    parameter DELAY_PATH1 = 1  // Delay for crossing 1
) (
    input wire in_top,
    input wire in_bot,
    input wire sel, // Challenge bit
    output wire out_top,
    output wire out_bot
);
    assign #(DELAY_PATH0) out_top = (sel) ? in_bot : in_top;
    assign #(DELAY_PATH1) out_bot = (sel) ? in_top : in_bot;

endmodule

module arbiter_element (
    input wire top_arrive, // Acts as Clock
    input wire bot_arrive, // Acts as Data
    output reg response
);
    
    always @(posedge top_arrive) begin
        response <= bot_arrive;
    end
    
endmodule
module arbiter_puf_multi (
    input wire trigger,        
    input wire [7:0] challenge, // 8-bit Challenge
    output wire [7:0] response  // 8-bit Response
);

    genvar row, stage;
    generate
        for (row = 0; row < 8; row = row + 1) begin : puf_row
            wire [8:0] w_top; 
            wire [8:0] w_bot;
            
            assign w_top[0] = trigger;
            assign w_bot[0] = trigger;


            for (stage = 0; stage < 8; stage = stage + 1) begin : chain_stage
                localparam D0 = 2 + ((row * stage) % 3); 
                localparam D1 = 2 + ((row + stage) % 2); 

                switch_block #(
                    .DELAY_PATH0(D0), 
                    .DELAY_PATH1(D1)
                ) sw (
                    .in_top (w_top[stage]),
                    .in_bot (w_bot[stage]),
                    .sel    (challenge[stage]),
                    .out_top(w_top[stage+1]),
                    .out_bot(w_bot[stage+1])
                );
            end
            arbiter_element arb (
                .top_arrive(w_top[8]),
                .bot_arrive(w_bot[8]),
                .response  (response[row])
            );
        end
    endgenerate

endmodule
