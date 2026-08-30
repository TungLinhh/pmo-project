# Import / Export Plan

> Kế hoạch chi tiết cho 2 luồng:
> - **Import**: từ file Excel (và PDF) của khách hàng → Postgres
> - **Export**: từ Postgres → lại file Excel đúng format khách hàng đang dùng
>
> Cập nhật 2026-08-29 với câu trả lời 27 open questions.

---

## 1. Tổng quan kiến trúc

```
┌──────────────┐    ┌───────────────┐    ┌──────────────┐    ┌──────────────┐
│ File Excel/  │ →  │ Schema detect │ →  │  Validator   │ →  │   Postgres   │
│ PDF (MinIO)  │    │ + column map  │    │  + báo lỗi   │    │   (upsert)   │
└──────────────┘    └───────────────┘    └──────────────┘    └──────────────┘
                          ↑
                          │ MVP: hardcode cho 4 loại file
                          │ Sau MVP: config per-tenant

┌──────────────┐    ┌───────────────┐    ┌──────────────┐
│   Postgres   │ →  │  Template     │ →  │ File Excel   │
│              │    │  engine       │    │ (cho KH)     │
└──────────────┘    └───────────────┘    └──────────────┘
```

**Nguyên tắc tối thượng** (từ `DEPLOYMENT_STACK.md`):
- **Idempotent** (chạy lại cùng file → không duplicate).
- **Lưu file gốc vào MinIO** để audit/trace.
- **Không hardcode business rule** — config-driven.
- **Migration-first** — mọi thay đổi schema qua migration.

---

## 2. MVP Scope (theo user câu 27)

**Mục tiêu**: MVP demo chạy được.

### 2.1. Ưu tiên ingest theo thứ tự

| # | Loại file | File đại diện | Số file | Mức quan trọng |
|---|---|---|---|---|
| 1 | Quy trình thực hiện dự án | `quy trình thực hiện dự án.xlsx` | 1 | Cao |
| 2 | Quy trình thuê thầu phụ | `Quy trình thuê thầu phụ, tổ đội.xlsx` | 1 | Cao |
| 3 | Shop Drawing | `Shop [KHU VỰC].xlsx` | 14 | Cao |
| 4 | Tiến độ thi công | `TĐ [KHU VỰC].xlsx` | 15 | Cao |
| 5 | Daily Report | `Báo cáo công việc C20 ngày 23.5.2021.xlsx` | 1 | Cao |
| 6 | **RFA log** | `HBG-MCR-MM-01.xlsx` (1397×178) | 1 | **Cao (user)** |
| 7 | Tài nguyên (DS NCC, DS thầu phụ) | `Danh sách nguồn lực công ty.xlsx` | 1 | Trung bình |
| 8 | Vật tư khu vực | `Vật tư [KHU VỰC].xlsx` | 14 | Trung bình |
| 9 | Thanh toán A_B | `HBG-MCR-MPM-01.1.xlsx` | 1 | Trung bình |
| 10 | Duyệt khác | `DUYỆT KHÁC.xlsx` | 1 | Thấp |

**MVP scope**: items 1-6 (6 loại file đầu, ~33 file). Items 7-10 có thể làm sau.

### 2.2. 4 loại file ưu tiên cho MVP (theo user câu 27)

User nói "làm hết từ từ, quan trọng MVP demo chạy được" → mình sẽ:
- **MVP core**: 4 loại (Quy trình, Shop, TĐ, Daily Report) — đủ để demo 1 quy trình từ đầu đến cuối.
- **Phase 2**: RFA log (1397×178) — quan trọng nhưng phức tạp.
- **Phase 3**: Tài nguyên, Vật tư, Thanh toán, Duyệt khác.

---

## 3. Plan cho IMPORT (Excel/PDF → Postgres)

### 3.1. Bước 1 — Upload & lưu MinIO

- User upload file qua API.
- Lưu vào bucket `pmo-originals` trong MinIO:
  - Key: `tenant/{tenant_id}/source/{yyyy}/{mm}/{uuid}.{ext}`
