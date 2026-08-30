# PMO MVP — Implementation Checklist

Ngày: 2026-08-29 · Spec: `/mnt/c/Users/vutun/Downloads/PMO_UI_Specification.md`

## Tổng quan theo mục 40 (MVP Vertical Slice)

| # | Màn hình | File | Status | Ghi chú |
|---|---|---|---|---|
| **HQ** |||||
| 1 | Login | `components/Login.jsx` | ✅ | 7 demo accounts, auto-fill chips |
| 2 | App Shell | `components/HqShell.jsx` | ✅ | Sidebar + BellDropdown |
| 3 | Project Control Center | `hq/ControlCenter.jsx` | ✅ | 4 pillars + pie chart + hover tooltip |
| 4 | Project Overview | `hq/ProjectOverview.jsx` | ✅ | |
| 5 | Progress Detail | `hq/ProgressDetail.jsx` | ✅ | |
| 6 | Shop List | `hq/ShopList.jsx` | ✅ | |
| 7 | Issue Detail | `hq/IssueDetail.jsx` | ✅ | CEO directive form |
| 8 | Issues list | `hq/Issues.jsx` | ✅ | Filter + click → detail |
| 9 | Notification Center | `hq/NotificationCenter.jsx` | ✅ | |
| **Field** |||||
| 10 | Login | `components/Login.jsx` | ✅ | Auto-redirect Site role |
| 11 | Field Home | `field/FieldHome.jsx` | ✅ | |
| 12 | WBS Selection | `field/FieldStubs.jsx` | ✅ | 43.8 area hierarchy |
| 13 | Daily Progress | `field/DailyProgress.jsx` | ✅ | |
| 14 | Material | `field/FieldStubs.jsx` | ✅ | 43.4 submittal aware |
| 15 | Manpower | `field/FieldStubs.jsx` | ✅ | 32 records |
| 16 | Issue/Photo | `field/FieldStubs.jsx` | ✅ | 43.6 photo upload |
| 17 | Review/Submit | `field/FieldStubs.jsx` | ✅ | |
| 18 | Offline Sync | `field/FieldStubs.jsx` | ✅ | 43.7 conflict log |
| **Governance** |||||
| 19 | Master Data List | `governance/MasterDataList.jsx` | ✅ | |
| 20 | Master Data Edit | `governance/MasterDataEdit.jsx` | ✅ | |
| 21 | Approval Center | `governance/Approval.jsx` | ✅ | Mock — TODO nối API thật |
| 22 | Audit Log | `governance/AuditLog.jsx` | ✅ | Real data |

## Demo readiness

### ✅ Login (7 demo accounts)

| Email | Pass | Role | Permissions (write) |
|---|---|---|---|
| `admin@hbg.com` | `admin123` | admin (PMO) | All 6 modules |
| `ceo@hbg.com` | `ceo123` | pmo + is_ceo | All 6 modules |
| `pm@hbg.com` | `pm123` | pm | shop, material, schedule |
| `pmo@hbg.com` | `pmo123` | pmo | All 6 modules |
| `site@hbg.com` | `site123` | site | schedule only (Field PWA) |
| `procurement@hbg.com` | `proc123` | procurement | payment, material, master_data |
| `accounting@hbg.com` | `acc123` | accounting | payment, approval |

### ✅ Flow E2E (verified bằng curl + Playwright)

- **Login + 6 roles**: ✅ 7/7 accounts, permissions matrix khác biệt rõ ràng
- **Control Center 4 pillars**: ✅ Pie chart + hover tooltip
- **Bell dropdown**: ✅ Click → navigate, read/unread state
- **CEO directive**: ✅ POST → tạo notification + audit log
- **PM transition shop drawing (43.3)**: ✅ REVIEW → REJECTED → DRAFT
- **Procurement reject material submittal (43.4)**: ✅ require reason
- **Accounting approve payment request (43.5)**: ✅ retention + VAT + due_date
- **KPI period lock (43.10)**: ✅ Q2 2026 Material OTD locked, PUT returns 423
- **Field PWA 9 màn hình**: ✅ wired với API mới
- **Audit log**: ✅ ghi nhận mỗi action

