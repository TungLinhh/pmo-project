# Tổng hợp 7 quy trình Visio (OCR) + Quy chế CBCNV

> Nguồn: 6 PDF (Visio flowchart) + 1 .docx được bạn cung cấp ngày 2026-08-29.
> OCR bằng `tesseract` (vie+eng) + `pdftoppm` (300dpi).
> File gốc: `reference_sheets_extra/`, kết quả OCR: `docs/_ocr_output/`.

## Tóm tắt nhanh

### 1. QUY TRÌNH AN TOÀN LAO ĐỘNG (1851 chars)
Flowchart 4 bước:
- **Bước 1**: Kiểm tra hiện trạng mặt bằng thi công, lập danh mục thiết bị
- **Bước 2**: Lập kế hoạch trang thiết bị phương tiện an toàn
- **Bước 3**: Giám sát quá trình lắp đặt trang bị an toàn
- **Bước 4**: Lập kế hoạch đào tạo (nội dung, tài liệu đào tạo)

### 2. QUY TRÌNH SHOP, HC (2641 chars)
Flow 6-7 bước cho shop drawing / hợp đồng:
- Kiểm tra hồ sơ thiết kế
- Lập bản vẽ shop
- Trình BQLDA review
- Phản hồi (nếu fail → sửa → resubmit)
- Phê duyệt → phát hành bản vẽ
- Lưu hồ sơ

### 3. QUY TRÌNH THANH TOÁN NCC (891 chars)
Flow 3-4 bước:
- NCC gửi hồ sơ thanh toán
- Phòng kế toán kiểm tra
- Phê duyệt → chuyển khoản
- Lưu hồ sơ

### 4. QUY TRÌNH THANH TOÁN TP (2091 chars)
Flowchart thanh toán thầu phụ tương tự NCC + thêm bước:
- Xác nhận khối lượng hoàn thành
- Đối chiếu hợp đồng
- Thanh toán theo đợt

### 5. QUY TRÌNH THI CÔNG (2002 chars)
Flow 5-6 bước:
- Nhận mặt bằng
- Lập biện pháp thi công (BPTC)
- Triển khai thi công
- Giám sát, nghiệm thu
- Bàn giao → thanh toán

### 6. QUY TRÌNH VẬT TƯ (9745 chars)
Flowchart dài nhất, 8-10 bước:
- Lập dự trù vật tư
- Xin phê duyệt
- Chọn NCC
- Ký hợp đồng cung ứng
- Theo dõi giao hàng
- Nghiệm thu vật tư
- Lưu kho / cấp cho công trường
- Theo dõi sử dụng, đối chiếu

### 7. QUY CHẾ ĐÁNH GIÁ CBCNV (6563 chars) — unencrypted .docx
**Đầy đủ nội dung**, có cấu trúc Chương/Điều:

**Chương I – Quy định chung**
- Điều 1: Mục đích — khen thưởng, động viên thành tích + kỷ luật vi phạm
- Điều 2: Đối tượng — CBCNV ký HĐLĐ chính thức, các Phòng/Đơn vị dự án

**Các chương tiếp theo** (xem file `Quy chế đánh giá CBCNV.txt`):
- Chương II: Tiêu chuẩn xếp loại
- Chương III: Quy trình đánh giá
- Chương IV: Khen thưởng / Kỷ luật

## Ghi chú
- 6 Visio PDF có chất lượng OCR thấp (flowchart + text nhỏ), nhưng tên bước chính vẫn trích được
- Quy chế CBCNV có nội dung đầy đủ, có thể tạo thêm table `hr_policies` nếu cần
- Tất cả OCR output lưu tại `docs/_ocr_output/`
