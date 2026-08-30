# Data Inventory — Phân tích file dữ liệu thật

> Phân tích cho **từng file** `.xlsx/.xls/.csv` tìm được trong `reference_sheets/`. Khảo sát: 2026-08-29.
> Tổng cộng: **59 file Excel**. Cập nhật 2026-08-29 với câu trả lời 27 open questions.

## Tóm tắt theo dự án

| Dự án | Mã | Số file | Phân bố |
|---|---|---|---|
| **Bãi Tràm Estates** (Xuân Cảnh, Phú Yên) | **BTE-WP4-HBC** | 58 | Folder `2019.04.28 HBG-HBC-BCTT/` |
| **LAWRENCE STING SCHOOL 2** (block C20) | (HBG 2021) | 1 | File lẻ ngoài folder |

## Tóm tắt theo phòng ban / chức năng (dự án BTE)

| Nhóm | Số file | Mục đích |
|---|---|---|
| FILE START | 1 | File chỉ mục/sơ đồ cây (gần như trống) |
| QUY TRÌNH | 2 | `Quy trình thực hiện dự án.xlsx` + `Quy trình thuê thầu phụ, tổ đội.xlsx` |
| SƠ ĐỒ CÂY | 1 | `Tiến độ hạng mục.xlsx` (gần như trống) |
| TIẾN ĐỘ SHOP | 16 | 1 file tổng + 1 sơ đồ tổng thể + 14 file `Shop [KHU VỰC].xlsx` |
| TIẾN ĐỘ CUNG ỨNG VẬT TƯ | 17 | **1 file RFA log lớn (1397×178) + 1 tổng + 1 sơ đồ + 14 file `Vật tư [KHU VỰC].xlsx`** |
| TIẾN ĐỘ THANH TOÁN A_B | 3 | 1 file tổng + 1 sơ đồ + 1 file quản lý |
| TIẾN ĐỘ THI CÔNG | 18 | 1 file tổng + 1 sơ đồ + 1 sơ đồ tổng thể + 15 file `TĐ [KHU VỰC].xlsx` |
| TÀI NGUYÊN | 1 | `Danh sách nguồn lực công ty.xlsx` |
| DUYỆT KHÁC | 1 | `DUYỆT KHÁC.xlsx` |
| Vật tư duyệt (PDF) | 13 PDF | Bản vẽ duyệt vật tư |

---

## Phát hiện QUAN TRỌNG: Cấu trúc 274 cột trong file Shop

Sau khi đọc chi tiết `Shop BOH.xlsx`:

```
C1-C11:    Data chính (STT, Mã hiệu, Tên, %HT, Ngày dự kiến/thực tế trình, Phản hồi BQLDA Lần 1, Ghi chú)
C12-C32:   5 lần phản hồi BQLDA (mỗi lần: Comment + Ngày), ngày trình lại, ngày phê duyệt
C33:       Ngày phê duyệt (giá trị True/False)
C34-C68:   Gantt Tuần 1-5 (mỗi tuần ~7 cột = 35 cột) — TRỐNG data, date header = 1900-01-XX (ngày giả)
C64:       Ghi chú (cuối)
```

→ **Quyết định MVP**: chỉ import C1-C33, bỏ Gantt template trống (theo user).

---

## File #1-2: `FILE START.xlsx` & `SƠ ĐỒ CÂY/Tiến độ hạng mục.xlsx`

| Thuộc tính | FILE START | Tiến độ hạng mục |
|---|---|---|
| Sheet | `SƠ ĐỒ CÂY` (69×22) | `TĐHM` (27×21) |
| Nội dung | **Gần như trống** | **Gần như trống** |
| Kết luận | Template skeleton chưa điền → **bỏ qua** | |

---

## File #3-4: QUY TRÌNH (2 file Excel)

### `quy trình thực hiện dự án.xlsx` — **ƯU TIÊN 1 cho MVP**

| Thuộc tính | Giá trị |
|---|---|
| Sheet | `Quy trình thực hiện dự án` (32×14) |
| Header | R7 (tiêu đề) + R8 (header cột) |
| Cột | C8=STT, C9=Tiến trình, C10=Nội dung, C11=Thực hiện, C12=Kiểm tra/Phê duyệt |
| Số bước | 8 (xem chi tiết ở `business_process_summary.md`) |
| **Quyết định schema** | Bảng `business_process_steps` với `name_vi` + `name_en` (tách theo user), business key `(tenant_id, process_code, ordinal)` |