- Metadata: tên file gốc, người upload, content hash (SHA256), `project_id`, `expected_doc_type`.

### 3.2. Bước 2 — Schema detection (MVP: hardcode cho 4 loại)

| Doc type | Detection logic |
|---|---|
| `business_process` | Sheet name = "Quy trình thực hiện dự án" (hoặc match với catalog) |
| `subcontractor_directory` | Sheet name chứa "thầu phụ" + "tổ đội" |
| `shop_drawing` | Sheet name starts with "SHOP " |
| `material_supply` | Sheet name starts with "VẬT TƯ" |
| `construction_schedule` | Sheet name starts with "TĐ " |
| `daily_report` | Sheet name parse được thành date `dd.mm.yyyy` |
| `rfa_log` | Sheet name = "RFA-Submission_Delivery" |
| `resource_directory` | Sheet name = "DS TP. TĐ" hoặc "DS NHÀ CUNG CẤP" |
| `payment_progress` | Sheet name contains "HSTT" hoặc "thanh toán" |
| `other_approved` | Sheet name = "SHOP OTH" |

### 3.3. Bước 3 — Column mapping (MVP: hardcode)

**Bảng `column_mappings`** sẽ được seed với mapping mặc định cho mỗi `source_doc_type`. Admin có thể edit sau qua UI.

**Mapping cứng cho 4 loại ưu tiên** (xem chi tiết ở `data_inventory.md`):

#### `business_process`
- C8: ordinal → `ordinal`
- C9: name (Tiến trình) → `name_vi`
- C10: content (Nội dung) → `content_vi`
- C11: responsibility → `responsibility_vi`
- C12: verification → `verification_vi`

#### `shop_drawing`
- C1: STT
- C6: Mã hiệu → `drawing_code`
- C7: Tên bản vẽ → `name_vi`
- C8: %HT → `progress_pct`
- C9: Ngày dự kiến trình → `planned_submit_date`
- C10: Ngày thực tế trình → `actual_submit_date`
- C12: Phản hồi L1 → `bql_l1_response`
- C13: Ngày L1 → `bql_l1_date`
- C14-C15: L2
- C16-C17: L3
- C18-C19: L4
- C20-C21: L5
- C22, C26, C30: Ngày trình lại → `resubmit_planned_dates[]`
- C33: Ngày phê duyệt → `approval_date`

#### `construction_schedule`
- C4: STT → parse thành `level_roman` + `level_arabic` (vd "A" → ("A", NULL), "1" → (NULL, 1), "1.1" → (NULL, 1) với `sublevel=1`)
- C5: Công việc thi công → `name_vi`
- C6: % Hoàn thành → `progress_pct`
- C7: Tình trạng (YES/NO) → `status` (DONE/PENDING)
- C8: Ngày bắt đầu KH → `plan_start_date`
- C9: Ngày bắt đầu TT → `actual_start_date`
- C10: Ngày kết thúc KH → `plan_end_date`
- C11: Ngày kết thúc TT → `actual_end_date`
- C12: Số ngày KH → `plan_duration_days`

#### `daily_report`
- Sheet name = ngày → `report_date`
- R2 C25: Tên người lập → `prepared_by`
- R84 C21: `Đ.D BCH/CT` → `approver_role` ("Đại diện ban chấp hành/chủ tịch")
- Section I (R30-R37): work items
- Section II (R43-R57): vật tư
- Section III (R64-R82): nhân lực (14 vai trò × 3 cột)
- **Bỏ qua C41-C42** (chưa rõ, TODO)

### 3.4. Bước 4 — Normalize & Validate