### ⚠️ Phần còn placeholder

- **Approval Center** (`governance/Approval.jsx`): hiện mock, **chưa wire transition API** cho shop_drawings + material_submittals
- **Material Submittal page** (HQ): chưa có UI riêng, chỉ xem trong Materials tab
- **Contracts/Invoices/Payment Requests UI** (B8): API đã có (3 contracts + 6 invoices + 6 payment_requests), nhưng chưa có page UI riêng — hiện chỉ thấy trong Materials
- **Mock attachments** (C11): chưa có PDF giả cho shop_drawings/submittals/payment_requests
- **Field Photo** (C12): chưa có ảnh placeholder
- **KPI target page** (B9): API có, chưa có UI riêng — chỉ thấy placeholder trong MasterData
- **Notification channels** (43.6): chỉ in_app hoạt động, email/zalo/push lưu `not_implemented`
- **CEO role enum** (43.2): chưa có enum riêng, dùng `role='pmo' + is_ceo=1`
- **PG migration** (43.1, 43.5): PG có data 100% nhưng backend runtime vẫn dùng SQLite (sync API)
- **Direct browser testing**: chưa test thật bằng Playwright/browser (chỉ curl)

### Files quan trọng để demo

```
backend/
├── src/
│   ├── index.js (1 file, ~750 dòng, tất cả endpoints)
│   ├── lib/
│   │   ├── auth.js (7 hard-coded passwords)
│   │   └── validation.js (43.3, 43.4, 43.5, 43.7, 43.10)
│   ├── db/
│   │   ├── index.js (SQLite/PG abstraction)
│   │   └── schema-pg.js (Drizzle, 36+ tables)
│   └── services/ingest/ (9 ingestors)
├── drizzle/0000_naive_nick_fury.sql (PG schema)
├── seed-demo.mjs (12 issues + 15 notif + 5 audit + 4 directives)
├── seed-users.mjs (7 demo users)
├── seed-payments-kpi.mjs (3 contracts + 6 inv + 6 preq + 4 KPIs)
├── scripts/archive/ (migration scripts, 1-time use)
└── data/pmo.db (SQLite, runtime)

frontend/src/
├── App.jsx (Router)
├── components/
│   ├── Login.jsx (7 demo chips)
│   ├── HqShell.jsx + FieldShell.jsx
│   ├── PieChart.jsx + PieTooltip.jsx
│   └── BellDropdown.jsx
├── hq/ (9 screens)
├── field/ (9 screens)
├── governance/ (4 screens)
├── api/index.js (typed client)
├── icons.jsx (28 SVG đơn sắc)
└── styles/{global,login,hq,field}.css
```

## Câu hỏi cho BA/PMO (mục 43)

> **Cập nhật 2026-08-29**: Áp dụng quyết định tạm từ DEPLOYMENT_STACK.md mục 10. Mọi mục dưới có **implementation tạm**, đánh dấu `// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.x)`. Chờ sếp tổng xác nhận chính thức.

