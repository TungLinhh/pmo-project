# PMO MVP — Demo Script (30 phút cho stakeholder)

> **Mục đích**: Demo end-to-end ingestion-to-extraction-to-visualization pipeline: Excel upload → parse → DB → 4-pillar dashboard → L1-L5 shop approval → payment chain → daily report → OTD KPI → audit log.
>
> **Stack chính**: Login → Upload Wizard (ingestion) → Control Center (visualization) → Shop Drawing L1-L5 → Material Submittal TVGS → Payment 4-step → Daily Report + Photo → OTD KPI → Audit Log.
>
> **Yêu cầu trước khi demo**:
> - Backend + Postgres đang chạy (`curl http://localhost:3000/api/health` trả 200)
> - Browser sẵn sàng tại `http://localhost:3000` (prod build) hoặc `http://localhost:5173` (dev)
> - Có 11 file Excel mẫu tại `backend/data/test-fixtures/TEST-MASTER-01/` (Shop TST-A, TĐ TST-B, Vật tư TST-C, ...)
> - Có 1 file PDF để demo OCR (nếu có)
>
> **Thời gian**: 30 phút + 5 phút Q&A



## Phân bổ thời gian (30 phút)

| Phần | Thời gian | Người trình bày | Người xem chính |
|------|-----------|------------------|------------------|
| 0. Setup + Ingestion (Excel upload wizard) | 3 phút | PMO | All |
| 1. Control Center (4-pillar dashboard) | 5 phút | PMO | CEO, PM |
| 2. Shop Drawing + L1-L5 Approval | 6 phút | PMO | CEO, PM, BQL |
| 3. Material Submittal + TVGS | 5 phút | PMO | Procurement |
| 4. Payment 4-step chain | 5 phút | PMO | CEO, Accounting |
| 5. Daily Report + Photo Upload | 3 phút | Site lead | PM, CEO |
| 6. OTD KPI + Audit Log | 3 phút | PMO | CEO |
| Q&A | 5 phút | All | All |



## Phần 0 — Setup + Ingestion (Excel Upload Wizard) (3 phút)

**Mục tiêu**: Show ingestion pipeline: upload Excel → parse → detect doc_type → preview → commit → report.

### 0.1. Chuẩn bị

```bash
# Generate 11 Excel test files (idempotent)
cd backend
node scripts/generate-test-excel.mjs
# → 11 files + manifest.json at data/test-fixtures/TEST-MASTER-01/
```

**Nói**:
> "Hệ thống hỗ trợ 11 loại file Excel: Shop Drawing, Construction Schedule, Material Supply, Subcontractors, Suppliers, Daily Report, RFA Log, Business Process, File Start, và 2 file error (zone-not-found, empty)."

### 0.2. Upload 1 file (Shop TST-A.xlsx)

- Sidebar → "Upload" hoặc navigate `/upload`
- Click "Choose File" → chọn `Shop TST-A.xlsx`
- Click "Upload"
- → Returns `{ upload_id, status: "SUCCESS", total_rows: 50, ok_rows: 50, error_rows: 0 }`

**Nói**:
> "Wizard 5 bước: upload → analyze → map → commit → report. Parse 50 rows × 33 columns tự động, detect doc_type = SHOP, commit vào shop_drawings table."

### 0.3. Upload all 11 files (idempotency demo)

```bash
# Run full pipeline test
node scripts/upload-test-pipeline.mjs
```

**Nói**:
> "Upload all 11 files. Sau khi upload lần 2, hệ thống detect duplicate → return same upload_id (idempotent). No duplicate rows in DB."

**Điểm kỹ thuật**:
- `POST /api/upload` multipart → multer stores at `data/uploads/<hash>.xlsx`
- `POST /api/upload/:id/configure` → detect doc_type via header pattern
- `POST /api/upload/:id/preview` → parse without DB writes
- `POST /api/upload/:id/commit` → execute ingestor (parse + commit)
- `POST /api/upload/:id/report` → `{ inserted, updated, skipped, errors }`

