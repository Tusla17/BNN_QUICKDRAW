`timescale 1ns/1ps

module tb_popcount();

    // --- CẤU HÌNH THAM SỐ ---
    parameter int INPUT_WIDTH = 9;
    // Dùng localparam để tự tính độ rộng output cho Testbench
    localparam int OUT_WIDTH = $clog2(INPUT_WIDTH + 1); 

    // --- KHAI BÁO TÍN HIỆU ---
    logic [INPUT_WIDTH-1:0] data_in;
    logic [OUT_WIDTH-1:0]   count_out;

    // --- INSTANTIATE DUT (Design Under Test) ---
    // Gọi chính xác tên module và parameter của bro
    popcount #(
        .INPUT_WIDTH(INPUT_WIDTH)
    ) dut (
        .data_in(data_in),
        .count_out(count_out)
    );

    // --- BIẾN KIỂM TRA TỰ ĐỘNG ---
    integer golden_count;
    integer error_cnt = 0;

    // --- KỊCH BẢN MÔ PHỎNG ---
    initial begin
        $display("========================================");
        $display("🚀 STARTING POPCOUNT TESTBENCH");
        $display("========================================");

        // 1. Test các trường hợp biên (Corner Cases)
        data_in = '0; // All zeros
        #10; check_result();

        data_in = '1; // All ones (Max value)
        #10; check_result();
        
        data_in = 9'b101010101; // Alternating
        #10; check_result();

        // 2. Test ngẫu nhiên (Randomized Testing)
        for (int i = 0; i < 100; i++) begin
            // Tạo số ngẫu nhiên lấp đầy INPUT_WIDTH
            data_in = $urandom_range(0, (1<<INPUT_WIDTH) - 1);
            #10; check_result();
        end

        // 3. Kết luận
        $display("========================================");
        if (error_cnt == 0)
            $display("✅ PASSED: RTL code của bro chạy chuẩn không cần chỉnh!");
        else
            $display("❌ FAILED: Có %0d kết quả sai, check lại logic nhé bro.", error_cnt);
        $display("========================================");

        $finish;
    end

    // --- TASK ĐỐI CHIẾU KẾT QUẢ ---
    task check_result();
        golden_count = $countones(data_in);
        
        if (count_out !== golden_count) begin
            $display("[ERROR] Time %0t | Input: %b | Expected: %0d | RTL Got: %0d",
                     $time, data_in, golden_count, count_out);
            error_cnt++;
        end
    endtask

endmodule