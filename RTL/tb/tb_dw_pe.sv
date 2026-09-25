`timescale 1ns/1ps

module tb_dw_pe();

    // --- Khai báo tín hiệu ---
    logic       clk;
    logic       rst_n;
    logic       valid_in;
    logic [8:0] window_in;
    logic [8:0] weight_in;
    
    logic       valid_out;
    logic [3:0] data_out;

    // --- Khai báo ROM chứa Trọng số ---
    // Mảng 3 phần tử, mỗi phần tử 9 bit
    logic [8:0] dw_rom [0:2]; 

    // --- Instantiate DUT ---
    dw_pe dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .window_in(window_in),
        .weight_in(weight_in),
        .valid_out(valid_out),
        .data_out(data_out)
    );

    // --- Tạo Clock ---
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // --- Kịch bản Test ---
    initial begin
        // 1. Nạp file hex vào ROM (Đảm bảo file hex nằm cùng thư mục mô phỏng)
        $readmemh("/home/ctw-fpga/Desktop/project/ecg_disease/RTL/tb/dw_weights.hex", dw_rom);
        
        rst_n = 0;
        valid_in = 0;
        window_in = 0;
        
        // Móc trọng số của Kênh 1 (Dòng đầu tiên: 05d) vào mạch
        weight_in = dw_rom[0]; 

        #25 rst_n = 1;
        @(negedge clk);

        // --- Bơm Test Case 1: Cửa sổ toàn bit 1 ---
        // Popcount kỳ vọng: AND toàn bit 1 với '0 0101 1101' sẽ giữ nguyên. 
        // Đếm số bit 1 của '05d' = 5. Output phải ra 5.
        valid_in = 1;
        window_in = 9'b111111111; 
        @(negedge clk);

        // --- Bơm Test Case 2: Cửa sổ xen kẽ ---
        // window: 9'b0_1010_1010
        // weight: 9'b0_0101_1101 (05d)
        // AND   : 9'b0_0000_1000 -> Đếm số bit 1 = 1. Output phải ra 1.
        valid_in = 1;
        window_in = 9'b010101010;
        @(negedge clk);

        // Dừng bơm
        valid_in = 0;
        
        #50;
        $finish;
    end

    // --- Monitor theo dõi Pipeline 2 tầng ---
    always @(posedge clk) begin
        if (valid_out) begin
            $display("Time: %0t | VALID OUT | Popcount Result = %0d", $time, data_out);
        end
    end

endmodule
