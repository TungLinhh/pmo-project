# PMO MVP — Demo Script (30 phút cho stakeholder)

> **Mục đích**: Demo end-to-end 4-pillar dashboard + L1-L5 shop approval + payment chain cho sếp/PM/CEO.
>
> **Stack chính**: Login → Control Center → Shop Drawing (L1-L5) → Material Submittal (TVGS) → Payment 4-step → Daily Report + Photo → OTD KPI.
>
> **Yêu cầu trước khi demo**:
> - Backend + Postgres đang chạy (kiểm tra `curl http://localhost:3000/api/health` trả 200)
> - Browser sẵn sàng tại `http://localhost:5173` (dev) hoặc `http://localhost:3000` (prod)
> - Mở sẵn tab Postman/curl để call API nếu cần
> - Chuẩn bị sẵn 1 file Excel mẫu `Tien_Do_Thanh_Toan_HoaBinh.xlsx` để demo upload wizard

---

## Phân bổ thời gian (30 phút)

| Phần | Thời gian | Người trình bày | Người xem chính |
|------|-----------|------------------|------------------|
| 1. Giới thiệu + Login | 2 phút | PMO | All |
| 2. Control Center (4-pillar dashboard) | 5 phút | PMO | CEO, PM |
| 3. Shop Drawing + L1-L5 Approval | 6 phút | PMO | CEO, PM, BQL |
| 4. Material Submittal + TVGS | 5 phút | PMO | Procurement |
| 5. Payment 4-step chain | 5 phút | PMO | CEO, Accounting |
| 6. Daily Report + Photo Upload | 3 phút | Site lead | PM, CEO |
| 7. OTD KPI + Audit Log | 3 phút | PMO | CEO |
| Q&A | 1 phút | All | All |

---

## Phần 1 — Giới thiệu + Login (2 phút)

**Mục tiêu**: Show 7 demo accounts + role-based redirect.

### 1.1. Mở browser

```
URL: http://localhost:3000
```

**Nói**:
> "Đây là PMO MVP, hệ thống quản lý dự án xây dựng. Tôi sẽ demo 7 quy trình chính trong 25 phút tới."

### 1.2. Login với `admin@hbg.com`

- Click chip "Admin" → tự điền email/password
- Click "Đăng nhập"

**Nói**:
> "Hệ thống có 7 role: admin, CEO, PM, PMO, site, procurement, accounting. Mỗi role có dashboard khác nhau."

**Điểm kỹ thuật** (nếu CEO hỏi):
- Auth: Bearer token 32-char hex, in-memory Map, logout invalidates ngay
- 7 demo accounts pre-seeded bởi `npm run init-db`

### 1.3. Sau khi login

- Redirect về `/hq` (Control Center)
- Sidebar bên trái có 12 menu (Control Center, Issues, Shop List, Materials, Manpower, Payment, OTD, Notifications, Audit, ...)

**Tip trình bày**: Click chuột vào các icon sidebar để show responsive UI, không cần đi sâu vào.

---

## Phần 2 — Control Center / 4-pillar Dashboard (5 phút)

**Mục tiêu**: Show cái nhìn tổng quan 1 dự án (BTE-WP4-HBC).

### 2.1. ProjectPicker

- Click dropdown "Project" ở góc trên bên trái
- Chọn "BTE-WP4-HBC - Khu du lịch sinh thái Bãi Tràm"

**Nói**:
> "ProjectPicker thay thế select thường — search nhanh theo code hoặc tên Việt/Anh."

### 2.2. 4-pillar pie chart

- Nhìn 4 vòng tròn: Construction / Shop Drawing / Material / Payment
- Mỗi vòng hiển thị status breakdown (e.g. Construction: 24 on-track, 5 late, 3 critical)

**Nói**:
> "Đây là 4 trụ cột của dự án. Mỗi vòng tròn thể hiện tỷ lệ từng trạng thái. Hover vào slice sẽ thấy chi tiết."

### 2.3. Hover tooltip

- Di chuột qua 1 slice bất kỳ → tooltip hiện ra với số liệu cụ thể

**Điểm kỹ thuật** (nếu hỏi):
- Custom SVG pie chart (no library, ~50 LOC)
- Tooltip follow cursor, no overflow

### 2.4. Period filter

- Click dropdown "Period" → chọn "This month" / "Last month" / "Custom"
- Chart update real-time

**Nói**:
> "Có thể filter theo tháng/quý/custom date range. Dữ liệu được compute từ 4 APIs song song: schedule, shop, materials, payments."

**Nếu hỏi chi tiết**: Show tooltip → click vào 1 task bất kỳ → navigate sang Progress Detail.

### 2.5. Notification bell (góc phải)

- Click icon bell → show dropdown với unread count
- Click 1 notification → mark as read + navigate tới resource

**Nói**:
> "Notification bell cho biết real-time có bao nhiêu việc cần xử lý. Auto-refresh mỗi 30s."

---

## Phần 3 — Shop Drawing + L1-L5 Approval (6 phút)

