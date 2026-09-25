import numpy as np
import os

def get_popcount(val):
    """Tính số lượng bit 1 trong một số nguyên"""
    return bin(val).count('1')

def main():
    print("====================================================")
    print("🚀 CHẠY GOLDEN MODEL ĐỐI CHIẾU LỚP FC2 (FLOAT MATH)")
    print("====================================================")
    
    # 1. Đọc Trọng số
    try:
        with open("fc2_weights.hex", "r") as f:
            weights = [int(line.strip(), 16) for line in f if line.strip()]
    except FileNotFoundError:
        print("❌ Lỗi: Không tìm thấy file fc2_weights.hex")
        return

    # 2. Đọc Tham số BN nguyên thủy của AI
    try:
        gammas = np.loadtxt("fc2_bn_gamma.txt")
        betas  = np.loadtxt("fc2_bn_beta.txt")
        means  = np.loadtxt("fc2_bn_mean.txt")
        vars_  = np.loadtxt("fc2_bn_var.txt")
    except Exception as e:
        print(f"❌ Lỗi đọc file txt: {e}")
        return
        
    eps = 1e-5

    # 3. Kịch bản test (Khớp 100% với tb_fc2_top.sv)
    test_cases = [
        ("TEST 1", 0xFFFFFFFF),
        ("TEST 2", 0x4FFEFEE3),
        ("TEST 3", 0x00000101)
    ]

    # 4. Tính toán
    for name, data in test_cases:
        scores = []
        pops = []
        
        for i in range(3):
            # Tính Popcount từ phép AND
            and_res = data & weights[i]
            pc = get_popcount(and_res)
            pops.append(pc)
            
            # Tính điểm số Float bằng công thức Batch Normalization chuẩn
            score_float = gammas[i] * (pc - means[i]) / np.sqrt(vars_[i] + eps) + betas[i]
            scores.append(score_float)
            
        # Tìm Nơ-ron có điểm cao nhất (Argmax)
        pred_class = np.argmax(scores)
        
        # Format kết quả sang mã nhị phân 2-bit (00, 01, 10)
        class_bin = format(pred_class, '02b')
        
        print(f"✅ [{name}] FC1 Data: {data:08x}")
        print(f"   => Popcounts : {pops}")
        print(f"   => Float Scores: [{scores[0]:.4f}, {scores[1]:.4f}, {scores[2]:.4f}]")
        print(f"   => Predicted Class: {class_bin}\n")

if __name__ == "__main__":
    main()
