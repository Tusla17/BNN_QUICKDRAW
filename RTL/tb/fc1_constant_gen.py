import os

def hex_to_sv_package(weights_path, thresh_path, output_sv="fc1_constants.sv"):
    print("🚀 Đang đọc trọng số Quick Draw! từ file .txt...")
    
    weights = []
    with open(weights_path, 'r') as f:
        for line in f:
            weights.append(line.strip())
            
    threshs = []
    with open(thresh_path, 'r') as f:
        for line in f:
            threshs.append(line.strip())

    # [PHẢN BIỆN]: Kiểm tra an toàn xem có đúng 64 nơ-ron không
    if len(weights) != 64 or len(threshs) != 64:
        print(f"[CẢNH BÁO] Lỗi số lượng nơ-ron! Weights: {len(weights)}, Threshs: {len(threshs)}")

    with open(output_sv, "w") as f:
        f.write("package fc1_constants;\n")
        
        # ---------------------------------------------------------
        # GHI TRỌNG SỐ (64 NƠ-RON, ĐỘ RỘNG 3044 BIT)
        # ---------------------------------------------------------
        f.write("    localparam logic [3043:0] FC1_WEIGHTS [0:63] = '{\n")
        for i in range(64): # [CẬP NHẬT]: Tăng từ 32 lên 64
            # Dùng 3044'h vì lúc xuất từ Kaggle ta đã ép chunk_size=3044 để chia hết cho 4
            f.write(f"        3044'h{weights[i]}")
            f.write("," if i < 63 else "\n")
            f.write("\n")
        f.write("    };\n\n")

        # ---------------------------------------------------------
        # GHI NGƯỠNG BATCHNORM (64 NƠ-RON)
        # ---------------------------------------------------------
        f.write("    localparam logic [16:0] FC1_THRESH [0:63] = '{\n")
        for i in range(64): # [CẬP NHẬT]: Tăng từ 32 lên 64
            f.write(f"        17'h{threshs[i]}")
            f.write("," if i < 63 else "\n")
            f.write("\n")
        f.write("    };\n")
        f.write("endpackage\n")
    
    print(f"✅ Đã tạo xong {output_sv} với cấu hình 64 Nơ-ron cho Quick Draw!")

# Chạy với đường dẫn chuẩn
hex_to_sv_package(
    "fc1_weights.txt",
    "fc1_thresh.txt"
)