### 0.4. Verify data in DB

```bash
PGPASSWORD=pmo_dev_pwd psql -h 127.0.0.1 -p 5433 -U pmo_user -d pmo -c "
SELECT status, count(*) FROM shop_drawings GROUP BY status ORDER BY status"
# → DRAFT: 90
PGPASSWORD=pmo_dev_pwd psql -h 127.0.0.1 -p 5433 -U pmo_user -d pmo -c "
SELECT count(*) FROM construction_schedule_items"
# → 416
```

**Nói**:
> "Sau khi upload, shop_drawings có 90 DRAFT, construction_schedule_items có 416 rows. Dữ liệu sẵn sàng để demo visualization."



## Phần 1 — Control Center / 4-pillar Dashboard (5 phút)

**Mục tiêu**: Show visualization: ingestion → DB → pie chart 4 pillars.

### 1.1. Mở browser

```
URL: http://localhost:3000
```

**Nói**:
> "Đây là PMO MVP. Sau khi ingestion xong, hệ thống tự động visualize 4 pillars: Construction, Shop Drawing, Material, Payment."

### 1.2. Login với `admin@hbg.com`

- Click chip "Admin" → tự điền email/password
- Click "Đăng nhập"

### 1.3. Sau khi login → redirect `/hq` (Control Center)

- Sidebar bên trái có 12 menu
- 4-pillar pie chart ở giữa

**Nói**:
> "4 pillars: Construction (416 items), Shop Drawing (90 DRAFT), Material (75 materials), Payment (271 PENDING). Hover vào slice → tooltip chi tiết."

### 1.4. Period filter

- Click dropdown "Period" → chọn "This month"
- Chart update real-time

**Nói**:
> "Dữ liệu được compute từ 4 APIs song song: schedule, shop, materials, payments. Filter theo tháng/quý/custom date range."

### 1.5. Notification bell (góc phải)

- Click icon bell → dropdown với unread count (216 unread)
- Click 1 notification → mark as read + navigate

**Nói**:
> "216 unread notifications. Auto-refresh mỗi 30s."



## Phần 2 — Shop Drawing + L1-L5 Approval (6 phút)

**Mục tiêu**: Show workflow duyệt shop drawing đa cấp (L1 → L2 → ... → L5).

### 2.1. Vào Shop List

- Sidebar → "Shop List" hoặc navigate `/hq/shop`

**Nói**:
> "90 shop drawings đang ở status DRAFT. Mỗi drawing có 5 levels approval: L1 (concept) → L2 (schematic) → L3 (detailed) → L4 (construction) → L5 (as-built)."

### 2.2. Filter theo status

- Filter: "DRAFT" → thấy drawings chưa submit
- Filter: "IN_REVIEW" → thấy drawings đang chờ duyệt

### 2.3. Tạo shop drawing mới

- Click "New Shop Drawing"
- Điền: project, zone, code, name, planned_submit_date
- Click "Save as Draft"

### 2.4. Submit

- Click drawing vừa tạo
- Click "Submit for Approval" → status chuyển SUBMITTED

### 2.5. L1-L5 Approve

- Click button "Approve L1" → modal hiện ra:
  - Response: chọn **P (Pass)** hoặc **F (Fail)** hoặc **C (Comment only)**
  - Comment: nhập text
- Click "Submit" → drawing chuyển sang L2
- Lặp lại L2 → L3 → L4 → L5

**Nói**:
> "Mỗi cấp có response riêng: P = Pass (chuyển cấp), F = Fail (reject, vẽ lại), C = Comment (yêu cầu thêm thông tin, không chuyển cấp). Khi đạt L5 thì auto-approve."

**Điểm kỹ thuật**:
- 5 columns `bql_l1_response`..`bql_l5_response` trong schema
- Endpoint `POST /api/shop-drawings/:id/approve-level` với role check

### 2.6. History (audit trail)

- Click tab "History" → thấy toàn bộ audit log của drawing này
  - Action, user, timestamp, before/after diff, comment

