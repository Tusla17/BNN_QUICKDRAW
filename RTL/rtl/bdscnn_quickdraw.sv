module bdscnn_quickdraw (
    input  logic       clk,
    input  logic       rst_n,

    output logic [6:0] hex0,
    output logic [6:0] hex1,
    output logic [6:0] hex2,
    output logic [6:0] hex3,
    output logic [6:0] hex4,
    output logic [6:0] hex5
  );

  // ISSP
  logic start_trigger;
  issp_start u_issp (.source(start_trigger));

  logic start_d;
  logic start_pulse;
  always_ff @(posedge clk) start_d <= start_trigger;
  assign start_pulse = start_trigger & ~start_d;


  logic auto_rst_n;
  assign auto_rst_n = rst_n & ~start_pulse;


  logic [9:0] ram_addr;
  logic       ram_q;

  ram_img u_ram (
            .address (ram_addr),
            .clock   (clk),
            .data    (1'b0),
            .wren    (1'b0),
            .q       (ram_q)
          );


  logic [10:0] stream_cnt;
  logic        pumping;
  logic        img_valid;

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      stream_cnt <= '0;
      pumping    <= 1'b0;
      img_valid  <= 1'b0;
    end
    else
    begin
      img_valid <= (pumping && stream_cnt < 11'd1024);

      if (start_pulse)
      begin
        pumping    <= 1'b1;
        stream_cnt <= '0;
      end
      else if (pumping)
      begin
        if (stream_cnt < 11'd1024)
          stream_cnt <= stream_cnt + 1'b1;
        else
          pumping <= 1'b0;
      end
    end
  end

  assign ram_addr = stream_cnt[9:0];


  logic       sys_valid;
  logic [3:0] class_result;

  bdscnn_top u_bdscnn (
               .clk       (clk),
               .rst_n     (auto_rst_n), 
               .img_valid (img_valid),
               .img_data  (ram_q),
               .sys_valid (sys_valid),
               .class_out (class_result)
             );

  // active low
  logic       display_valid;
  logic [3:0] latched_class;

  always_ff @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      display_valid <= 1'b0;
      latched_class <= 4'd0;
    end
    else if (start_pulse)
    begin
      display_valid <= 1'b0;
    end
    else if (sys_valid)
    begin
      display_valid <= 1'b1;
      latched_class <= class_result;
    end
  end

  // 0 is ligt
  localparam CHAR_C     = 7'b1000110;
  localparam CHAR_L     = 7'b1000111;
  localparam CHAR_A     = 7'b0001000;
  localparam CHAR_S     = 7'b0010010;
  localparam CHAR_BLANK = 7'b1111111;


  assign hex5 = display_valid ? CHAR_C : CHAR_BLANK;
  assign hex4 = display_valid ? CHAR_L : CHAR_BLANK;
  assign hex3 = display_valid ? CHAR_A : CHAR_BLANK;
  assign hex2 = display_valid ? CHAR_S : CHAR_BLANK;
  assign hex1 = display_valid ? CHAR_S : CHAR_BLANK;


  always_comb
  begin
    if (!display_valid)
    begin
      hex0 = CHAR_BLANK;
    end
    else
    begin
      case (latched_class)
        4'd0:
          hex0 = 7'b1000000; // 0
        4'd1:
          hex0 = 7'b1111001; // 1
        4'd2:
          hex0 = 7'b0100100; // 2
        4'd3:
          hex0 = 7'b0110000; // 3
        4'd4:
          hex0 = 7'b0011001; // 4
        4'd5:
          hex0 = 7'b0010010; // 5
        4'd6:
          hex0 = 7'b0000010; // 6
        4'd7:
          hex0 = 7'b1111000; // 7
        4'd8:
          hex0 = 7'b0000000; // 8
        4'd9:
          hex0 = 7'b0010000; // 9
        default:
          hex0 = 7'b0111111;
      endcase
    end
  end

endmodule
