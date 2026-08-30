# Tổng hợp quy trình nghiệp vụ — PMO Project

> **Trạng thái**: BƯỚC KHẢO SÁT — đã đọc tất cả 34 file tài liệu, 8/34 trích xuất được nội dung, 26/34 là PDF (bản vẽ kỹ thuật, RFA form).
> Cấu trúc heading = tên **phòng ban / chức năng** được phát hiện trong tài liệu.
> **Cập nhật 2026-08-29**: đã có câu trả lời cho 27 open questions (xem cuối file).

## Tổng quan nguồn

| Loại | Số lượng | Trích xuất text | Ghi chú |
|---|---|---|---|
| Tài liệu Word (.doc/.docx) trong `QUY TRÌNH/` | 8 | 1 docx đầy đủ, 1 docx bị mã hóa, 6 .doc là Visio embed (text không truy xuất được) | File .doc cũ chứa sơ đồ Visio nhúng; user sẽ upload bản PDF/ảnh sau |
| File PDF | 26 | Chỉ trích được 2-80 ký tự/file | Đa số là bản vẽ kỹ thuật, RFA form, shop drawing — **cần OCR** để search nội dung (làm sau MVP) |
| File Excel (.xlsx) | 59 | 2 file là quy trình dạng bảng | 2/59 file Excel chứa nội dung quy trình |

### Nguồn dự án có trong tài liệu

| Dự án | Mã | Năm | Mức độ tài liệu |
|---|---|---|---|
| **Bãi Tràm Estates** (Xuân Cảnh, Sông Cầu, Phú Yên) | **BTE-WP4-HBC** (BTE=Bãi Tràm, WP4=Work Package 4, HBC=HBG Construction) | 2019-2020 | Rất nhiều (folder chính) |
| **MELIA CAM RANH BAY VILLA & RESORT** | (dự án cũ, làm reference) | ? | Chỉ trong DS nhân lực/NCC |
| **LAWRENCE STING SCHOOL 2** (block C20) | (file lẻ ngoài folder) | 2021 | 1 file daily report |

### Đơn vị quản lý

- Folder gốc tên `2019.04.28 HBG-HBC-BCTT` — **BCTT = Báo Cáo Tổng Thể** (theo user xác nhận).
- **Multi-tenant strategy**: 1 tenant = 1 khách hàng/công ty (vd: tenant `hbg` chứa nhiều dự án của HBG).
- Trong dự án BTE: **1 gói thầu duy nhất** (MEP = Cơ điện = Cơ — cùng 1 gói, gọi khác EN vs VN).

---

## Phòng SXKD (Sản Xuất Kinh Doanh)

> **Nguồn**: `QUY TRÌNH/quy trình thực hiện dự án.xlsx` — sheet `Quy trình thực hiện dự án`, R7-R20.

### Quy trình "Thực hiện 1 dự án" — 8 bước

| STT | Tiến trình | Nội dung (tóm tắt) | Trách nhiệm thực hiện | Trách nhiệm kiểm tra / phê duyệt |
|---|---|---|---|---|
| 1 | **Bắt đầu** | Tiếp nhận thông báo trúng thầu, thương thảo, ký kết hợp đồng A-B, soạn quyết định giao nhiệm vụ, trình BGD phê duyệt | Phòng SXKD, Phòng TCHC | TGĐ ký HĐ A-B, PTGĐ phụ trách |
| 2 | **Lập Kế hoạch triển khai** | Lập kế hoạch tài chính, lập danh sách đội ngũ + vật tư | Chỉ huy trưởng công trường tìm hiểu dự án | Tr. phòng SXKD kiểm tra và trình BGD |
| 3 | **Ký kết với đơn vị cung cấp vật tư** | Thương thảo + ký kết hợp đồng cung ứng | Chỉ huy trưởng công trường | Tr. phòng SXKD kiểm tra |
| 4 | **Chuẩn bị triển khai** | Kiểm tra, chuẩn bị mặt bằng thi công | Chỉ huy trưởng công trường | Tr. phòng SXKD hướng dẫn |
| 5 | **Triển khai hợp đồng thi công** | Triển khai, nghiệm thu từng công việc | Các tổ công nhân, đơn vị thầu phụ | Các cá nhân, phòng ban liên quan |
| 6 | **Nghiệm thu hoàn thành, bàn giao công trình** | Kiểm tra, đánh giá điều kiện nghiệm thu | Chỉ huy trưởng công trường | Tr. phòng SXKD hướng dẫn |
| 7 | **Quyết toán, thanh lý hợp đồng** | Tổng hợp tài liệu, chứng từ | Cán bộ SXKD phụ trách khu vực | Tr. phòng SXKD kiểm tra |
| 8 | **Kết thúc** | Lập báo cáo tổng kết, họp tổng kết | Tất cả bên tham gia | Ban GĐ nhận xét đánh giá |

