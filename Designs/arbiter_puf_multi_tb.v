`timescale 1ns / 1ps
`include "arbiter_puf_multi.v"

module arbiter_puf_multi_tb;

    // Inputs
    reg trigger;
    reg [7:0] challenge;

    // Outputs
    wire [7:0] response;

    // Instantiate the Unit Under Test (UUT)
    arbiter_puf_multi uut (
        .trigger(trigger), 
        .challenge(challenge), 
        .response(response)
    );

    // Procedure to apply a challenge and check result
    task apply_challenge_test;
        input [7:0] chal_in;
        begin
            // 1. Reset Trigger (Low)
            trigger = 0;
            // 2. Apply Challenge
            challenge = chal_in;
            #20; // Wait for challenge setup
            
            // 3. Fire Trigger (Race Start)
            trigger = 1;
            
            // 4. Wait for signal to propagate through 8 stages 
            #100; 
            
            // 5. Display Result
            $display("Time: %0t | Challenge: 8'b%b | Response: 8'b%b", $time, challenge, response);
            
            // 6. Reset trigger for next run
            trigger = 0;
            #20;
        end
    endtask

    initial begin
        // --- GTKWave/VCD Dump Setup ---
        // This generates the file needed for the waveform viewer
        $dumpfile("arbiter_puf_multi.vcd");
        $dumpvars(0, arbiter_puf_multi_tb);
        // -----------------------------

        // Initialize Inputs
        trigger = 0;
        challenge = 0;

        $display("-------------------------------------------------------------");
        $display("Starting 8x8 Arbiter PUF Simulation");
        $display("-------------------------------------------------------------");

        // --- Test Case 1 ---
        apply_challenge_test(8'b10101010);

        // --- Test Case 2 ---
        apply_challenge_test(8'b00000000);

        // --- Test Case 3 ---
        apply_challenge_test(8'b11111111);
        
        $display("-------------------------------------------------------------");
        $display("Simulation Complete. Output dumped to arbiter_puf_multi.vcd");
        $finish;
    end
      
endmodule
