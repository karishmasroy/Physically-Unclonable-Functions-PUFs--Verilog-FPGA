`timescale 1ns / 1ps

(* DONT_TOUCH = "TRUE" *)
module puf_stage (
    input  wire in_top,
    input  wire in_bot,
    input  wire challenge_bit,
    output wire out_top,
    output wire out_bot
);
    // Standard MUX-based switch logic
    // Challenge = 0 -> Straight: (out_top=in_top, out_bot=in_bot)
    // Challenge = 1 -> Crossed:  (out_top=in_bot, out_bot=in_top)
    assign out_top = (challenge_bit) ? in_bot : in_top;
    assign out_bot = (challenge_bit) ? in_top : in_bot;

endmodule