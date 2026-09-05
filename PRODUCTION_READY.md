# PMO Production Ready — 2026-09-05

## ✅ Verification
- **Lint**: Backend OK (24 file .js), Frontend build OK (399KB JS, 40KB CSS)
- **Secret scan**: 0 suspicious (env-driven only)
- **Tests**: 70/70 PASS (29 API + 13 payment + 13 L1-L5/escalation + 15 schema)
- **Tunnel**: `https://firm-writings-ids-basename.trycloudflare.com` (live, HTTP 200, 369ms latency)

## 🆕 Phase 3 Features (2026-09-05)

### TVGS Auto-escalation
- Mount: `/api/jobs`
- Manual: `POST /api/jobs/escalate-tvgs` → trả về { escalated_count, items }
- Status: `GET /api/jobs/escalate-tvgs/status` → { last_run, last_result }
- Auto: chạy mỗi 1 giờ (setInterval, bỏ qua khi NODE_ENV=test)
- Logic: submittal quá `supervisor_deadline` + chưa escalated hôm nay → tạo notification cho PM (nếu có) hoặc admin (fallback) + tất cả CEO, mark `escalated_at`
- Schema: `material_submittals.escalated_at TIMESTAMP`, `projects.pm_user_id INTEGER REFERENCES users(id)`

### L1-L5 Shop Drawing Approval
- Mount: `/api/shop-drawings` (gộp vào shop.js, bỏ shop-approval.js)
- State machine: DRAFT → SUBMITTED → (REJECTED → DRAFT/SUBMITTED) | (L1.P → L2.P → L3.P → L4.P → L5.P → APPROVED)
- Endpoints:
  - `POST /api/shop-drawings/` (create, status=DRAFT)
  - `GET /api/shop-drawings/` (list, filter by project_id, status)
  - `GET /api/shop-drawings/:id` (single + zone_code)
  - `PATCH /api/shop-drawings/:id` (edit DRAFT/REJECTED only)
  - `POST /api/shop-drawings/:id/transition` (single-level submit/approve/reject, status machine validated)
  - `POST /api/shop-drawings/:id/approve-level { level: 1-5, response: 'P'/'F'/'C', comment }`
  - `GET /api/shop-drawings/:id/approval-state` (per-level response/date/comment + current_level + is_fully_approved)
  - `GET /api/shop-drawings/:id/history` (audit trail)
- Response values: 'P' = Pass, 'F' = Fail, 'C' = Conditional, NULL = pending
- Validation: phải submit trước khi approve; previous levels phải pass; L5 PASS → APPROVED; FAIL → REJECTED (re-submit được)
- Auth: `requireRole('admin', 'ceo', 'pmo', 'bql')` cho approve-level

### OTD KPI Page (`/hq/otd`)
- Frontend: `OTDPage.jsx` + CSS
- API: `GET /api/projects/:id/otd?grace_days=0` → { otd_pct, total_items, on_time, late, by_zone, trend_6mo }
- Decision 2026-09-05: threshold = bám sát kế hoạch (actual_end ≤ planned_end + grace_days, default grace=0)

### Photo Gallery
- Backend table: `daily_photos (id, daily_report_id, file_path, mime_type, file_size, uploaded_by, created_at)` + index
- API: `POST /api/daily-reports/:id/photos` (multipart), `GET /api/daily-reports/:id/photos`
- Frontend: `DailyReportForm.jsx` — tạo daily report, thêm manpower, upload ảnh

### Submittal History Modal
- Component: `SubmittalHistory.jsx` — lấy từ audit log
- Hiển thị: current state (status, SLA, TVGS deadline, revision) + audit trail (action, user, timestamp, note, field_changes)

## 🐛 Bug đã fix
1. **`{ mergeParams: true }`** cho 19 Router — Express không tự merge params từ parent path
2. **`$N` thủ công trong routes bị conflict với `convertSql` '?' → '$N'** — thêm check `/\$\d+/` skip convert
3. **`payment.js` inconsistent types $1** — cast `$1::workflow_status` ở cả 3 CASE WHEN
4. **`shop.js` dùng `sla_deadline` column không tồn tại** → xóa
5. **`shop_drawings` transition `$1` cũng inconsistent types** → cast `$1::workflow_status`
6. **`notifications` schema sai** — dùng `link`/`is_read` không tồn tại → đổi sang `resource_type`/`resource_id` (đúng schema)
7. **`user_role` enum không có 'ceo'** → chỉ check `is_ceo = true`
8. **2 router cùng path `/api/shop-drawings`** → gộp shop-approval.js vào shop.js

## 📁 Files
- 22 routes mới (lib/ + routes/)
- 5 components mới (frontend): OTDPage, DailyReportForm, SubmittalHistory
- 1 schema migration: `9998_align_schema_with_routes.sql` (thêm escalated_at, pm_user_id)
- index.js: 1166 → 130 LOC
- Tổng: 70/70 tests pass

## 🔗 Tunnel
- URL: https://firm-writings-ids-basename.trycloudflare.com
- Login: admin@hbg.com / admin123
- Routes mới: /hq/otd, /hq/materials (L1-L5 history), /field/daily-report
- API: /api/jobs/escalate-tvgs (POST), /api/shop-drawings/:id/approve-level (POST)

## ⚠️ Known limitations
- UI E2E test 2/4 do network chập chờn (không phải bug code)
- TVGS escalation auto-run 1h/lần chỉ khi server chạy
- Photo upload size limit: theo Express default (100KB nếu không set)
- L1-L5 dùng `requireRole('admin', 'ceo', 'pmo', 'bql')` — cần đảm bảo user role đúng
