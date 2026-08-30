# PMO MVP - Demo Script

> Hướng dẫn demo từng bước cho stakeholder. Mỗi bước có: (1) mục đích, (2) thao tác, (3) kỳ vọng kết quả, (4) account dùng.

## Chuẩn bị

### Tech stack
- Frontend: Vite + React, port 5173 (dev) hoặc built `dist/`
- Backend: Node + Express, port 3000
- DB: SQLite (mặc định) tại `backend/data/pmo.db` HOẶC PostgreSQL 16 (production)

### Khởi động
```bash
# Terminal 1 - Backend
cd backend && npm run dev
# → http://localhost:3000/api/health = 200

# Terminal 2 - Frontend
cd frontend && npm run dev
# → http://localhost:5173
```

### 7 tài khoản demo (đã seed sẵn)
| Email | Password | Role | Phạm vi |
|---|---|---|---|
| `admin@hbg.com` | `admin123` | ADMIN | Full access mọi project |
| `ceo@hbg.com` | `ceo123` | CEO | Toàn bộ (chỉ write Directive) |
| `pm@hbg.com` | `pm123` | PM | Project mình quản lý |
| `pmo@hbg.com` | `pmo123` | PMO | Master data + KPI, mọi project (read) |
| `site@hbg.com` | `site123` | SITE | Project/zone được gán (write daily progress/issue) |
| `procurement@hbg.com` | `proc123` | PROCUREMENT | Material + Supplier, mọi project |
| `accounting@hbg.com` | `acc123` | ACCOUNTING | Contract + Invoice + Payment |

### 3 project
- `HBG-HBC-BCTT` (id=1) - dữ liệu lớn nhất (521 schedule items, 102 shop drawings)
- `LAWRENCE-STING-2` (id=2) - C20 project từ Excel gốc
- `TEST-MASTER-01` (id=3) - **khuyến nghị demo chính** (đầy đủ 9 ingestor + business data + CEO directive)

## Demo flow 30 phút

### 1. Login + Permission (3 phút) ⭐
1. Mở `http://localhost:5173/login`
2. Login bằng `admin@hbg.com` / `admin123` → vào `/hq` (Control Center)
3. Logout, login lại bằng `site@hbg.com` / `site123` → sidebar bị ẩn các menu không có quyền (Contracts, KPI, Master Data)
4. **Kỳ vọng**: UI khác nhau theo role. Thử click vào route bị ẩn (vd `/hq/approval` khi là SITE) → 403 hoặc redirect.

### 2. Control Center - 4 Pillar Dashboard (5 phút) ⭐
1. Ở `/hq`, chọn project `TEST-MASTER-01` (id=3) từ dropdown
2. Xem 4 pillar cards:
   - **Construction Progress**: pie chart 50% completion (50/100 done), có overdue
   - **Shopdrawing**: pie chart ~10% approved (5/51), có 5 status phân tán
   - **Material**: 84 items, có critical/delayed
   - **Payment**: pie chart 18% paid (2/11)
3. Hover vào từng pie chart → tooltip hiện chi tiết (offset 18px, không đè chữ)
4. **Detail navigation**: click vào pillar card → mở `/hq/progress?project_id=3` (đúng project)
5. **Kỳ vọng**: Pie % hiển thị đúng, URL có `?project_id=3`, không lẫn project khác

### 3. Project Detail (3 phút)
1. Ở `/hq/projects/3` - xem Project Overview
2. Có KPI targets (mix period_lock), area hierarchy (Building → Floor → Area)
3. Click vào KPI target có period_lock=true → không edit được (locked)

### 4. Construction Progress Detail (4 phút) ⭐
1. Ở `/hq/progress?project_id=3`
2. Filter theo zone, status, search
3. Thử export Excel → file `construction-schedule-3.xlsx` tải về
4. Verify % trong dashboard khớp với số items done ở đây (50/100)

### 5. Shop Drawing (4 phút) ⭐
1. Ở `/hq/shop?project_id=3`
2. 51 records với 5 status: DRAFT, SUBMITTED, REVIEW, APPROVED, REJECTED
3. Click "View detail" → modal với đầy đủ thông tin
4. Có 5 REJECTED với `rejection_reason`
5. Click vào drawing ở status SUBMITTED → transition sang REVIEW (nếu có quyền PM)

### 6. Material Submittal (3 phút)
1. Ở `/hq/materials?project_id=3`
2. 91 submittals (30 từ ingest + business seed)
3. Có `revision_number > 1`, có `sla_deadline` overdue (badge đỏ ⚠️)
4. Filter status, overdue

### 7. Manpower (2 phút)
1. Ở `/hq/manpower?project_id=3`
2. 41 teams với positions
3. Demo tổng hợp theo zone

### 8. Payment (3 phút) ⭐
1. Ở `/hq/payment?project_id=3`
2. 31 payment requests + 11 payment milestones
3. **Demo RETENTION ≠ 0** (nếu có record), **VAT ≠ 0**
4. Có OVERDUE (due_date quá hạn)
5. Status phân tán: PLANNED, SUBMITTED, APPROVED, PAID, OVERDUE