| # | Mục | Status | Implementation tạm | Chờ xác nhận |
|---|---|---|---|---|
| 1 | **43.1** Pilot projects | ⏳ Pending | CT2/HBG chỉ là source/test data | Cần chọn pilot thật |
| 2 | **43.2** Permission matrix | ⚠️ Tạm | 6 role + is_ceo flag, RBAC theo module × action | Ma trận Resource × Role × Action đầy đủ |
| 3 | **43.3** Shopdrawing state machine | ⚠️ Tạm | DRAFT→SUBMITTED→REVIEW→APPROVED + REJECTED→DRAFT, transition fields + audit | Approver role, revision loop, supersede |
| 4 | **43.4** Material Submittal | ⚠️ Tạm | Bảng mới, SLA + revision + rejection_reason bắt buộc | Multi-level approver, retention |
| 5 | **43.5** Payment transaction | ⚠️ Tạm | 3 bảng mới (contracts/invoices/payment_requests) + payments mở rộng | Approver chain, VAT %, retention release |
| 6 | **43.6** Notification channels | ⚠️ Tạm | Chỉ in_app hoạt động, các kênh khác `not_implemented` | Email/SMTP, Zalo OA, Telegram bot, push |
| 7 | **43.7** Offline conflict | ⚠️ Tạm | Last-write-wins theo timestamp + audit log | Vector clock, manual resolve UI |
| 8 | **43.8** Area hierarchy | ⚠️ Tạm | 6 cấp, 2 project + 19 zone mapped, building/floor/area NULL | Building/floor classification rules |
| 9 | **43.9** Planned quantity baseline | ⚠️ Tạm | Bảng schedule_baselines version + effective_date | Auto version trigger, cut-off rules |
| 10 | **43.10** KPI governance | ⚠️ Tạm | period_lock + approved_at, Q2 locked demo | Auto lock cron, override approver |

## Cách chạy

```bash
# Backend (port 3000)
cd /home/vutun/pmo_project/backend
node src/index.js

# Frontend (build → serve by backend)
cd /home/vutun/pmo_project/frontend
npm run build
# → truy cập http://localhost:3000

# PostgreSQL (optional, đã có 36+ tables migrated)
/home/linuxbrew/.linuxbrew/opt/postgresql@16/bin/pg_ctl -D /home/vutun/pgdata -l /tmp/pg.log start
```

## Demo accounts

Đã thêm 7 demo accounts (mục 43.2 — 6 role + admin). Passwords trong `backend/src/lib/auth.js#PASSWORDS`. Seed users bằng `node seed-users.mjs`.


## Bug fixes (2026-08-29 - sau 9 bug report)

| # | Bug | Status | File sửa | Phương pháp verify |
|---|---|---|---|---|
| **0** | Toast/Snackbar | ✅ FIXED | `components/Toast.jsx` (mới) + `App.jsx` | Component góc dưới trái, 3s auto-hide, success/error, click đóng |
| **1.1** | /hq/approval không dùng được | ✅ FIXED | `governance/Approval.jsx` (rewrite) + 6 endpoints mới | Approve/Reject → toast success; shop REVIEW 50 items hiện |
| **1.2** | /hq/master-data admin không vào | ✅ FIXED | `governance/MasterDataList.jsx` + 2 endpoints | Fixed auth header, added business-processes (8), workers |
| **1.3** | Schedule/Export buttons | ✅ FIXED | `hq/ProjectOverview.jsx` | Schedule → /hq/progress, Export → /api/export trả 200, file 293KB |
| **1.4** | Upload/Period/Custom range | ✅ FIXED | `hq/ControlCenter.jsx` | Upload modal wired, Period filter thực sự filter data, Custom range datepicker |
| **1.5** | Add material | ✅ FIXED | `hq/Materials.jsx` + POST endpoint | Modal form, validate material_code, toast success - id=244 |
| **1.6** | Add issue (đang nhầm thành 'add material') | ✅ FIXED | `hq/Issues.jsx` + POST endpoint | Modal form, severity/category selector, id=13 |
| **1.7** | Add milestone | ✅ FIXED | `hq/Payment.jsx` (rewrite toàn bộ) + POST endpoint | Modal chọn contract→invoice→request, retention+VAT+due_date, id=7 |
| **1.8** | Dark mode toggle | ✅ FIXED | `components/HqShell.jsx` + `global.css` | Icon sun/moon cạnh bell, localStorage lưu preference, CSS vars song song |