### Quy trình "Thuê thầu phụ, tổ đội"

> **Nguồn**: `QUY TRÌNH/Quy trình thuê thầu phụ, tổ đội.xlsx` — 2 sheet.

**Sheet 1 — `Danh mục theo dõi`**: ma trận giao việc giữa **6 tổ đội nội bộ** (A. Vương, A. Sinh, A. Thịnh, A. Hùng, A. Lùng, A. Vĩnh) × **4+ công ty thầu phụ** (Tín Nghĩa, V.Teco, Vinaceeco, Stronger, EnSol).

- Phân theo **3 nhóm hệ thống**: (I) Cấp thoát nước trong nhà, (II) Cấp thoát nước hạ tầng, (III) Xử lý nước thải.
- Mỗi hệ thống có 4-5 hạng mục con.
- Mỗi ô = `Tên người phụ trách` (không phải boolean).

**Sheet 2 — `THÔNG TIN TPTĐ`**: bảng chi tiết từng thầu phụ/tổ đội:
- STT, Họ tên, Số ĐT, Hạng mục (Điện/Nước/ĐH/Xử nước thải/Xử nước cấp/Nước đóng chai), Năng lực, Khu vực, Email.
- Có **9 thầu phụ** được liệt kê chi tiết.

---

## Phòng Hành Chính Nhân Sự (HCNS)

> **Nguồn**: `QUY TRÌNH/Cap phat BHLD.docx` — đọc được đầy đủ, hiệu lực từ 03/01/2015.

### Quy định cấp phát BHLĐ (Bảo Hộ Lao Động)

**Đối tượng**: CBCNV có hợp đồng lao động chính thức.

**Tiêu chuẩn cấp phát hằng năm** (bảng trong file):

| STT | Loại BHLĐ | Đơn vị | Số lượng | Niên hạn |
|---|---|---|---|---|
| 1 | Mũ bảo hộ | Cái | 01 | 12 tháng |
| 2 | Quần áo BHLĐ | Bộ | 01 | 12 tháng |
| 3 | Áo gile | Cái | 01 | 12 tháng |
| 4 | Giày BHLĐ | Đôi | 02 | 12 tháng |
| 5 | Áo mưa | Cái | 01 | 24 tháng |
| 6 | Ủng | Đôi | 01 | 12 tháng |
| 7 | Khẩu trang BHLĐ | Cái | 01 | 01 tháng |
| 8 | Găng tay | Đôi | 01 | 01 tháng |
| 9 | Kính BHLĐ | Cái | 01 | 12 tháng |
| 10 | Mặt nạ BHLĐ | Cái | 01 | 18 tháng |

**Trách nhiệm 3 bên**:
- **Phòng HCNS**: quản lý, theo dõi cấp phát, mở sổ theo dõi, kiểm kê tồn kho, báo cáo định kỳ.
- **Phòng Kế toán**: cập nhật số liệu xuất/nhập/tồn/đơn giá; thủ kho chỉ xuất theo phiếu của HCNS.
- **Người lao động**: sử dụng đúng mục đích, không cho người ngoài mượn, làm mất phải bồi thường.

