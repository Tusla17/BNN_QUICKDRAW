import os

def hex_file_to_sv_localparam(input_filename, param_name, width, is_signed=False):
    # Đổi đuôi .txt thành _param.sv cho file đầu ra
    output_filename = input_filename.replace('.txt', '_param.sv')
    signed_str = "signed " if is_signed else ""
    
    try:
        with open(input_filename, 'r') as f:
            lines = [l.strip() for l in f if l.strip()]
            
        with open(output_filename, 'w') as f_out:
            f_out.write(f"localparam logic {signed_str}[{width-1}:0] {param_name} [0:{len(lines)-1}] = '{{\n")
            for i, val in enumerate(lines):
                comma = "," if i < len(lines) - 1 else ""
                f_out.write(f"    {width}'h{val}{comma}\n")
            f_out.write("};\n")
            
        print(f"[THÀNH CÔNG] Đã tạo file: {output_filename}")
        
    except FileNotFoundError:
        print(f"[LỖI] Không tìm thấy file {input_filename} trong thư mục hiện tại.")

def merge_luts_to_single_file(num_classes, width, output_filename):
    try:
        with open(output_filename, 'w') as f_out:
            f_out.write("// ==========================================\n")
            f_out.write("// BẢNG TRA CỨU (LUT) CHO 10 CLASS\n")
            f_out.write("// ==========================================\n\n")
            
            for c in range(num_classes):
                input_filename = f"fc2_lut_{c}.txt"
                param_name = f"lut_{c}"
                try:
                    with open(input_filename, 'r') as f:
                        lines = [l.strip() for l in f if l.strip()]
                    
                    # Thêm 'signed' vì giá trị threshold/LUT có thể âm
                    f_out.write(f"localparam logic signed [{width-1}:0] {param_name} [0:{len(lines)-1}] = '{{\n")
                    for i, val in enumerate(lines):
                        comma = "," if i < len(lines) - 1 else ""
                        f_out.write(f"    {width}'h{val}{comma}\n")
                    f_out.write("};\n\n")
                except FileNotFoundError:
                    print(f"[LỖI] Không tìm thấy file {input_filename}. Đảm bảo bạn đang chạy trong đúng thư mục!")
                    return
                    
        print(f"🎉 [THÀNH CÔNG XUẤT SẮC] Đã gộp {num_classes} bảng LUT vào 1 file duy nhất: {output_filename}")
    except Exception as e:
        print(f"[LỖI] Quá trình gộp file thất bại: {e}")

if __name__ == "__main__":
    print("====================================================")
    print("ĐANG ÉP KIỂU HEX THÀNH SYSTEMVERILOG LOCALPARAM...")
    
    # 1. Các file độc lập
    hex_file_to_sv_localparam("pw_weights.txt", "pw_weights", 3)
    hex_file_to_sv_localparam("pw_thresh.txt", "pw_thresh", 17)
    hex_file_to_sv_localparam("fc2_weights.txt", "fc2_weights", 64) # Chú ý: Trọng số FC2 giờ rộng 64-bit
    
    # 2. Gộp 10 file LUT của FC2 thành 1 file duy nhất (Độ rộng mặc định của score là 32-bit)
    merge_luts_to_single_file(num_classes=10, width=32, output_filename="fc2_lut_all_param.sv")
    
    print("====================================================")
