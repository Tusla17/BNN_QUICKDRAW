`timescale 1ns/1ps

module tb_fc1_neuron();

    // --- Khai báo tín hiệu ---
    logic             clk;
    logic             rst_n;
    
    logic             valid_in;
    logic [3045:0]    data_in;
    logic [3045:0]    weight_in;
    logic [16:0]      thresh_in;
    
    logic             valid_out;
    logic             data_out;

    // --- ROM chứa Trọng số (Khai báo mảng chứa đủ 32 dòng) ---
    // Python xuất hex align theo bội số của 4, nên 3046 bit được độn thành 3048 bit
    logic [3047:0]    fc1_weights [0:31]; 
    logic [16:0]      fc1_thresh [0:31];

    // --- Instantiate DUT ---
    fc1_neuron dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_in(data_in),
        .weight_in(weight_in),
        .thresh_in(thresh_in),
        .valid_out(valid_out),
        .data_out(data_out)
    );

    // --- Tạo Clock ---
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // --- KỊCH BẢN BƠM DỮ LIỆU ---
    initial begin
        // Nhớ đảm bảo 2 file này nằm cùng thư mục mô phỏng trên Ubuntu
        $readmemh("/home/ctw-fpga/Desktop/project/ecg_disease/RTL/tb/fc1_weights.hex", fc1_weights);
        $readmemh("/home/ctw-fpga/Desktop/project/ecg_disease/RTL/tb/fc1_thresh.hex", fc1_thresh);

        rst_n = 0; valid_in = 0;
        data_in = 0; weight_in = 0; thresh_in = 0;
        
        #25 rst_n = 1;
        @(negedge clk);

        $display("========================================");
        $display("🚀 BẮT ĐẦU TEST FC1 NEURON");
        $display("========================================");

        // ----------------------------------------------------
        // TEST CASE 1: Neuron 0 (Có Ngưỡng Âm)
        // Dữ liệu: Thresh từ file là 1fffd -> Polarity=1 (>=), Value = fffd (-3).
        // Bơm data toàn 0 -> Popcount = 0.
        // Kỳ vọng: 0 >= -3 (Đúng) -> Phải nhả ra 1.
        // ----------------------------------------------------
        valid_in = 1;
        weight_in = fc1_weights[0][3045:0]; // Chỉ bốc đúng 3046 bit
        thresh_in = fc1_thresh[0];
        data_in = '0; 
        @(negedge clk);

        // ----------------------------------------------------
        // TEST CASE 2: Neuron 1 (Có Ngưỡng Dương)
        // Dữ liệu: Thresh từ file là 1000a -> Polarity=1 (>=), Value = 000a (10).
        // Bơm data toàn 0 -> Popcount = 0.
        // Kỳ vọng: 0 >= 10 (Sai) -> Phải nhả ra 0.
        // ----------------------------------------------------
        valid_in = 1;
        weight_in = fc1_weights[1][3045:0];
        thresh_in = fc1_thresh[1];
        data_in = '0; 
        @(negedge clk);

        // ----------------------------------------------------
        // TEST CASE 3: Đánh thức Neuron 1
        // Bơm data giống hệt weight của Neuron 1 -> Chắc chắn Popcount >= 10.
        // Kỳ vọng: Max >= 10 (Đúng) -> Phải nhả ra 1.
        // ----------------------------------------------------
        valid_in = 1;
        weight_in = fc1_weights[1][3045:0];
        thresh_in = fc1_thresh[1];
        data_in = fc1_weights[1][3045:0]; 
        @(negedge clk);

        // Dừng bơm
        valid_in = 0;
        
        #100;
        $display("========================================");
        $finish;
    end

    // --- Monitor ---
    integer tc_count = 0;
    always @(posedge clk) begin
        if (valid_out) begin
            tc_count++;
            $display("🕒 Time: %0t | Test Case #%0d | Output = %b", $time, tc_count, data_out);
        end
    end

endmodule