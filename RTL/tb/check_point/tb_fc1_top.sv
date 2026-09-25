`timescale 1ns/1ps

module tb_fc1_top();

    // --- Interconnect Signals ---
    logic         clk;
    logic         rst_n;
    logic         pw_valid;
    logic [17:0]  pw_data;
    logic [3:0]   rr_data;
    
    logic         fc1_valid;
    logic [31:0]  fc1_data_out;

    // --- Device Under Test (DUT) ---
    fc1_top dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .pw_valid     (pw_valid),
        .pw_data      (pw_data),
        .rr_data      (rr_data),
        .fc1_valid    (fc1_valid),
        .fc1_data_out (fc1_data_out)
    );

    // --- Clock Generation (50MHz -> 20ns period) ---
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // --- Test Scenario ---
    integer i;
    initial begin
        // Initial State
        rst_n    = 1'b0;
        pw_valid = 1'b0;
        pw_data  = 18'h0;
        rr_data  = 4'h0;
        
        #45;
        rst_n = 1'b1; 
        @(negedge clk);

        $display("====================================================");
        $display("[SYSTEM] STARTING STREAMING SIMULATION FOR FC1_TOP");
        $display("====================================================");

        // --- TEST CASE 1: FRAME 1 ---
        // Simulate abnormal heart rate (ARR), short RR interval = 4'b0101
        rr_data = 4'b0101; 
        
        // Stream 169 pixels continuously (13x13 Frame)
        for (i = 0; i < 169; i++) begin
            pw_valid = 1'b1;
            // Generate toggle data for polarity testing
            pw_data  = i[17:0] ^ 18'h15A5A; 
            @(negedge clk);
        end
        
        // Halt stream after Frame 1
        pw_valid = 1'b0;
        pw_data  = 18'h0;
        
        // Wait for Pipeline to flush out the result
        @(posedge fc1_valid);
        $display("[TIME: %0t] -> [FRAME 1 DONE] FC1 Output: 32'h%h", $time, fc1_data_out);
        
        #100;
        
        // --- TEST CASE 2: FRAME 2 ---
        // Test continuous operation with different RR = 4'b1010
        @(negedge clk);
        rr_data = 4'b1010;
        
        for (i = 0; i < 169; i++) begin
            pw_valid = 1'b1;
            // Invert data logic
            pw_data  = ~(i[17:0] & 18'h3FFFF); 
            @(negedge clk);
        end
        
        pw_valid = 1'b0;
        pw_data  = 18'h0;

        @(posedge fc1_valid);
        $display("[TIME: %0t] -> [FRAME 2 DONE] FC1 Output: 32'h%h", $time, fc1_data_out);

        #100;
        $display("====================================================");
        $display("[SYSTEM] SIMULATION COMPLETED SUCCESSFULLY");
        $display("====================================================");
        $finish;
    end

    // --- Timeout Monitor ---
    initial begin
        // Extended timeout for 2 full frames + latency
        #50000;
        $display("[ERROR] TIMEOUT! Pipeline is stuck. Check pixel_cnt and shift_reg routing.");
        $finish;
    end

endmodule