**Nói**:
> "Mỗi thay đổi đều được log vào audit_log — ai làm gì, lúc nào, thay đổi gì. Compliance-ready."



## Phần 3 — Material Submittal + TVGS (5 phút)

**Mục tiêu**: Show workflow submittal + SLA tracking (3-day supervisor deadline).

### 3.1. Vào Materials

- Sidebar → "Materials"

### 3.2. Tạo submittal mới

- Click "New Submittal"
- Chọn material từ dropdown
- Submittal code, supplier
- Click "Create"

### 3.3. Submit for TVGS

- Click submittal vừa tạo
- Click "Submit for TVGS"
- Modal confirm: "Supervisor deadline: 3 days from now"
- Click OK

**Nói**:
> "TVGS = Technical Validation & General Survey. Sau khi submit, supervisor có 3 ngày để duyệt. Quá hạn sẽ auto-escalate lên CEO."

**Điểm kỹ thuật**:
- Schema: `supervisor_approval_days = 3`, auto-compute `supervisor_deadline`
- Cron job mỗi 1h check overdue → notify CEO + PM
- Endpoint: `POST /api/jobs/escalate-tvgs` (manual trigger)

### 3.4. Approve / Reject

- Click submittal → "Approve" hoặc "Reject"
- Reject: nhập lý do → status REJECTED → có thể edit + re-submit

### 3.5. Overdue view

- Navigate `/hq/materials?overdue=1`
- Hoặc: API `GET /api/projects/:id/material-submittals/overdue`

**Nói**:
> "44 material submittals: 1 DRAFT, 38 SUBMITTED, 4 APPROVED, 1 REJECTED. Hệ thống sẽ auto-escalate sau 3 ngày."



## Phần 4 — Payment 4-step Chain (5 phút)

**Mục tiêu**: Show chain nghiêm ngặt contracts → invoices → payment_requests → payments.

### 4.1. Vào Payment

- Sidebar → "Payment"

### 4.2. Step 1: Create Contract

- Tab "Contracts" → "New Contract"
- Vendor, amount, retention_pct (e.g. 10%), start/end date
- Save → status ACTIVE

### 4.3. Step 2: Create Invoice

- Từ contract vừa tạo → "Add Invoice"
- Amount (e.g. 30% contract value), due_date
- Save

**Nói**:
> "Invoice phải thuộc 1 contract. Không thể tạo invoice độc lập."

### 4.4. Step 3: Create Payment Request

- Từ invoice → "Request Payment"
- Amount (e.g. 100% invoice, trừ retention 10%), due_date
- Status: DRAFT → click "Submit for Approval" → SUBMITTED

### 4.5. Step 4: Approve + Pay

- Login as accounting (`accounting@hbg.com` / `acc123`)
- Vào Payment → "Pending Approval"
- Click request → "Approve" (status: APPROVED)
- Click "Record Payment" → nhập bank_ref, paid_date → DONE

**Nói**:
> "Payment chain nghiêm ngặt 4 bước. Không thể skip bước. Mỗi bước có role gate riêng: accounting cho payment, PM tạo request, CEO duyệt high-value."
> "271 PENDING, 4 APPROVED, 26 PAID payment requests. 105 contracts, 276 invoices."

### 4.6. Audit trail

- Click tab "History" → thấy toàn bộ chain log



## Phần 5 — Daily Report + Photo Upload (3 phút)

**Mục tiêu**: Show field workflow (site engineer dùng mobile/tablet).

### 5.1. Login as site

- Logout → login `site@hbg.com` / `site123`
- Auto-redirect `/field`

### 5.2. Vào Daily Report

- Click "Daily Report" hoặc navigate `/field/daily-report`

### 5.3. Tạo report

- Date (default today), weather_am/pm
- Add manpower: role_code, headcount (e.g. "Worker: 25, Foreman: 2")
- Click "Save"

### 5.4. Upload photos