| Vấn đề | Xử lý |
|---|---|
| `#N/A`, `#REF!` | → `NULL` |
| `""` | → `NULL` |
| `datetime` (`2019-09-04 00:00:00`) | → `date` |
| Chuỗi ngày (`"23/05/2021"`) | Parse `dd/mm/yyyy` |
| `0,7` | → `0.7` |
| STT khuyết | **Renumber tự động** |
| Sheet name có khoảng trắng thừa | `.strip()` |
| Sheet name ký tự đặc biệt | Lookup table |
| Cell merged | Lấy top-left value |
| `0` trong Tình trạng (Daily Report) | → `NULL` (chưa cập nhật) |
| `P` trong rating NCC | → `PASS` (TODO: confirm) |
| `YES`/`NO` (TĐ) | → `DONE`/`PENDING` |
| File lớn (1397×178) | `read_only=True` + chunk |

**Sau normalize**, validator kiểm tra:
- Required fields không NULL
- Kiểu dữ liệu đúng
- Foreign key tồn tại

**Hành vi lỗi (theo user)**:
- 1 dòng lỗi → **Bỏ qua dòng đó, ghi log, tiếp tục**
- >20% dòng lỗi → Dừng import
- Output: báo cáo JSON + CSV dòng lỗi

### 3.5. Bước 5 — Idempotent upsert

Dùng PostgreSQL `INSERT ... ON CONFLICT (business_key) DO UPDATE SET ...`. Business key đã liệt kê ở `data_inventory.md`.

### 3.6. Thứ tự import

1. `tenants`
2. `projects`
3. `zones`
4. `subcontractors`, `suppliers`
5. `business_process_steps`
6. `task_assignments`
7. `shop_drawings`
8. `construction_schedule_items`
9. `daily_reports` + các bảng con
10. `rfa_log_entries`
11. `materials`
12. `payment_milestones`

### 3.7. PDF (làm sau MVP)

- 26 file PDF lưu vào MinIO + metadata vào DB.
- **OCR sau MVP** (theo user).
- Trước mắt: chỉ trích metadata từ tên file (mã, rev).

---

## 4. Plan cho EXPORT (Postgres → Excel)

### 4.1. Mục tiêu (theo user câu 23)

> "Làm được đến đâu thì làm"

- **MVP**: Export file Excel **đơn giản** (dữ liệu dạng bảng, không cần giống format gốc 100%).
- **Phase 2**: Export giống format gốc (giữ template MinIO + điền data, dùng openpyxl).

### 4.2. MVP Export (đơn giản)

- Dùng `openpyxl` tạo file mới từ data DB.
- Format: 1 sheet = 1 bảng, header bold, freeze row đầu.
- File name: `{table_name}_{tenant_code}_{date}.xlsx`

### 4.3. Phase 2 Export (giống format gốc)

- Lưu template gốc vào MinIO bucket `pmo-templates`.
- Khi export: copy template → điền data vào ô tương ứng theo `excel_export_mappings`.
- Rủi ro: openpyxl có thể mất chart/conditional formatting → cần test từng template.

---

## 5. Kiến trúc MVP (theo `DEPLOYMENT_STACK.md`)

### 5.1. Stack

- **Backend**: Node.js (TypeScript) + Fastify + Prisma + BetterAuth
- **Frontend**: React + Vite + TypeScript
- **Database**: PostgreSQL 16 (Docker)
- **Storage**: MinIO (Docker, S3-compatible)
- **Auth**: BetterAuth với RBAC + organization plugin
- **Dev**: Docker Compose

### 5.2. Cấu trúc thư mục MVP