**Bồi thường**:
- Mất trước niên hạn: bồi ≥ 50% giá trị.
- Nghỉ việc trước 6 tháng: hoàn 100%; sau 6 tháng: hoàn 50%.
- Hư hỏng: cá nhân chịu kinh phí.

### Quy chế đánh giá CBCNV

> **Nguồn**: `QUY TRÌNH/Quy chế đánh giá CBCNV.docx` — **file bị mã hóa OLE CDFV2, user chưa có bản unencrypted**.

---

## Phòng An Toàn (HSE)

> **Nguồn**: `QUY TRÌNH/QUY TRÌNH AN TOÀN LAO ĐỘNG.doc` — file chứa **sơ đồ Visio nhúng**. User sẽ cung cấp bản PDF/ảnh sau.

### Quy trình giám sát an toàn (suy ra từ text fragments)

- Kiểm tra hiện trạng mặt bằng thi công
- Lập kế hoạch trang bị phương tiện an toàn
- Giám sát quá trình lắp đặt
- Lập danh mục thiết bị, biển báo an toàn cần lắp đặt
- Lập kế hoạch đào tạo + tài liệu đào tạo
- Đánh giá đề phòng rủi ro
- Yêu cầu **dừng thi công** nếu không đảm bảo an toàn
- Đưa ra biện pháp khắc phục nếu có rủi ro

---

## Phòng Mua hàng / Cung ứng vật tư

> **Nguồn**: `QUY TRÌNH/QUY TRÌNH VẬT TƯ.doc` (Visio embed), 14 file Excel `Vật tư [KHU VỰC].xlsx`.

Suy ra từ fragments: quy trình có các bước yêu cầu vật tư → duyệt → đặt hàng → giao hàng → nghiệm thu. Mỗi dòng vật tư có **4 lần yêu cầu** (Lần 1-4).

File `HBG-MCR-MM-01.xlsx` (sheet `RFA-Submission_Delivery`, **1397 dòng × 178 cột**) — **file quan trọng**, là log quản lý Material Approval / RFA submission toàn dự án. Cần ingest trong MVP.

---

## Phòng Kế toán / Tài chính (Thanh toán A-B)

> **Nguồn**: file Excel `TIẾN ĐỘ THANH TOÁN A_B/HBG-MCR-MPM-01.1.xlsx`, sheet `TĐ - HSTT` (19 dòng × 16 cột).

Schema: Diễn giải / Hồ sơ thanh toán (Khối lượng/Giá trị/Duyệt/Chưa) / Hồ sơ chất lượng (Duyệt DM/Hoàn thành/Chưa) / Tình trạng chung.

---

## Phòng Kỹ thuật / Shop Drawing

> **Nguồn**: 14 file Excel `Shop [KHU VỰC].xlsx`.

### Cấu trúc file Shop (đại diện `Shop BOH.xlsx`)

**Cấu trúc 274 cột đã xác nhận** (sau khi đọc chi tiết):
- **C1-C11**: data chính (STT, Mã hiệu, Tên bản vẽ, %HT, Ngày dự kiến/thực tế trình, Phản hồi BQLDA Lần 1, Ghi chú)
- **C12-C32**: 5 lần phản hồi BQLDA, mỗi lần có cặp (Comment, Ngày) + ngày trình lại
- **C33**: Ngày phê duyệt (giá trị `True`/`False`)
- **C34+**: **Gantt template TRỐNG** (Tuần 1, 2, 3, 4, 5, mỗi tuần ~7 cột = 35 cột). Date header `1900-01-01` (ngày giả, không phải ngày thật) → user chưa điền Gantt.

**Quyết định MVP**: chỉ import C1-C33, bỏ qua Gantt template (làm sau nếu user thực sự cần).

### Danh sách 14 khu vực (zone)

