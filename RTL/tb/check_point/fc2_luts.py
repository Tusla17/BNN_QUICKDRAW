import numpy as np

def generate_fc2_luts():
    print("========================================")
    print("🚀 TẠO BẢNG TRA CỨU (LUT) CHO LỚP FC2")
    print("========================================")
    
    # Đọc tham số nguyên thủy từ AI
    gammas = np.loadtxt("fc2_bn_gamma.txt")
    betas  = np.loadtxt("fc2_bn_beta.txt")
    means  = np.loadtxt("fc2_bn_mean.txt")
    vars_  = np.loadtxt("fc2_bn_var.txt")
    eps = 1e-5

    # 3 Nơ-ron tương ứng với 3 file HEX
    for i in range(3):
        filename = f"fc2_lut_{i}.hex"
        with open(filename, "w") as f:
            # Popcount của FC2 chỉ có thể nằm trong khoảng 0 -> 32
            for x in range(33):
                # 1. Tính giá trị Float thực tế của BatchNorm
                y_float = gammas[i] * (x - means[i]) / np.sqrt(vars_[i] + eps) + betas[i]
                
                # 2. Lượng tử hóa (Nhân với 2^16 để giữ độ phân giải phần thập phân)
                y_quant = int(round(y_float * 65536))
                
                # 3. Ép kiểu Bù 2 cho số âm (32-bit)
                if y_quant < 0:
                    y_quant = (1 << 32) + y_quant
                    
                # Ghi xuống file dưới dạng 8 ký tự Hex
                f.write(f"{y_quant:08x}\n")
                
        print(f"✅ Đã tạo xong {filename} (33 giá trị lượng tử 32-bit)")

if __name__ == "__main__":
    generate_fc2_luts()
