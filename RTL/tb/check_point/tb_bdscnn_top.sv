`timescale 1ns/1ps

module tb_bdscnn_top();

    logic        clk;
    logic        rst_n;
    logic        img_valid;
    logic        img_data;
    logic [3:0]  rr_data;
    
    logic        sys_valid;
    logic [1:0]  class_out;

    bdscnn_top dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .img_valid (img_valid),
        .img_data  (img_data),
        .rr_data   (rr_data),
        .sys_valid (sys_valid),
        .class_out (class_out)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk; // Clock 50MHz
    end

    // Mảng lưu trữ ảnh và Metadata
    logic        mem_img [0:1023];
    logic [3:0]  meta_rr;
    logic [1:0]  meta_exp_class;

    integer i, test_idx;
    integer fd;
    integer dummy;
    initial begin
        rst_n     = 0;
        img_valid = 0;
        img_data  = 0;
        rr_data   = 0;

        #45;
        rst_n = 1;
        @(negedge clk);

        $display("====================================================");
        $display("[SYSTEM] STARTING FULL HARDWARE PIPELINE SIMULATION");
        $display("====================================================");

        // Chạy qua 3 mẫu test
        for (test_idx = 0; test_idx < 3; test_idx++) begin
            
            // 1. Nạp ảnh tĩnh và Metadata từ file
            $readmemb($sformatf("/home/ctw-fpga/Desktop/project/ecg_disease/RTL/fpga_test_vectors/test_img_%0d.txt", test_idx), mem_img);
            
            fd = $fopen($sformatf("/home/ctw-fpga/Desktop/project/ecg_disease/RTL/fpga_test_vectors/test_meta_%0d.txt", test_idx), "r");
            if (fd) begin
                
                // Gán vào biến dummy để ModelSim không la ó
                dummy = $fscanf(fd, "%h\n", meta_rr);
                dummy = $fscanf(fd, "%d\n", meta_exp_class);
                $fclose(fd);
            end else begin
                $display("[ERROR] Cannot open metadata file!");
                $finish;
            end

            $display("[INFO] Streaming Test Sample %0d (Expected: %0d)...", test_idx, meta_exp_class);
            rr_data = meta_rr;
            
            // 2. Bơm 1024 pixel (32x32) vào máy quét MCP
            for (i = 0; i < 1024; i++) begin
                img_valid = 1'b1;
                img_data  = mem_img[i];
                @(negedge clk);
            end
            
            // Dừng bơm ảnh
            img_valid = 1'b0;
            img_data  = 1'b0;

            // 3. Chờ toàn bộ Pipeline tính toán xong
            @(posedge sys_valid);
            
            // 4. Đối chiếu kết quả
            if (class_out == meta_exp_class) begin
                $display("   [TIME: %0t] -> MATCH! RTL Predicted: %b", $time, class_out);
            end else begin
                $display("   [TIME: %0t] -> FAIL! Expected: %0d, Got: %b", $time, meta_exp_class, class_out);
            end
            
            // Chờ một chút trước khi bơm khung hình tiếp theo
            #200;
        end

        $display("====================================================");
        $display("[SYSTEM] SIMULATION COMPLETED");
        $display("====================================================");
        $finish;
    end

    // --- Timeout Monitor ---
    initial begin
        #500000; // Nới lỏng Timeout để cho Pipeline chạy
        $display("[ERROR] TIMEOUT! Pipeline is stuck.");
        $finish;
    end

endmodule