**Mục tiêu**: Show workflow duyệt shop drawing đa cấp (L1 → L2 → ... → L5).

### 3.1. Vào Shop List

- Sidebar → "Shop List" (hoặc navigate `/hq/shop`)

**Nói**:
> "Đây là danh sách shop drawings. Mỗi drawing có 5 levels approval: L1 (concept) → L2 (schematic) → L3 (detailed) → L4 (construction) → L5 (as-built). Mỗi cấp do 1 bộ phận duyệt."

### 3.2. Filter theo status

- Filter: "DRAFT" → thấy drawings chưa submit
- Filter: "IN_REVIEW" → thấy drawings đang chờ duyệt

### 3.3. Tạo shop drawing mới

- Click "New Shop Drawing"
- Điền: project, zone, code, name, planned_submit_date
- Click "Save as Draft"

### 3.4. Submit

- Click drawing vừa tạo
- Click "Submit for Approval" → status chuyển SUBMITTED

### 3.5. L1-L5 Approve

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

### 3.6. History (audit trail)

- Click tab "History" → thấy toàn bộ audit log của drawing này
  - Action, user, timestamp, before/after diff, comment

**Nói**:
> "Mỗi thay đổi đều được log vào audit_log — ai làm gì, lúc nào, thay đổi gì. Compliance-ready."

---

## Phần 4 — Material Submittal + TVGS (5 phút)

**Mục tiêu**: Show workflow submittal + SLA tracking (3-day supervisor deadline).

### 4.1. Vào Materials

- Sidebar → "Materials"

### 4.2. Tạo submittal mới

- Click "New Submittal"
- Chọn material từ dropdown
- Submital code, supplier
- Click "Create"

### 4.3. Submit for TVGS

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

### 4.4. Approve / Reject

- Click submittal → "Approve" hoặc "Reject"
- Reject: nhập lý do → status REJECTED → có thể edit + re-submit

### 4.5. Overdue view

- Navigate `/hq/materials?overdue=1`
- Hoặc: API `GET /api/projects/:id/material-submittals/overdue`

**Nói**:
> "Đây là danh sách submittals quá hạn TVGS. Hệ thống sẽ auto-escalate sau 3 ngày."

---

## Phần 5 — Payment 4-step Chain (5 phút)

**Mục tiêu**: Show chain nghiêm ngặt contracts → invoices → requests → payments.

### 5.1. Vào Payment

- Sidebar → "Payment"

### 5.2. Step 1: Create Contract

- Tab "Contracts" → "New Contract"
- Vendor, amount, retention_pct (e.g. 10%), start/end date
- Save → status ACTIVE

### 5.3. Step 2: Create Invoice

- Từ contract vừa tạo → "Add Invoice"
- Amount (e.g. 30% contract value), due_date
- Save

**Nói**:
> "Invoice phải thuộc 1 contract. Không thể tạo invoice độc lập."

### 5.4. Step 3: Create Payment Request

- Từ invoice → "Request Payment"
- Amount (e.g. 100% invoice, trừ retention 10%), due_date
- Status: DRAFT → click "Submit for Approval" → SUBMITTED

### 5.5. Step 4: Approve + Pay

- Login as accounting (`accounting@hbg.com` / `acc123`)
- Vào Payment → "Pending Approval"
- Click request → "Approve" (status: APPROVED)
- Click "Record Payment" → nhập bank_ref, paid_date → DONE

**Nói**:
> "Payment chain nghiêm ngặt 4 bước. Không thể skip bước. Mỗi bước có role gate riêng: accounting cho payment, PM tạo request, CEO duyệt high-value."

**Nếu hỏi "Có thể chỉnh sửa sau khi approve?"**:
> "Có thể tạo request mới (re-submit) nếu cần sửa. Không thể rollback trực tiếp — compliance-ready."

### 5.6. Audit trail

- Click tab "History" → thấy toàn bộ chain log

---

## Phần 6 — Daily Report + Photo Upload (3 phút)

**Mục tiêu**: Show field workflow (site engineer dùng mobile/tablet).

### 6.1. Login as site

- Logout → login `site@hbg.com` / `site123`
- Auto-redirect `/field`

### 6.2. Vào Daily Report

- Click "Daily Report" hoặc navigate `/field/daily-report`

### 6.3. Tạo report

- Date (default today), weather_am/pm
- Add manpower: role_code, headcount (e.g. "Worker: 25, Foreman: 2")
- Click "Save"

### 6.4. Upload photos

- Click "Upload Photos" → chọn 3-5 ảnh từ máy
- Photos hiện ra dạng gallery thumbnails
- Click thumbnail → xem full size

**Nói**:
> "Site engineer có thể tạo daily report ngay tại công trường bằng tablet/phone. Upload ảnh bằng camera trực tiếp."

**Điểm kỹ thuật**:
- Multipart upload (multer), ≤20 files/request
- Photos lưu ở `data/uploads/`, metadata ở `daily_photos` table

### 6.5. Manpower rollup

- Navigate `/hq/manpower` (login lại as admin)
- Filter: tuần này, all projects
- Show rollup: tổng 247 workers across 4 projects

