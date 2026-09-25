`timescale 1ns/1ps

module tb_pw_pe();

    // --- Khai báo tín hiệu ---
    logic        clk;
    logic        rst_n;
    
    logic        valid_in;
    logic [3:0]  dw_out_0, dw_out_1, dw_out_2;
    logic [2:0]  weight_in;
    logic [16:0] thresh_in;
    
    logic        valid_out;
    logic        data_out;

    // --- Gọi khối PW_PE CỦA BRO (Mạch bị lỗi) ---
    pw_pe dut (
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_in),
        .dw_out_0(dw_out_0), .dw_out_1(dw_out_1), .dw_out_2(dw_out_2),
        .weight_in(weight_in), .thresh_in(thresh_in),
        .valid_out(valid_out), .data_out(data_out)
    );

    // --- Tạo Clock ---
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // --- BƠM DỮ LIỆU ---
    initial begin
        rst_n = 0; valid_in = 0;
        dw_out_0 = 0; dw_out_1 = 0; dw_out_2 = 0;
        weight_in = 0; thresh_in = 0;
        
        #25 rst_n = 1;
        @(negedge clk);

        $display("========================================");
        $display("🔥 BẮT ĐẦU CHẠY TESTBENCH SÁT THỦ (STREAMING)");
        $display("========================================");

        // ----------------------------------------------------
        // NHỊP 1: Bơm Dữ liệu A và Ngưỡng A
        // Tổng A = 4 + 4 + 4 = 12
        // Ngưỡng A = 15 (Polarity = 1)
        // KẾT QUẢ ĐÚNG PHẢI LÀ: 12 >= 15 -> Ra 0.
        // ----------------------------------------------------
        valid_in = 1;
        weight_in = 3'b111;
        thresh_in = {1'b1, 16'd15}; // Ngưỡng 15
        dw_out_0 = 4'd4; dw_out_1 = 4'd4; dw_out_2 = 4'd4; 
        @(negedge clk);

        // ----------------------------------------------------
        // NHỊP 2: Bơm LIỀN NGAY Dữ liệu B và Ngưỡng B
        // Tổng B = 0 + 0 + 0 = 0
        // Ngưỡng B = 5 (Polarity = 1)
        // KẾT QUẢ ĐÚNG PHẢI LÀ: 0 >= 5 -> Ra 0.
        // ----------------------------------------------------
        valid_in = 1;
        weight_in = 3'b111;
        thresh_in = {1'b1, 16'd5}; // Ngưỡng 5
        dw_out_0 = 4'd0; dw_out_1 = 4'd0; dw_out_2 = 4'd0; 
        @(negedge clk);

        // Dừng bơm
        valid_in = 0;
        
        #50;
        $display("========================================");
        $finish;
    end

    // --- Trạm quan sát ---
    integer tc_count = 0;
    always @(posedge clk) begin
        if (valid_out) begin
            tc_count++;
            $display("🕒 Time: %0t | Clk %0d | Output = %b (EXPT: 0)", $time, tc_count, data_out);
            if (data_out == 1'b1) 
                $display("   ❌ FAIL!");
        end
    end

endmodule