- Click "Upload Photos" → chọn 3-5 ảnh từ máy
- Photos hiện ra dạng gallery thumbnails
- Click thumbnail → xem full size

**Nói**:
> "Site engineer có thể tạo daily report ngay tại công trường bằng tablet/phone. Upload ảnh bằng camera trực tiếp."

**Điểm kỹ thuật**:
- Multipart upload (multer), ≤20 files/request
- Photos lưu ở `data/uploads/`, metadata ở `daily_photos` table

### 5.5. Manpower rollup

- Navigate `/hq/manpower` (login lại as admin)
- Filter: tuần này, all projects
- Show rollup: tổng workers across 4 projects

**Nói**:
> "Hệ thống tự động rollup manpower theo tuần/tháng, cross-project. CEO có thể thấy ngay dự án nào thiếu người."



## Phần 6 — OTD KPI + Audit Log (3 phút)

**Mục tiêu**: Show KPI tổng hợp + audit trail toàn hệ thống.

### 6.1. OTD Page

- Sidebar → "OTD" (admin/pm/ceo only)
- Mặc định project hiện tại, grace_days=0

**Nói**:
> "OTD = On-Time Delivery. Tỷ lệ tasks hoàn thành đúng hạn. Threshold mặc định là 'bám sát kế hoạch' — actual_end ≤ planned_end."
> "416 construction schedule items. By Zone breakdown. 6-month trend chart."

### 6.2. By Zone

- Scroll xuống → bảng "By Zone": mỗi zone có OTD%
- Sort by lowest → thấy zone nào trễ nhất

### 6.3. 6-month trend

- Biểu đồ đường: OTD% theo tháng trong 6 tháng gần nhất

**Nói**:
> "OTD < 70% là màu đỏ (critical), 70-90% vàng (watch), ≥90% xanh (good). Hệ thống tự tính toán từ construction_schedule_items."

### 6.4. Audit Log

- Navigate `/audit` (admin/ceo/pmo only)
- Filter theo resource_type, user, date range
- Export CSV (620 audit entries)

**Nói**:
> "Mọi thay đổi đều được log. Tìm kiếm theo user/resource/date. Export CSV cho audit bên ngoài."
> "620 audit entries, 35 areas, 105 contracts, 75 subcontractors, 30 suppliers."



## Phần 7 — Setup Commands (Chuẩn bị trước demo)

### 7.1. One-time setup (chạy 1 lần)

```bash
# Clone repo
git clone https://github.com/TungLinhh/pmo-project.git
cd pmo-project

# Install all workspaces
npm install

# Start PostgreSQL (port 5433)
./backend/scripts/pg-ctl.sh start
# Data dir: ../data/pgdata/, Port: 5433

# Apply DB schema + seed demo data (idempotent)
cd backend
npm run init-db
# Applies: drizzle/0000_naive_nick_fury.sql + 9998_align + 9999_issues
# Creates unique indexes, seeds tenant hbg, 7 users, 3 projects, 36 zones
```

### 7.2. Daily dev / demo prep

```bash
# Build frontend (prod)
npm run build
# Output: frontend/dist/ (served by Express on port 3000)

# Start backend only (port 3000)
npm start

# Or dev mode (backend + frontend HMR)
npm run dev
# Backend: http://localhost:3000
# Frontend: http://localhost:5173 (HMR)
```

### 7.3. Generate test Excel files (cho ingestion demo)

```bash
cd backend
node scripts/generate-test-excel.mjs
# → 11 files + manifest.json tại data/test-fixtures/TEST-MASTER-01/
# Files: Shop TST-A, TĐ TST-B, Vật tư TST-C, Báo cáo TEST, MCR-MM TEST,
#        quy trình TEST, File start TEST, TĐ XYZ-BAD (error), Shop EMPTY (error)
```

### 7.4. Seed rich demo data (idempotent)

```bash
# Enrich TEST-MASTER-01 project (id=3) with realistic demo data
node scripts/seed-demo-data-enrich.mjs
# → Distributes 90 shop DRAFT, 44 material submittals, 271 payment requests,
#   35 issues, 10 notifications, area hierarchy (building→floor→area)
```