### Endpoints mới thêm (10):
- POST /api/projects/:id/materials (1.5)
- POST /api/projects/:id/issues (1.6)
- POST /api/invoices/:id/payment-requests (1.7)
- GET /api/shop-drawings/:id (1.1 detail)
- GET /api/material-submittals/:id (1.1 detail)
- POST /api/material-submittals/:id/approve (1.1)
- GET /api/projects/:id/material-submittals?status=X (1.1)
- GET /api/projects/:id/payment-requests?status=X (1.1)
- GET /api/payment-requests/:id (1.1 detail)
- PUT /api/payment-requests/:id (1.1 approve)

### Files mới:
- `frontend/src/components/Toast.jsx` (toast container, 70 dòng)

### Test kết quả:
- 7/7 demo accounts login OK
- 9/9 bugs fixed và E2E verified
- Build size: 363KB JS, 101KB gzip
- Backend ổn định ở port 3000


## Update 2026-08-30 (vòng 4: GitHub + Docker + UI fixes)

| # | Mục | Status | Ghi chú |
|---|---|---|---|
| 1 | GitHub push code | ✅ DONE | Repo: `TungLinhh/pmo-project`, commit 6091f50 |
| 2 | Dockerfile multi-stage | ✅ DONE | Test build syntax OK, docker chưa cài trong WSL |
| 3 | shop_drawing.js 27 vs 28 args | ✅ FIXED | Thêm 1 param resubmit_actual_date_2 |
| 4 | Upload Excel modal (browser test) | ✅ OK | Modal render, file input + Upload button OK |
| 5 | Approval Reject (browser test) | ✅ OK | POST /api/shop-drawings/:id/transition + toast |
| 5b | Approval View Details (browser test) | ✅ OK | Modal hiển thị JSON đầy đủ |
| 6 | Dark mode WCAG AA | ✅ FIXED | Text #d8dee9 (4.5:1 contrast), input/select border rõ |
| 7 | Table compact | ✅ FIXED | padding 5x8, tabular-nums, th nowrap |
| 8 | Cursor-tracking tooltip | ✅ FIXED | PieChart dùng mousemove, có animation fade |
| 9 | Manpower page thật | ✅ FIXED | 4 tab (Workers/Machinery/Teams/Suppliers) với data |
| 10 | Mở rộng test data | ✅ DONE | shop=50, schedule=100, materials=80, 2 file lỗi |
| 11 | Backup safety | ✅ DONE | pmo.db.backup-20260830-000409 (475KB) |
| 12 | Admin/CEO test | ✅ 114/114 | 38 endpoints × 3 projects × admin/CEO |

### Số liệu TEST-MASTER-01 project_id=3 (sau upload)
- shop_drawings: 51 (TST-A zone)
- construction_schedule_items: 100 (TST-B zone)
- materials: 80 (TST-C zone)
- subcontractors: 50 (tenant-level)
- suppliers: 30 (tenant-level)
- daily_reports: 1 (TEST 1.8.2026)
- rfa_log: 20 (TST-A/B/C/D)
- business_process_steps: 8 (project_execution)
- file_uploads: 11 (9 success, 2 intentional FAILED)

### Screenshots
Đã chụp vào `docs/bug_screenshots/`:
- upload-excel-01-control-center.png, 02-modal-open.png
- approval-01-approval-page.png, 02-view-detail-modal.png, 03-reject-modal.png
- dark-mode-01-light.png, 02-dark.png
- manpower-01-manpower.png
- verify-upload-modal-open.png, verify-upload-file-selected.png, verify-upload-after-submit.png
- verify-approval-view-modal.png, verify-approval-reject-modal.png, verify-approval-reject-filled.png
- verify-approval-reject-after.png

### Files mới
- `Dockerfile`, `docker-entrypoint.sh`, `.dockerignore`
- `frontend/src/components/CursorTooltip.jsx`
- `frontend/src/hq/Manpower.jsx` (real page, 4 tab)
- `scripts/ui-verify.mjs`, `scripts/ui-verify-deep.mjs` (Playwright UI test)
- `backend/scripts/init-schema.mjs`