### `Quy trình thuê thầu phụ, tổ đội.xlsx` — **ƯU TIÊN 2**

| Thuộc tính | Sheet 1: `Danh mục theo dõi` | Sheet 2: `THÔNG TIN TPTĐ` |
|---|---|---|
| Kích thước | 31×19 | 36×15 |
| Header | R6 (tiêu đề) + R7-R8 (dự án, địa điểm) | R8 (tiêu đề) + R11-R12 (dự án) |
| Header cột | R10 (STT/Nội dung/Đơn vị tổ đội/Đơn vị thầu phụ) | R14 (STT/Họ tên/SĐT/Hạng mục) |
| Dữ liệu | Ma trận 6 tổ đội × 4+ công ty TP | 9 thầu phụ × 12 cột thuộc tính |
| Cấu trúc | 6 tổ đội (TỔ ĐỘI 1-6) × 4 công ty TP (A-D) | 6 hạng mục: Điện/Nước/ĐH/Xử nước thải/Xử nước cấp/Nước đóng chai |
| **Vấn đề** | Ô chứa tên người ("A. VƯƠNG") | Cột Hạng mục giá trị "P" (chưa rõ enum) |
| **Schema** | Bảng `task_assignments` | Bảng `subcontractors` + `subcontractor_capabilities` |

---

## File #5: `TÀI NGUYÊN/Danh sách nguồn lực công ty.xlsx`

| Sheet | Kích thước | Nội dung |
|---|---|---|
| `SƠ ĐỒ` | 1×1 | File tham chiếu lỗi → **bỏ qua** |
| `DS TP. TĐ` | 24×14 | DS thầu phụ/tổ đội: STT, Tên, Hệ thống, Hạng mục, Dự án đã làm, Năng lực (Tốt/Khá/TB), SĐT, Tình trạng |
| `DS NHÀ CUNG CẤP` | 27×19 | DS nhà cung cấp: STT, Tên NCC, Hệ thống, Hạng mục, Dự án, Giá (Cao/TB/Thấp), Chất lượng (Đạt/Không đạt), Dịch vụ BH |

**Vấn đề**: nhiều dự án khác (Melia Cam Ranh) xuất hiện → bảng tổng hợp nhiều dự án.

---

## File #6: `DUYỆT KHÁC/DUYỆT KHÁC.xlsx`

Cùng schema với Shop nhưng là "OTH = Other approvals". Header giống `Shop BOH.xlsx`.

---

## File #7-20: TIẾN ĐỘ SHOP (14 file `Shop [KHU VỰC].xlsx` + 2 file tổng) — **ƯU TIÊN 3 cho MVP**

### Schema chung (C1-C33 sẽ ingest, C34+ bỏ qua Gantt template)

| Cột | Header (R23) | Kiểu | Ghi chú |
|---|---|---|---|
| C1 | STT | int | Số thứ tự |
| C2-C5 | (header phụ) | - | Có thể trống |
| C6 | Mã hiệu | string | vd "BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-001" |
| C7 | Tên bản vẽ | string | |
| C8 | % HT | float | 0-100 |
| C9 | Ngày dự kiến trình | date | |
| C10 | Ngày thực tế trình | date | |
| C11 | (trống) | - | |
| C12 | Phản hồi BQLDA Lần 1 | string | "R" (Rejected?) hoặc "A" (Approved?) |
| C13 | Ngày Lần 1 | date | |
| C14-C15 | Comment + Ngày Lần 2 | string + date | |
| ... | ... | ... | đến Lần 5 |
| C22-C32 | Ngày dự kiến/ngày trình lại | date | |
| C33 | Ngày phê duyệt | bool | True/False |

**14 khu vực**: BOH, BPV, BSN, BUT, BZONE, CLU, GEN, HPV, INF, KID, LOB&SPA, RES VILLAS, VN RES.