```
pmo_project/
├── backend/                    # Node.js API
│   ├── src/
│   │   ├── routes/             # API endpoints
│   │   ├── services/           # Business logic
│   │   │   ├── ingest/         # Ingestion pipeline cho từng doc_type
│   │   │   │   ├── business_process.ts
│   │   │   │   ├── shop_drawing.ts
│   │   │   │   ├── construction_schedule.ts
│   │   │   │   ├── daily_report.ts
│   │   │   │   └── rfa_log.ts
│   │   │   ├── export/
│   │   │   └── storage/        # MinIO client
│   │   ├── lib/
│   │   │   ├── excel/          # Excel parser, normalize, validate
│   │   │   ├── db/             # Prisma client
│   │   │   └── auth/           # BetterAuth setup
│   │   └── index.ts
│   ├── prisma/
│   │   ├── schema.prisma       # DB schema
│   │   └── migrations/
│   ├── tests/                  # TDD: test với file reference
│   ├── package.json
│   └── tsconfig.json
├── frontend/                   # React app
│   ├── src/
│   │   ├── pages/
│   │   │   ├── Upload.tsx      # Upload file
│   │   │   ├── Dashboard.tsx   # Xem data
│   │   │   └── Login.tsx
│   │   ├── components/
│   │   ├── api/                # API client
│   │   └── App.tsx
│   ├── package.json
│   └── vite.config.ts
├── docker-compose.yml          # postgres, minio, app
├── .env.example
├── docs/                       # docs đã có
│   ├── business_process_summary.md
│   ├── data_inventory.md
│   └── import_export_plan.md
└── reference_sheets/           # data thật (đã copy)
```

### 5.3. Lộ trình MVP (theo thứ tự ưu tiên)

| # | Task | Ưu tiên | Ghi chú |
|---|---|---|---|
| 1 | Docker Compose (postgres + minio) | P0 | `DEPLOYMENT_STACK.md` đã chốt |
| 2 | Prisma schema (DDL) | P0 | Dựa trên 19 bảng ở `data_inventory.md` |
| 3 | Migration đầu tiên | P0 | Tạo tables + seed mapping |
| 4 | Backend skeleton (Fastify + BetterAuth) | P0 | |
| 5 | Endpoint POST /api/upload (MinIO) | P0 | Lưu file gốc, hash, metadata |
| 6 | Excel parser core (openpyxl wrapper cho Node) | P0 | Dùng `xlsx` (SheetJS) hoặc `exceljs` |
| 7 | Ingestion cho 4 loại (Quy trình, Shop, TĐ, Daily Report) | P0 | MVP demo |
| 8 | Ingestion cho RFA log (1397×178) | P1 | Stream read |
| 9 | Frontend upload page | P1 | React + Vite |
| 10 | Frontend dashboard (xem data) | P1 | Hiển thị 1 bảng bất kỳ |
| 11 | Frontend login + RBAC | P1 | BetterAuth |
| 12 | Export Excel đơn giản | P2 | Phase 2 |
| 13 | Export giống format gốc | P2 | Phase 2 |
| 14 | OCR PDF | P3 | Sau MVP |

---

## 6. Open questions còn lại (không critical cho MVP)

| # | Câu | Status |
|---|---|---|
| 8 | Cột C41-C42 Daily Report | TODO: cần xem file gốc hoặc bỏ qua |
| 13 | Enum `P` rating NCC | TODO: confirm với user khi gặp data |
| 20 | 6 file Visio | User sẽ upload PDF/ảnh sau |
| 21 | File .docx mã hóa | Chưa có |

Các câu này **không block MVP**. Sẽ xử lý khi gặp trong quá trình code.

---

## 7. Đề xuất bước tiếp theo CỤ THỂ

Theo user câu 27 "làm hết từ từ, quan trọng MVP demo chạy được":

**Bước tiếp theo ngay bây giờ**: bạn muốn mình bắt đầu với phần nào?

1. **Setup Docker Compose + Prisma schema** (DDL) — foundation cho cả MVP
2. **Backend skeleton + 1 endpoint upload** — test được upload file
3. **Code ingestion cho Daily Report C20 trước** (49 cột, schema rõ nhất) — demo nhanh 1 flow
4. **Khác** — bạn chỉ định

Mình recommend **option 1** (setup foundation) vì:
- Docker Compose + Prisma schema cần làm trước để có DB local
- Sau đó mới code ingestion
- Lệch hướng nếu bắt đầu code mà chưa có schema

Sau khi bạn chọn, mình sẽ bắt tay ngay.