### Known issues (chưa fix - low priority)
- 1 daily report có thể ingest nhưng sub-row chưa verify đếm từng loại (work_items/manpower/materials/acceptance)
- 2 file lỗi cố ý trong test fixtures (TĐ XYZ-BAD zone invalid, Shop EMPTY no data) - đây là tính năng test
- Reference sheets (547MB PDF gốc) không commit, dùng nội bộ


## Update 2026-08-30 vòng 5 (rate limit + backup verify + docker + daily report + README + data)

| # | Mục | Status | Ghi chú |
|---|---|---|---|
| 1 | Rate limit (express-rate-limit) | ✅ DONE | Login 5/min (skipSuccessfulRequests), API 100/min |
| 2 | Backup verify (pg_dump → pmo_backup_verify) | ✅ DONE | 44/44 bảng khớp 100%, 1120 rows match. File: `docs/backup_verification/backup_verification.md` |
| 3 | Docker build test | ⚠️ GIỚI HẠN | Không có Docker trong WSL (no sudo). Hướng dẫn trong `docs/docker_build_test_report.md` |
| 4 | Daily report sub-row verify | ✅ DONE + FIX | R27-R37 range + filter "Tổng cộng". 8 work_items/sheet (3 parents + 5 subs) khớp file gốc. Report: `docs/daily_report_verification.md` |
| 5 | README.md GitHub | ✅ DONE | 7 KB, đầy đủ quickstart + demo accounts + structure |
| 6 | Data TEST-MASTER-01 expansion | ✅ DONE | +contracts(12) +invoices(30) +payment_requests(31) +submittals(20) +issues(17) +notifications(63) +directives(9) +audit_log(131) +KPI(4) +file_uploads(5) |

### Test results
- **Rate limit**: 5 fail → 401, 6th → 429, success login không bị count (skipSuccessfulRequests ✓), 110 API calls: 90 OK + 20 limited
- **Backup verify**: 44 tables, 1120 rows khớp 100%, drop & recreate DB OK
- **Daily report**: HBG C20 file 2 sheets, 8 work_items + 16 manpower + 1 material + 11 acceptance per sheet
- **Pipeline test**: 9/11 file OK (2 intentional fail)

### Files mới/sửa vòng 5
- `backend/src/index.js` (+rate-limit imports + middlewares)
- `backend/package.json` (+express-rate-limit)
- `backend/src/services/ingest/daily_report.js` (R27-R37 + "Tổng cộng" filter)
- `backend/scripts/seed-test-master-business.mjs` (mới, 230 dòng)
- `docs/backup_verification/backup_verification.md`
- `docs/backup_verification/backup_test_20260830-004948.sql` (289KB)
- `docs/backup_verification/backup_test_20260830-004948.sql.dump` (171KB)
- `docs/daily_report_verification.md`
- `docs/docker_build_test_report.md`
- `README.md` (7KB, GitHub-ready)


## Update 2026-08-30 vòng 6 (mobile nav + permission matrix + tooltip + dark mode audit)

| # | Mục | Status | Ghi chú |
|---|---|---|---|
| 1 | Mobile nav (hamburger + drawer) | ✅ DONE | <768px ẩn sidebar, hamburger mở drawer 280px, click outside đóng. Verified bằng Playwright viewport 375×667 |
| 2 | Permission matrix (6 role) | ✅ DONE | `lib/permissions.js` + middleware. Test: 130/130 PASS (admin/CEO full, PM limited, etc). Endpoint /api/me/permissions return full matrix |
| 3 | Tooltip 4 pillars | ✅ FIXED | Xóa duplicate `<PieTooltip>` ở 4 cards, dùng PieChart built-in (onMouseMove + fixed positioning, offset 18px). Verified tooltip offset 21-30px lệch khỏi path |
| 4 | Dark mode audit | ✅ DONE | Override 30+ selectors dark mode: badges, table cells, modal headers, inputs, kpi cards, status chips, sidebar menu, page header, code, etc. Add 7 missing CSS vars (c-draft-bg, c-approved, c-rejected, c-overdue + bg). Screenshot 13/13 pages ở dark mode audit folder |
| 5 | Compact pillar layout | ✅ DONE | padding 10x12, font 12.5px, gap 6px, min-height 200px |