### 9. Issues + CEO Directive (4 phút) ⭐⭐
1. Ở `/hq/issues?project_id=3`
2. 28 issues với 4 severity (CRITICAL/HIGH/MEDIUM/LOW)
3. **3 issues ESCALATED** + 1 CEO directive
4. Click vào issue ESCALATED → xem CEO directive text
5. Tạo issue mới với severity=CRITICAL → toast confirm "Tạo thành công"

### 10. Approval Center (4 phút) ⭐⭐⭐
1. Ở `/hq/approval` (cần quyền PM/PMO/CEO)
2. 3 sections: Shop (REVIEW), Material (SUBMITTED), Payment (PENDING)
3. **Click "View Details"** → **inline expand** ngay dưới dòng (KHÔNG phải modal)
4. **Click "Approve"** → **confirm modal** "Bạn có chắc chắn muốn DUYỆT shop drawing #N?"
5. Confirm → toast success, item biến mất khỏi list
6. **Click "Reject"** → modal lý do (bắt buộc) → confirm
7. **Verify**: Reject từ inline detail gọi CÙNG API với Reject ở list (check audit log)

### 11. Mobile portrait (2 phút) ⭐
1. Resize browser xuống 375×812
2. Sidebar biến mất → thay bằng nút hamburger ở góc trên trái
3. Click hamburger → drawer 280px trượt vào
4. Click ra ngoài hoặc chọn menu → tự đóng
5. Content full-width, không còn tính theo sidebar
6. Thử ở `/hq/payment`, `/hq/shop`, `/hq/issues` → tables compact, kpi 2 cols

### 12. Dark mode (2 phút)
1. Click nút theme ở header → toggle dark
2. Toàn bộ 20 màn hình đã audit:
   - Table headers/cells dùng `var(--c-surface)`
   - Status chips có màu dark-mode-compatible
   - Modal inputs có border dark
   - 13/13 pages screenshotted tại `docs/bug_screenshots/dark-mode-audit/`

### 13. Audit Log + Notifications (2 phút)
1. Ở `/hq/audit` → xem 131 audit log entries (login, transitions, etc.)
2. Ở `/hq/notifications` → 89 notifications (critical/warning/info)
3. Click "Mark all read" → toast confirm

### 14. Upload Excel (3 phút)
1. Ở `/hq`, click "Upload Excel"
2. Upload `Báo cáo công việc C20 ngày 23.5.2021.xlsx` (file mẫu trong `Downloads/PMO_project_reference_sheets/`)
3. Verify: 8 work_items (3 parents + 5 subs) + 16 manpower + 1 material + 11 acceptance / sheet
4. Hiện ở list daily reports ngay

## Highlights kỹ thuật (nếu stakeholder hỏi)

- **Rate limit**: 5 login/min, 100 API/min/IP - test tại `backend/scripts/test-rate-limit.mjs`
- **Backup/Restore**: `pg_dump` → restore → verify 44/44 tables match (xem `docs/backup_verification/`)
- **Permission matrix**: 6 role × 14 module × 3 action, 130/130 test pass (xem `backend/scripts/test-role-permissions.mjs`)
- **Demo data**: 9 ingestor scripts + enrichment script - `backend/scripts/seed-*.mjs` + `seed-demo-data-enrich.mjs`
- **GitHub**: 3 commits (`6091f50`, `ba53873`, `0a874de`) - tất cả test pass

## Test accounts matrix (kỹ thuật)

| Role | Đọc | Ghi/Sửa | Duyệt |
|---|---|---|---|
| PM | Toàn bộ module, project mình quản lý | Schedule, Issue, Daily progress | Shop drawing, Material submittal |
| PMO | Toàn bộ, mọi project | KPI target, Master data | Không duyệt nghiệp vụ |
| Site | Project/zone được gán | Daily progress, Material, Issue, Photo | Không |
| Procurement | Material, Supplier, Subcontractor | Material submittal, Supplier, Subcontractor | Không |
| Accounting | Contract, Invoice, Payment | Contract, Invoice, Payment request | Không |
| CEO | Toàn bộ | Chỉ Directive | Có thể duyệt cấp cao |

> `// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.2)` ở mỗi quyết định - matrix là TẠM.

## Files quan trọng
- `README.md` - quick start, tech stack
- `CHECKLIST.md` - tracking tất cả vòng (v0 → v7)
- `docs/backup_verification/` - backup/restore test
- `docs/daily_report_verification.md` - parser verify với HBG C20
- `docs/docker_build_test_report.md` - Docker limitations
- `docs/bug_screenshots/v6-*` - mobile/tooltip/dark mode
- `docs/bug_screenshots/dark-mode-audit/` - 13 dark mode screens
- `backend/scripts/test-role-permissions.mjs` - permission test 130 cases
- `backend/scripts/test-admin-full-access.mjs` - admin full access test
