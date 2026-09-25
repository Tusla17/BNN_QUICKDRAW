# ==============================================================================
# 1. Khởi tạo Clock
# ==============================================================================
# Tạo clock 50MHz (Chu kỳ = 20.000 ns) cho chân đầu vào 'clk'
create_clock -name clk -period 20.000 [get_ports {clk}]

# Tự động tính toán clock uncertainty (Jitter, dải bảo vệ timing)
derive_clock_uncertainty

# (Tùy chọn) Tự động suy luận clock từ PLL nếu trong lõi có dùng PLL
derive_pll_clocks

# ==============================================================================
# 2. Ràng buộc ngõ vào (Input Constraints)
# ==============================================================================
# rst_n (SW0) và start (SW1) là tín hiệu bất đồng bộ từ thao tác cơ học của con người
# -> Thiết lập False Path để bỏ qua việc phân tích timing từ các chân này vào thanh ghi
set_false_path -from [get_ports {rst_n start}] -to [all_registers]

# ==============================================================================
# 3. Ràng buộc ngõ ra (Output Constraints)
# ==============================================================================
# ledr[2:0] chỉ dùng để quan sát bằng mắt thường, không yêu cầu timing khắt khe
# -> Thiết lập False Path để bỏ qua việc phân tích timing từ thanh ghi ra chân LED
set_false_path -from [all_registers] -to [get_ports {ledr[*]}]