| Mã | Tên (suy ra / user xác nhận) |
|---|---|
| BOH | Back of House |
| BPV | Beach Pool Villa |
| BSN | Business ? (chưa rõ) |
| BUT | Butler ? (chưa rõ) |
| BZONE | Zone B ? (chưa rõ) |
| CLU | Cluster Villa ? (chưa rõ) |
| GEN | General / Generator |
| HPV | ? (chưa rõ) |
| INF | Infrastructure |
| KID | Kid Club |
| LOB & SPA | Lobby & Spa |
| RES VILLAS | **Resort** (theo user) |
| VN RES | Vietnam Residences |

> User không rõ tên đầy đủ của nhiều zone — dùng mã làm primary key, tên để trống cho user tự điền sau.

---

## Phòng Thi công (Tiến độ thi công)

> **Nguồn**: 15 file Excel `TĐ [KHU VỰC].xlsx`.

### Cấu trúc file TĐ (đại diện `TĐ BOH.xlsx`)

- Header R2-R15 (bilingual).
- 53 cột (nhỏ hơn nhiều so với file Shop/Vật tư).
- Cấu trúc phân cấp A/I/II/III/1/2/3... → **DB sẽ tách `level_roman` + `level_arabic` (theo user)**.
- Mỗi dòng: STT, Công việc, % Hoàn thành, Tình trạng (YES/NO), 4 cột ngày (KH/TT × bắt đầu/kết thúc), Số ngày KH.

### Danh sách 15 file TĐ (khu vực)

| File | Ghi chú |
|---|---|
| `TĐ BOH.xlsx` | Back of House |
| `TĐ BPV -1 BR.xlsx`, `TĐ BPV-2 BR.xlsx` | Beach Pool Villa 1BR/2BR |
| `TĐ BSC.xlsx` | Business Center |
| `TĐ BULTER.xlsx` | Butler |
| `TĐ BZONE.xlsx` | Zone B |
| `TĐ CLUSTER VILLA.xlsx` | Cluster Villa |
| `TĐ FITNESS.xlsx` | Fitness Center |
| `TĐ HPV-1 BR.xlsx`, `TĐ HPV-2 BR.xlsx` | HPV 1BR/2BR |
| `TĐ Hạ Tầng.xlsx` | Hạ tầng / Infrastructure |
| `TĐ KID.xlsx` | Kid Club |
| `TĐ LOB-SPA.xlsx` | LOB-SPA |
| `TĐ RES -3 BR.xlsx`, `TĐ RES -4 BR.xlsx` | **Resort** 3BR/4BR |
| `TĐ VNR.xlsx` | Vietnam Residences |

---

## Ban Chỉ Huy Công Trường (BCH) — dự án LAWRENCE STING

> **Nguồn**: File lẻ `Báo cáo công việc C20 ngày 23.5.2021.xlsx`.

### Quy trình "Báo cáo công việc hằng ngày" (Daily Working Report)

- Mỗi ngày 1 file, mỗi file nhiều sheet, mỗi sheet = 1 ngày.
- File mẫu có 2 sheet `22.5.2021` và `23.5.2021`.
- 2 người lập khác nhau cho 2 sheet — **đây là thực tế, có thể do mỗi ngày 1 người role khác** (theo user).
- Chữ viết tắt `Đ.D BCH/CT` = **Đại diện ban chấp hành / chủ tịch** (theo user).

**Cấu trúc 5 sections** (xem chi tiết trong `data_inventory.md`):
1. **Hạng mục & Tiến độ** (ELECTRICAL × 12, MECHANICAL × 12)
2. **An toàn / Vật tư** (16 dòng template)
3. **Nghiệm thu VTTB + Lắt đặt / Nhân lực HBG** (3 cột: Lũy kế/Trong ngày/Cộng)
4. **Kiến nghị**
5. **Ký duyệt** (góc trên: người lập; góc dưới: chức danh)