### Files mới
- `backend/src/lib/permissions.js` (matrix 6 role × 14 module)
- `backend/src/lib/permission-middleware.js` (block 403 based on role+module+action)
- `scripts/test-role-permissions.mjs` (130 tests)
- `scripts/ui-verify-v6.mjs`, `ui-verify-v6-quick.mjs`, `ui-verify-tooltip.mjs`

### Files sửa
- `backend/src/index.js` (+ permissionMiddleware, /me/permissions dùng matrix)
- `backend/src/lib/auth.js` (no change)
- `frontend/src/components/HqShell.jsx` (+hamburger, drawer state)
- `frontend/src/components/PieChart.jsx` (offset 18px, fixed positioning)
- `frontend/src/hq/ControlCenter.jsx` (xóa PieTooltip riêng ở 4 pillars)
- `frontend/src/styles/global.css` (compact pillar + dark mode audit overrides)
- `frontend/src/styles/hq.css` (mobile media query <768px)
- `frontend/src/icons.jsx` (menu + close icons)

### Screenshots (docs/bug_screenshots/)
- v6-mobile-{01,02,03,04}-*.png (mobile nav)
- v6-tooltip-pie{1,2,3,4}.png (tooltip verify)
- dark-mode-audit/{login, control-center, projects, progress, shop, materials, manpower, payment, issues, notifications, master-data, approval, audit}.png (13 dark mode pages)

## Update 2026-08-30 vòng 8 (ingest fixes + zone aliases + multi-zone)

| # | Mục | Status | Ghi chú |
|---|-----|--------|---------|
| 1 | Test ingest 29 zone files từ HBG-HBC-BCTT gốc | ✅ | 29/29 SUCCESS (8 files failed trước fix) |
| 2 | Fix zone_matcher: dùng findZoneByName thay hard-coded regex | ✅ | Aliases: CUL, BEACH ZONE, FITNES, LOBY → CLU/BZONE/GEN/LOB-SPA |
| 3 | Fix detectDocType: payment_progress check trước "tiến độ" | ✅ | "Tiến độ thanh toán" giờ detect đúng |
| 4 | Multi-zone rollup files: route to ingestProjectLevelFile | ✅ | 80 rows ingested từ 16 zones |
| 5 | Fix project_level.js: detect ordinal bằng Roman numerals, skip numeric-only names | ✅ | Trước: chỉ insert 2 rows do `name="0.25"` |
| 6 | gitignore backend/uploads/ | ✅ | Cleanup test artifacts |
| 7 | 2 commits pushed lên GitHub | ✅ | `4e817d3` (ingest) + `26872ac` (UI fixes) |

### Test results
- **Trước fix**: 21/29 zone files SUCCESS, 8 FAILED
- **Sau fix**: 29/29 SUCCESS
- **Multi-zone rollup "Tiến độ thi công tổng thể"**:
  - Trước: 2 rows (do bug parse cột)
  - Sau: 80 rows / 16 zones (5 rows/zone) ✅

### 3 multi-zone files status
- `Tiến độ thi công tổng thể các khu vực.xlsx`: 16 sheets, 80 rows OK ✅
- `Tiến độ vật tư tổng thể các khu vực.xlsx`: 1 sheet "Sơ đồ tổng thể vật tư" - placeholder, 0 rows
- `Tiến độ hạng mục.xlsx`: 1 sheet "TĐHM" - placeholder, 0 rows
</content>