**Schema đề xuất**:
- Bảng `shop_drawings`: `(project_id, zone_id, drawing_code, name_vi, name_en, progress_pct, planned_submit_date, actual_submit_date, bql_l1_response, bql_l1_date, ..., bql_l5_*, resubmit_dates, approval_date)`

---

## File #21-37: TIẾN ĐỘ CUNG ỨNG VẬT TƯ (14 file + 3 file tổng) — **ƯU TIÊN 4**

### Schema 14 file Vật tư (giống Shop)

- Cột: STT, Mã Hiệu, Tên vật tư, % HT, Ngày yêu cầu Lần 1-4.
- 14 khu vực giống Shop.

### File quan trọng: `HBG-MCR-MM-01.xlsx`

| Thuộc tính | Giá trị |
|---|---|
| Sheet | `RFA-Submission_Delivery` |
| Kích thước | **1397 dòng × 178 cột** (lớn nhất) |
| Nội dung | **Log toàn bộ Material Approval / RFA submission** của dự án |
| Xử lý | Dùng `openpyxl read_only=True` + chunk processing. **ƯU TIÊN ingest trong MVP** (theo user) |

---

## File #38-52: TIẾN ĐỘ THI CÔNG (15 file TĐ + 3 tổng) — **ƯU TIÊN 5 cho MVP**

### Schema `TĐ BOH.xlsx` (đại diện)

| Cột | Header (R14) | Kiểu |
|---|---|---|
| C4 | Stt/No | string (A, I, II, 1, 2, 3) |
| C5 | Công việc thi công | string (bilingual) |
| C6 | % Hoàn thành | float 0-1 |
| C7 | Tình trạng | enum (YES/NO) |
| C8 | Ngày bắt đầu KH | date |
| C9 | Ngày bắt đầu TT | date |
| C10 | Ngày kết thúc KH | date |
| C11 | Ngày kết thúc TT | date |
| C12 | Số ngày KH | int |

**Quyết định user**: tách `level_roman` + `level_arabic` thành 2 cột riêng.

**Schema đề xuất**:
- Bảng `construction_schedule_items` với fields: `(project_id, zone_id, level_roman, level_arabic, ordinal, name_vi, name_en, progress_pct, status, plan_start_date, actual_start_date, plan_end_date, actual_end_date, plan_duration_days)`

---

## File #53-55: TIẾN ĐỘ THANH TOÁN A_B (3 file)

| File | Sheet | Mô tả |
|---|---|---|
| `HBG-MCR-MPM-01.1.xlsx` | `TĐ - HSTT` (19×16) | Bảng báo cáo tiến độ hồ sơ thanh toán |
| `Tiến độ thanh toán các khu vực.xlsx` | `TĐ TỔNG` (104×39) | Tổng hợp thanh toán các khu vực |

---

## File #58: `Báo cáo công việc C20 ngày 23.5.2021.xlsx` (dự án LAWRENCE STING) — **ƯU TIÊN 6 cho MVP**

### Thông tin nhận diện

| Trường | Giá trị |
|---|---|
| Bộ phận | `BAN CHỈ HUY CÔNG TRƯỜNG` |
| Dự án | `LAWRENCE STING SCHOOL 2` |
| Job No. | `MEP` |
| Block | `C20` |
| Sheet | `22.5.2021`, `23.5.2021` (112×49) |

### Quyết định từ câu trả lời

- `Đ.D BCH/CT` = **Đại diện ban chấp hành / chủ tịch**
- Cột "Tình trạng" giá trị `0` = **chưa cập nhật** (NULL tương đương)
- Cột C41-C42 (tỉ lệ 0.7→1.0 không có header) = **chưa rõ, nghi vấn đi cùng nhóm cột D/E/F/G** — để TODO, không map trong MVP
- 2 người lập khác nhau (Nguyễn Văn Định vs Nguyễn Xuân Thắng) = **thực tế, mỗi ngày 1 role**
- STT khuyết → **renumber tự động** khi import

---

## Vấn đề chung cho tất cả 59 file Excel