### Giá trị enum đã xác nhận

- Cột "Tình trạng" giá trị `0` = **chưa cập nhật** (NULL tương đương, không phải fail).
- Cột rating NCC giá trị `P` = **có vẻ Pass/Present** (chưa chắc chắn, cần xem file gốc).
- STT bị khuyết (1-9, 11-16) → **renumber tự động** khi import.

---

## Tổng hợp câu trả lời 27 open questions

| # | Câu | Trả lời |
|---|---|---|
| 1 | BTE-WP4-HBC | BTE=Bãi Tràm, WP4=Work Package 4, HBC=HBG Construction |
| 2 | BCTT | Báo Cáo Tổng Thể |
| 3 | Multi-tenant | 1 tenant = 1 khách hàng (vd: `hbg` chứa nhiều dự án) |
| 4 | MEP vs Cơ | Cùng 1 gói thầu (MEP = Cơ điện) |
| 5 | 14 zone | Tên chưa rõ — dùng mã làm primary, tên để trống |
| 6 | Cấu trúc A/I/II/III/1/2/3 | Tách 2 cột: `level_roman` + `level_arabic` |
| 7 | Bilingual | Tách `name_vi` + `name_en` |
| 8 | Cột C41-C42 Daily Report | **Chưa rõ, nghi vấn đi cùng nhóm cột D/E/F/G** — cần xem file gốc |
| 9 | 26 file PDF | Cần OCR — làm sau MVP |
| 10 | Shop 274 cột | Chỉ import C1-C33, bỏ Gantt template |
| 11 | 1 dòng lỗi | Bỏ qua dòng đó, ghi log + báo cáo |
| 12 | Enum `0` Tình trạng | Chưa cập nhật (NULL tương đương) |
| 13 | Enum `P` rating | Có vẻ Pass/Present (chưa chắc) |
| 14 | STT khuyết | Renumber tự động |
| 15 | 2 người lập / 1 file | Thực tế, có thể khác role |
| 16 | `Đ.D BCH/CT` | Đại diện ban chấp hành / chủ tịch |
| 17 | "Cơ" = Cơ điện | Đúng |
| 18 | Số khách hàng | 3-7 bên (hiện tại) |
| 19 | Format mỗi khách | Tương tự (qua bên tôi) |
| 20 | 6 file Visio | Sẽ upload bản PDF/ảnh sau |
| 21 | File .docx mã hóa | Chưa có |
| 22 | RFA log 1397 dòng | **Có, khá quan trọng** — cần ingest trong MVP |
| 23 | Export format gốc | Làm được đến đâu thì làm |
| 24 | Số khách dự kiến | 5-10 |
| 25 | Multi-sheet khác loại | Không, dữ liệu cụ thể theo file |
| 26 | Config | Hardcode OK, cả 2 đều OK |
| 27 | Bước tiếp theo | **MVP demo chạy được trước, làm từ từ** |

## Đề xuất bước tiếp theo (theo câu 27)

**Mục tiêu MVP demo chạy được** — theo thứ tự ưu tiên:
1. **Schema Postgres** + migration đầu tiên (DDL) — dựa trên 27 câu trả lời.
2. **Backend API** (Node.js hoặc Python) với BetterAuth + RBAC cơ bản.
3. **Ingestion pipeline** cho **4 loại file ưu tiên**:
   - `quy trình thực hiện dự án.xlsx` (8 bước)
   - `Shop *.xlsx` (C1-C33)
   - `TĐ *.xlsx` (cấu trúc A/I/II/...)
   - `Daily Report C20` (49 cột)
4. **File `HBG-MCR-MM-01.xlsx`** (RFA log 1397×178) — quan trọng, làm sau 4 loại trên.
5. **Frontend web** (React + Vite) để upload file, xem data, dashboard.
6. **MinIO** (S3-compatible) để lưu file gốc.
7. **Docker Compose** local cho dev (theo DEPLOYMENT_STACK.md).
