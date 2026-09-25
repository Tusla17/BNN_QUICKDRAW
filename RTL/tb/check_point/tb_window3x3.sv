`timescale 1ns/1ps

module tb_window3x3();

    // --- CẤU HÌNH THAM SỐ ---
    parameter int DATA_WIDTH = 8;
    parameter int IMG_WIDTH  = 4;

    // --- KHAI BÁO TÍN HIỆU ---
    logic clk;
    logic rst_n;
    logic din_valid;
    logic [DATA_WIDTH-1:0] din;
    
    logic dout_valid;
    logic [9*DATA_WIDTH-1:0] dout_window;

    // --- INSTANTIATE DUT ---
    window3x3 #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .din_valid(din_valid),
        .din(din),
        .dout_valid(dout_valid),
        .dout_window(dout_window)
    );

    // --- TẠO CLOCK (Ví dụ 50MHz trên DE10-Nano) ---
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // Chu kỳ 20ns
    end

    // --- BÓC TÁCH MẢNG DUỖI PHẲNG ĐỂ IN RA MÀN HÌNH ---
    logic [DATA_WIDTH-1:0] win [0:8];
    genvar i;
    generate
        for (i = 0; i < 9; i++) begin
            assign win[i] = dout_window[i*DATA_WIDTH +: DATA_WIDTH];
        end
    endgenerate

    // --- BIẾN ĐẾM SỐ LẦN VALID ---
    integer valid_count = 0;

    // --- KỊCH BẢN BƠM DỮ LIỆU ---
    initial begin
        // Khởi tạo
        rst_n = 0;
        din_valid = 0;
        din = 0;

        // Reset hệ thống
        #25 rst_n = 1;
        @(negedge clk);

        $display("========================================");
        $display("🚀 START STREAMING 4x4 (PIXEL 1 -> 16)");
        $display("========================================");

        // Bơm liên tục 16 pixel vào ống
        for (int p = 1; p <= 16; p++) begin
            din_valid = 1;
            din = p;
            @(negedge clk); // Đợi đến sườn xuống tiếp theo
        end

        // Dừng bơm dữ liệu
        din_valid = 0;
        din = 0;
        #100; // Đợi thêm vài chu kỳ xem mạch có nhả rác không

        // Kết luận
        $display("========================================");
        if (valid_count == 4)
            $display("✅ PASSED: Circuit create 4 valid results as expected!");
        else
            $display("❌ FAILED: Circuit create %0d results (EXPECTED: 4).", valid_count);
        $display("========================================");

        $finish;
    end

    // --- TRẠM QUAN SÁT (MONITOR) CỜ VALID ---
    always @(posedge clk) begin
        if (dout_valid) begin
            valid_count++;
            $display("Time: %0t | VALID WINDOW NUMBER #%0d", $time, valid_count);
            // In theo đúng hình dạng ma trận 3x3 
            // Lưu ý: Do index 0-2 là hàng cũ nhất (Hàng 1), 6-8 là hàng mới nhất (Hàng 3)
            $display("  [%2d, %2d, %2d]", win[0], win[1], win[2]);
            $display("  [%2d, %2d, %2d]", win[3], win[4], win[5]);
            $display("  [%2d, %2d, %2d]\n", win[6], win[7], win[8]);
        end
    end

endmodule