| # | Vấn đề | Mức độ | Xử lý |
|---|---|---|---|
| 1 | **Header nằm ở row 12-25** | Cao | Schema-detection layer |
| 2 | **Sheet name có dấu + khoảng trắng thừa** | Trung bình | `.strip()` + normalize |
| 3 | **Sheet name lẫn lộn ký tự** (vd `LOB+SPA` ≠ `LOB & SPA`) | Trung bình | Lookup table map |
| 4 | **274 cột trong file Shop/Vật tư** | Cao | **MVP: chỉ import C1-C33, bỏ Gantt** |
| 5 | **Mỗi file dùng 1 sheet** | Trung bình | Skip Sheet1(1×1) rỗng |
| 6 | **Bilingual header** | Trung bình | Tách `name_vi` + `name_en` |
| 7 | **Header công ty/dự án chỉ ở row 14-18** | Cao | Propagate xuống mỗi dòng |
| 8 | **File lớn (1397×178)** | Trung bình | `openpyxl read_only=True` |
| 9 | **File CDFV2 encrypted** | Thấp | Bỏ qua (user chưa có bản unencrypted) |
| 10 | **Sheet "SƠ ĐỒ" 1×1 tham chiếu lỗi** | Thấp | Bỏ qua |
| 11 | **Conditional formatting mất** | Thấp | Chấp nhận |
| 12 | **Một số file có Sheet1(1×1) rỗng** | Thấp | Bỏ qua |

### Xử lý lỗi (theo user)

- **1 dòng lỗi** → **Bỏ qua dòng đó, ghi log chi tiết, tiếp tục**.
- **>20% dòng lỗi** → Dừng import, báo user.

### Xử lý cell đặc biệt

| Vấn đề | Xử lý |
|---|---|
| `#N/A`, `#REF!` | Convert → `NULL` |
| `""` (chuỗi rỗng) | Convert → `NULL` |
| `datetime` (vd `2019-09-04 00:00:00`) | Convert → `date` |
| Số thập phân `0,7` (dấu phẩy) | Convert → `0.7` |
| STT khuyết (1-9, 11-16) | **Renumber tự động** |
| `0` trong cột Tình trạng (Daily Report) | **NULL** (chưa cập nhật) |
| `P` trong cột rating (NCC) | `PASS` (giả định, sẽ confirm sau) |
| `YES`/`NO` trong cột Tình trạng (TĐ) | `DONE`/`PENDING` |
| Sheet name có khoảng trắng thừa | `.strip()` + normalize |
| Sheet name có ký tự đặc biệt | Map theo lookup table |

---

## Schema đề xuất tổng hợp (sẽ viết DDL chính thức ở bước tiếp theo)

### 1. Bảng `tenants`
- `id`, `code`, `name`, `created_at`

### 2. Bảng `projects`
- `id`, `tenant_id` FK, `code` (vd "BTE-WP4-HBC"), `name_vi`, `name_en`, `package` ("MEP"), `rev_prefix`, `created_at`
- Business key: `(tenant_id, code)`

### 3. Bảng `zones`
- `id`, `project_id` FK, `code` ("BOH", "BPV", ...), `name_vi`, `name_en` (nullable), `is_br_split` (bool, cho BPV-1BR/2BR)
- Business key: `(project_id, code)`

### 4. Bảng `business_process_steps`
- `id`, `tenant_id` FK, `process_code`, `ordinal`, `name_vi`, `content_vi`, `responsibility_vi`, `verification_vi`
- Business key: `(tenant_id, process_code, ordinal)`

### 5. Bảng `subcontractors`
- `id`, `tenant_id` FK, `name`, `phone`, `email`, `capability_summary`, `status` (enum: ACTIVE/INACTIVE)
- Business key: `(tenant_id, name)`

### 6. Bảng `subcontractor_capabilities`
- `id`, `subcontractor_id` FK, `capability_code` (ELECTRICAL/PLUMBING/HVAC/...), `level` (GOOD/FAIR/POOR)
- Business key: `(subcontractor_id, capability_code)`

### 7. Bảng `suppliers`
- `id`, `tenant_id` FK, `name`, `system`, `category`, `past_projects`, `location`, `price_rating`, `quality_rating`, `warranty_rating`
- Business key: `(tenant_id, name)`