### 7.5. Verify

```bash
# Health check
curl http://localhost:3000/api/health
# → {"status":"ok","timestamp":"...","authenticated":false,"user":null}

# Verify data counts
PGPASSWORD=pmo_dev_pwd psql -h 127.0.0.1 -p 5433 -U pmo_user -d pmo -c "
SELECT 'shops' t, status, count(*) c FROM shop_drawings GROUP BY status
UNION ALL SELECT 'materials' t, status, count(*) FROM material_submittals GROUP BY status
UNION ALL SELECT 'payments' t, overall_status, count(*) FROM payment_requests GROUP BY overall_status
UNION ALL SELECT 'issues' t, severity, count(*) FROM issues GROUP BY severity
UNION ALL SELECT 'schedule' t, '', count(*) FROM construction_schedule_items
UNION ALL SELECT 'notifications' t, '', count(*) FROM notifications WHERE read_at IS NULL;"
```

### 7.6. Tunnel (optional, để share URL)

```bash
cloudflared tunnel --url http://localhost:3000
# → https://firm-writings-ids-basename.trycloudflare.com
```



## Q&A — Câu hỏi thường gặp

### Q1: "Bao lâu thì migrate dữ liệu từ Excel hiện tại?"

> **A**: Tùy số lượng file. Với 50 files, 1-2 giờ. Hệ thống có sẵn wizard 5 bước (upload → analyze → map → commit → report). Mỗi file chạy riêng, idempotent (re-upload không duplicate).

### Q2: "Có mobile app không?"

> **A**: Hiện tại web responsive — dùng được trên tablet/phone. Native mobile (iOS/Android) dự kiến v0.9. Field hiện tại dùng tablet/phone browser, OK cho daily report + photo.

### Q3: "Bao nhiêu users đồng thời?"

> **A**: Test với 50 concurrent users, ổn. Single-server (Express) chịu được 500-1000 users tùy use case. Multi-server cần Redis (in-memory token map).

### Q4: "Bảo mật thế nào?"

> **A**: Bearer token (32-char hex), CORS whitelist (production), rate limiting (đã disable cho admin), password bcrypt (sẽ enable v0.4). Audit log mọi state change. HTTPS qua reverse proxy (nginx/Cloudflare).

### Q5: "Có tích hợp ERP không?"

> **A**: Chưa. v0.5 sẽ có API webhook để sync với SAP/Oracle. Hiện tại manual export CSV.

### Q6: "Backup thế nào?"

> **A**: `pg_dump` daily cron, lưu 7 ngày local + 30 ngày S3. Restore test hàng tháng. Photos backup riêng (cron rsync to NAS).

### Q7: "License cost?"

> **A**: Proprietary, internal use only. Single one-time payment + yearly support fee (negotiate).

### Q8: "Khi nào production-ready?"

> **A**: v0.3.1 hiện tại (Sep 2026) là demo-ready. v1.0 production-ready: 2026-Q4 (sau khi enable password hashing, real email, rate limit).



## Tips trình bày

### 1. Trước khi demo (15 phút chuẩn bị)

- Verify backend up: `curl http://localhost:3000/api/health` → `{"status":"ok",...}`
- Verify data seeded: run verification SQL above
- Verify tunnel up: `curl https://firm-writings-ids-basename.trycloudflare.com/api/health`

### 2. Trong khi demo

- **Nói chậm, rõ ràng**. Đừng vội.
- **Click chuột có chủ đích**. Tránh click lung tung.
- **Nếu bug xuất hiện**: dùng script, không debug tại chỗ. Ghi nhận, fix sau.
- **Nếu stakeholder hỏi ngoài scope**: "Tôi ghi nhận, sẽ phản hồi sau demo."

### 3. Sau khi demo (5 phút wrap-up)

- Cảm ơn
- Gửi email follow-up với:
  - Slide tóm tắt
  - Link demo
  - Credentials (nếu stakeholder muốn thử)
  - Timeline v0.4 / v1.0



