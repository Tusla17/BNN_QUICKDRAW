`timescale 1ns/1ps

module tb_fc2_top();

    // --- Các tín hiệu kết nối ---
    logic         clk;
    logic         rst_n;
    
    logic         fc1_valid;
    logic [31:0]  fc1_data_in;
    
    logic         fc2_valid;
    logic [1:0]   class_out;

    // --- Khởi tạo DUT ---
    fc2_top dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .fc1_valid   (fc1_valid),
        .fc1_data_in (fc1_data_in),
        .fc2_valid   (fc2_valid),
        .class_out   (class_out)
    );

    // --- Tạo Clock 50MHz ---
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // --- Kịch bản kiểm thử ---
    initial begin
        // Khởi tạo trạng thái
        rst_n       = 1'b0;
        fc1_valid   = 1'b0;
        fc1_data_in = 32'h0;
        
        #45;
        rst_n = 1'b1;
        @(negedge clk);

        $display("====================================================");
        $display("[SYSTEM] STARTING SIMULATION FOR FC2_TOP (ARGMAX LUT)");
        $display("====================================================");

        // --- TEST CASE 1: Bơm dữ liệu Golden từ FC1 (Max Popcount) ---
        fc1_valid   = 1'b1;
        fc1_data_in = 32'hFFFFFFFF; 
        @(negedge clk);
        fc1_valid   = 1'b0; // Chỉ nháy cờ Valid 1 nhịp (vì FC1 chốt ra song song)

        @(posedge fc2_valid);
        $display("[TIME: %0t] -> [TEST 1 DONE] FC1 Data: %h | Predicted Class: %b", $time, fc1_data_in, class_out);
        #50;

        // --- TEST CASE 2: Bơm dữ liệu có Popcount trung bình ---
        @(negedge clk);
        fc1_valid   = 1'b1;
        fc1_data_in = 32'h4FFEFEE3; 
        @(negedge clk);
        fc1_valid   = 1'b0;

        @(posedge fc2_valid);
        $display("[TIME: %0t] -> [TEST 2 DONE] FC1 Data: %h | Predicted Class: %b", $time, fc1_data_in, class_out);
        #50;

        // --- TEST CASE 3: Bơm dữ liệu thưa thớt (Min Popcount) ---
        @(negedge clk);
        fc1_valid   = 1'b1;
        fc1_data_in = 32'h00000101; 
        @(negedge clk);
        fc1_valid   = 1'b0;

        @(posedge fc2_valid);
        $display("[TIME: %0t] -> [TEST 3 DONE] FC1 Data: %h | Predicted Class: %b", $time, fc1_data_in, class_out);
        #50;

        $display("====================================================");
        $display("[SYSTEM] SIMULATION COMPLETED SUCCESSFULLY");
        $display("====================================================");
        $finish;
    end

    // --- Timeout Monitor ---
    initial begin
        #2000;
        $display("[ERROR] TIMEOUT! FC2 Pipeline is stuck. Check valid_stg routing.");
        $finish;
    end

endmodule