### 8. Bảng `task_assignments`
- `id`, `project_id` FK, `system_code` (I/II/III), `subtask_code` (1.1, 1.2, ...), `team_id` (FK subcontractors), `subcontractor_id` (FK subcontractors), `assignee_name`
- Business key: `(project_id, system_code, subtask_code, team_id, subcontractor_id)`

### 9. Bảng `shop_drawings`
- `id`, `project_id` FK, `zone_id` FK, `drawing_code`, `name_vi`, `name_en` (tách bilingual), `progress_pct`, `planned_submit_date`, `actual_submit_date`, `bql_l1_response`, `bql_l1_date`, `bql_l1_comment`, ..., `bql_l5_*`, `resubmit_planned_dates[]`, `resubmit_actual_dates[]`, `approval_date` (bool)
- Business key: `(project_id, zone_id, drawing_code)`

### 10. Bảng `materials`
- `id`, `project_id` FK, `zone_id` FK, `material_code`, `name_vi`, `name_en`, `progress_pct`, `request_date_1..4`
- Business key: `(project_id, zone_id, material_code)`

### 11. Bảng `construction_schedule_items`
- `id`, `project_id` FK, `zone_id` FK, `level_roman`, `level_arabic`, `ordinal`, `name_vi`, `name_en` (tách bilingual), `progress_pct`, `status` (enum: DONE/PENDING), `plan_start_date`, `actual_start_date`, `plan_end_date`, `actual_end_date`, `plan_duration_days`
- Business key: `(project_id, zone_id, level_roman, level_arabic, ordinal, name_vi)`

### 12. Bảng `rfa_log_entries` (từ file `HBG-MCR-MM-01.xlsx`)
- `id`, `project_id` FK, `material_id` FK (nullable), `rfa_code`, `rfa_type` (MAA/SHD/RFA/...), `submission_date`, `approval_date`, `status`, `raw_data` (JSONB), `created_at`
- Business key: `(project_id, rfa_code)` — cần verify sau khi đọc chi tiết file

### 13. Bảng `payment_milestones`
- `id`, `project_id` FK, `milestone_code`, `name_vi`, `progress_volume`, `progress_value_vnd`, `approval_status` (APPROVED/PENDING/...), `quality_docs_status`, `overall_status`
- Business key: `(project_id, milestone_code)`

### 14. Bảng `daily_reports`
- `id`, `project_id` FK, `report_date`, `prepared_by`, `approver_role` ("Đại diện ban chấp hành/chủ tịch")
- Business key: `(project_id, report_date)`

### 15. Các bảng con cho Daily Report
- `daily_work_items` (hạng mục + vướng mắc + tiến độ)
- `daily_material_status` (vật tư trên công trường)
- `daily_manpower` (14 vai trò × 3 cột Lũy kế/Trong ngày/Cộng)
- `daily_acceptance` (nghiệm thu)
- `daily_safety_observations`
- `daily_recommendations`

### 16. Bảng `file_uploads` (audit log)
- `id`, `tenant_id` FK, `project_id` FK, `original_filename`, `minio_key`, `content_hash`, `expected_doc_type`, `uploader_user_id`, `status` (UPLOADED/PROCESSING/SUCCESS/PARTIAL/FAILED), `report_json`, `created_at`

### 17. Bảng `column_mappings` (config per tenant)
- `id`, `tenant_id` FK, `source_doc_type`, `raw_header_vi`, `raw_header_en`, `system_field`, `data_type`, `is_required`, `is_user_confirmed`
- Business key: `(tenant_id, source_doc_type, raw_header_vi)`

### 18. Bảng `users` (BetterAuth)
- Theo schema BetterAuth mặc định + RBAC roles.

### 19. Bảng `source_files` (file gốc trong MinIO, separate from uploads)
- `id`, `minio_key`, `bucket`, `content_hash`, `size_bytes`, `uploaded_at`, `original_filename`

---

## Tại sao KHÔNG nên hardcode tên cột

Đã xác nhận với user: **Hardcode OK cho MVP**, nhưng cả 2 cách (hardcode + config per-tenant) đều OK. Mình sẽ:
- MVP: hardcode mapping cho 4 loại file ưu tiên (Quy trình, Shop, TĐ, Daily Report).
- Sau MVP: cho phép admin customize qua UI, lưu vào bảng `column_mappings`.