## Cấu hình demo cụ thể (tham khảo)

### Tunnel URL (Cloudflare)

```
https://firm-writings-ids-basename.trycloudflare.com
```

### Local (nếu demo on-site)

```
http://localhost:3000     (prod build, single port)
http://localhost:5173     (dev with HMR)
```

### Tài khoản demo

| Email | Password | Role | Dùng cho phần |
|-------|----------|------|---------------|
| `admin@hbg.com` | `admin123` | admin | Mọi thứ |
| `ceo@hbg.com` | `ceo123` | CEO | Phần 6 (OTD) |
| `pm@hbg.com` | `pm123` | PM | Phần 2 (Shop) |
| `site@hbg.com` | `site123` | Site | Phần 5 (Daily Report) |
| `procurement@hbg.com` | `proc123` | Procurement | Phần 3 (Material) |
| `accounting@hbg.com` | `acc123` | Accounting | Phần 4 (Payment) |

### File Excel mẫu (sẵn trong `backend/data/test-fixtures/TEST-MASTER-01/`)

```
Shop TST-A.xlsx            # 50 items × 33 cols (SHOP)
TĐ TST-B.xlsx              # 100 items × 15 cols (SCHEDULE)
Vật tư TST-C.xlsx          # 80 items × 10 cols (MATERIAL)
Báo cáo công việc TEST.xlsx # 84 rows × 27 cols (DAILY)
MCR-MM TEST.xlsx           # 20 rows × 8 cols (RFA)
quy trình thực hiện TEST.xlsx # 8 steps × 5 cols (BP)
File start TEST.xlsx       # 6 files × 4 cols
TĐ XYZ-BAD.xlsx            # ERROR: zone not found
Shop EMPTY.xlsx            # ERROR: empty file
quy trình thực hiện TEST.xlsx
File start TEST.xlsx
```



## Phụ lục: Những câu hỏi kỹ thuật có thể gặp

### "Dùng ORM gì?"

> Raw `pg` (PostgreSQL node driver), không ORM. Lý do: schema mature (43 tables), cần full control SQL (CTE, RETURNING, ON CONFLICT). Drizzle/Prisma thêm indirection không cần thiết.

### "Frontend bundle size?"

> 399KB JS gzipped 110KB, 40KB CSS. Acceptable cho internal tool. Nếu cần optimize: code-splitting per route (chưa làm, future v0.4).

### "Có dùng TypeScript không?"

> Chưa. Backend plain JS + JSDoc, Frontend JSX. TypeScript migration dự kiến v0.5.

### "Test coverage?"

> 70 E2E tests (4 baseline suites). Manual UI testing. Unit test coverage ~30% (chưa đo chính thức). Sẽ tăng dần.

### "CI/CD?"

> GitHub Actions: lint + build + 4 E2E suites + schema audit. Deploy manual (single-server). Docker image build + push to registry tự động.

### "Monitoring/logging?"

> Backend: stdout → `pm2`/`systemd` journal. Frontend: browser console. DB: `data/pg_log/`. Tunnel: cloudflared process output. Cải thiện: ship logs to Loki/ELK (v0.5).

### "Schema migration?"

> `drizzle/9998_align_schema_with_routes.sql` (patches) + `9999_add_issues_table.sql` (initial missing tables). `npm run init-db` apply idempotently.

### "Multi-tenant?"

> Schema supports (mọi table có `tenant_id`). UI single-tenant hiện tại. v0.8 sẽ thêm tenant switcher.



## Kết thúc

Nếu có câu hỏi hoặc cần điều chỉnh, liên hệ engineering team.

**Live demo**: https://firm-writings-ids-basename.trycloudflare.com
**Source code**: https://github.com/TungLinhh/pmo-project
**Docs**: [docs/PRODUCT_TECHNICAL_DOCUMENTATION.md](PRODUCT_TECHNICAL_DOCUMENTATION.md)

