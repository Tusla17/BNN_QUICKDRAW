`timescale 1ns/1ps

module tb_bdscnn_top();

  logic        clk;
  logic        rst_n;
  logic        img_valid;
  logic        img_data;

  logic        sys_valid;
  logic [3:0]  class_out; 

  bdscnn_top dut (
               .clk       (clk),
               .rst_n     (rst_n),
               .img_valid (img_valid),
               .img_data  (img_data),
               .sys_valid (sys_valid),
               .class_out (class_out)
             );

  
  initial begin
    clk = 0;
    forever #10 clk = ~clk; // Clock 50MHz
  end

  // Mảng lưu trữ ảnh và Metadata
  logic        mem_img [0:1023];
  logic [3:0]  meta_exp_class; // Sửa thành 4 bit

  integer i, test_idx;
  integer fd;
  integer dummy;
  
  initial begin
    rst_n     = 0;
    img_valid = 0;
    img_data  = 0;

    #45;
    rst_n = 1;
    @(negedge clk);

    $display("====================================================");
    $display("[SYSTEM] STARTING QUICK DRAW! HARDWARE SIMULATION");
    $display("====================================================");

    
    for (test_idx = 0; test_idx < 10; test_idx++) begin

      
      $readmemb($sformatf("/home/huyatieo/Desktop/project/BNN/quick_draw/RTL/fpga_test_vectors/test_img_%0d.txt", test_idx), mem_img);

     
      fd = $fopen($sformatf("/home/huyatieo/Desktop/project/BNN/quick_draw/RTL/fpga_test_vectors/test_meta_%0d.txt", test_idx), "r");
      if (fd) begin
        dummy = $fscanf(fd, "%d\n", meta_exp_class);
        $fclose(fd);
      end else begin
        $display("[ERROR] Cannot open metadata file! Check your directory.");
        $finish;
      end

      $display("[INFO] Streaming Test Sample %0d (Expected Class: %0d)...", test_idx, meta_exp_class);

      
      for (i = 0; i < 1024; i++) begin
        img_valid = 1'b1;
        img_data  = mem_img[i];
        @(negedge clk);
      end

      
      img_valid = 1'b0;
      img_data  = 1'b0;

      
      @(posedge sys_valid);

      
      if (class_out == meta_exp_class) begin
        $display("   [TIME: %0t] -> MATCH! RTL Predicted: %0d", $time, class_out);
      end else begin
        $display("   [TIME: %0t] -> FAIL! Expected: %0d, Got: %0d", $time, meta_exp_class, class_out);
      end

      
      #200;
    end

    $display("====================================================");
    $display("[SYSTEM] SIMULATION COMPLETED");
    $display("====================================================");
    $finish;
  end

  // --- Timeout Monitor ---
  initial begin
    #500000; // Timeout
    $display("[ERROR] TIMEOUT! Pipeline is stuck.");
    $finish;
  end

endmodule