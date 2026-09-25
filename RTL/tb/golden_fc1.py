import os

def to_signed_16bit(val):
    """Ép kiểu số nguyên 16-bit không dấu sang có dấu (Bù 2)"""
    if val >= 0x8000:
        return val - 0x10000
    return val

def simulate_frame(rr_data, is_frame1):
    """Giả lập cơ chế thanh ghi dịch 3042 bit từ dữ liệu luồng"""
    shift_reg = 0
    
    for i in range(169):
        if is_frame1:
            # pw_data  = i[17:0] ^ 18'h15A5A;
            pw_data = i ^ 0x15A5A
        else:
            # pw_data  = ~(i[17:0] & 18'h3FFFF);
            pw_data = (~i) & 0x3FFFF
            
        # Dịch trái 18 bit và nhồi pw_data vào LSB (giữ đúng 3042 bit)
        shift_reg = ((shift_reg << 18) | pw_data) & ((1 << 3042) - 1)
        
    # Ghép 4 bit RR vào MSB (bit 3045:3042)
    fc1_input_vector = (rr_data << 3042) | shift_reg
    return fc1_input_vector

def main():
    print("========================================")
    print("🚀 CHẠY GOLDEN MODEL ĐỐI CHIẾU LỚP FC1")
    print("========================================")
    
    # 1. Đọc Trọng số và Ngưỡng
    try:
        with open("fc1_weights.hex", "r") as f:
            weights = [int(line.strip(), 16) for line in f if line.strip()]
        with open("fc1_thresh.hex", "r") as f:
            thresholds = [int(line.strip(), 16) for line in f if line.strip()]
    except FileNotFoundError as e:
        print(f"❌ Lỗi: Không tìm thấy file hex - {e}")
        return

    # 2. Sinh dữ liệu 2 Frame y hệt Testbench
    frames = [
        ("FRAME 1", simulate_frame(rr_data=0x5, is_frame1=True)),
        ("FRAME 2", simulate_frame(rr_data=0xA, is_frame1=False))
    ]

    # 3. Quét qua 32 Neuron để tính toán
    for frame_name, input_vector in frames:
        output_32bit = 0
        
        for i in range(32):
            # Tính Popcount của phép AND
            and_res = input_vector & weights[i]
            popcount = bin(and_res).count('1')
            
            # Giải mã Threshold (Bit 16: Polarity, Bit 15:0 Value có dấu)
            th_raw = thresholds[i]
            polarity = (th_raw >> 16) & 1
            thresh_val = to_signed_16bit(th_raw & 0xFFFF)
            
            # So sánh
            if polarity == 1:
                bit_out = 1 if popcount >= thresh_val else 0
            else:
                bit_out = 1 if popcount <= thresh_val else 0
                
            # Gắn vào vị trí bit thứ i của kết quả
            output_32bit |= (bit_out << i)
            
        print(f"✅ {frame_name} Golden Output : 32'h{output_32bit:08x}")

if __name__ == "__main__":
    main()