**Nói**:
> "Hệ thống tự động rollup manpower theo tuần/tháng, cross-project. CEO có thể thấy ngay dự án nào thiếu người."

---

## Phần 7 — OTD KPI + Audit Log (3 phút)

**Mục tiêu**: Show KPI tổng hợp + audit trail toàn hệ thống.

### 7.1. OTD Page

- Sidebar → "OTD" (admin/pm/ceo only)
- Mặc định project hiện tại, grace_days=0

**Nói**:
> "OTD = On-Time Delivery. Tỷ lệ tasks hoàn thành đúng hạn. Threshold mặc định là 'bám sát kế hoạch' — actual_end ≤ planned_end."

### 7.2. By Zone

- Scroll xuống → bảng "By Zone": mỗi zone có OTD%
- Sort by lowest → thấy zone nào trễ nhất

### 7.3. 6-month trend

- Biểu đồ đường: OTD% theo tháng trong 6 tháng gần nhất
- Click vào tháng → drill down

**Nói**:
> "OTD < 70% là màu đỏ (critical), 70-90% vàng (watch), ≥90% xanh (good). Hệ thống tự tính toán từ construction_schedule_items."

### 7.4. Audit Log

- Navigate `/audit` (admin/ceo/pmo only)
- Filter theo resource_type, user, date range
- Export CSV

**Nói**:
> "Mọi thay đổi đều được log. Tìm kiếm theo user/resource/date. Export CSV cho audit bên ngoài."

---

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

> **A**: v0.3.0 hiện tại (Sep 2026) là demo-ready. v1.0 production-ready: 2026-Q4 (sau khi enable password hashing, real email, rate limit).

---

## Tips trình bày

### 1. Trước khi demo (15 phút chuẩn bị)

```bash
# Verify backend up
curl http://localhost:3000/api/health
# → {"status":"ok",...}

# Verify data seeded
PGPASSWORD=pmo_dev_pwd psql -h 127.0.0.1 -p 5433 -U pmo_user -d pmo -c "SELECT COUNT(*) FROM projects;"
# → 2 projects (BTE-WP4-HBC, LAWRENCE-STING-2)

# Verify tunnel up
curl https://firm-writings-ids-basename.trycloudflare.com/api/health
# → 200 OK
```

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

---

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
| `ceo@hbg.com` | `ceo123` | CEO | Phần 7 (OTD) |
| `pm@hbg.com` | `pm123` | PM | Phần 3 (Shop) |
| `site@hbg.com` | `site123` | Site | Phần 6 (Daily Report) |
| `procurement@hbg.com` | `proc123` | Procurement | Phần 4 (Material) |
| `accounting@hbg.com` | `acc123` | Accounting | Phần 5 (Payment) |

### File Excel mẫu (sẵn trong `data/test-fixtures/`)

```
Tien_Do_Thanh_Toan_HoaBinh.xlsx       # payment schedule
Tien_do_thi_cong_HoaBinh_2024.xlsx    # construction
```

---

## Phụ lục: Những câu hỏi kỹ thuật có thể gặp

### "Dùng ORM gì?"

> Raw `pg` (PostgreSQL node driver), không ORM. Lý do: schema mature, cần full control SQL (CTE, RETURNING, ON CONFLICT). Drizzle/Prisma thêm indirection không cần thiết.

### "Frontend bundle size?"

> 399KB JS gzipped 110KB, 40KB CSS. Acceptable cho internal tool. Nếu cần optimize: code-splitting per route (chưa làm, future v0.4).

### "Có dùng TypeScript không?"

> Chưa. Backend plain JS + JSDoc, Frontend JSX. TypeScript migration dự kiến v0.5.

### "Test coverage?"

> 70 E2E tests (4 suites). Manual UI testing. Unit test coverage ~30% (chưa đo chính thức). Sẽ tăng dần.

### "CI/CD?"

> GitHub Actions: lint + build + 4 E2E suites + schema audit. Deploy manual (single-server). Docker image build + push to registry tự động.

### "Monitoring/logging?"

> Backend: stdout → `pm2`/`systemd` journal. Frontend: browser console. DB: `data/pg_log/`. Tunnel: cloudflared process output. Cải thiện: ship logs to Loki/ELK (v0.5).

### "Schema migration?"

> `drizzle/9998_align_schema_with_routes.sql` (patches) + `9999_add_issues_table.sql` (initial missing tables). `npm run init-db` apply idempotently.

### "Multi-tenant?"

> Schema supports (mọi table có `tenant_id`). UI single-tenant hiện tại. v0.8 sẽ thêm tenant switcher.

---

## Kết thúc

Nếu có câu hỏi hoặc cần điều chỉnh, liên hệ engineering team.

**Live demo**: https://firm-writings-ids-basename.trycloudflare.com
**Source code**: https://github.com/TungLinhh/pmo-project
**Docs**: [docs/PRODUCT_TECHNICAL_DOCUMENTATION.md](PRODUCT_TECHNICAL_DOCUMENTATION.md)
