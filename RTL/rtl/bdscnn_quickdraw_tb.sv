module bdscnn_quickdraw_tb (
    input  logic       clk,      // 50MHz
    input  logic       rst_n,    // SW[0]
    

    output logic [9:0] ledr      
);

    import hw_stimulus::*;

    logic [10:0] stream_cnt;
    logic        sys_valid;
    logic [3:0]  class_result;   

    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stream_cnt <= '0;
        end else if (stream_cnt < 11'd1024) begin
            stream_cnt <= stream_cnt + 1'b1;
        end
    end

    
    bdscnn_top u_bdscnn (
        .clk       (clk),
        .rst_n     (rst_n),
        .img_valid (stream_cnt < 11'd1024), 
        .img_data  (TEST_IMG[stream_cnt]),             
        .sys_valid (sys_valid),
        .class_out (class_result)
    );

    logic [9:0] led_reg;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_reg <= 10'b0;
        end else if (sys_valid) begin
            led_reg <= (10'd1 << class_result); 
        end
    end

    assign ledr = led_reg;

endmodule