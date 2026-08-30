# PMO MVP — Demo Script

> Kịch bản 10 phút để demo toàn bộ MVP. Người demo chỉ cần click theo thứ tự, không cần nhớ flow.

## Trước khi demo (5 phút setup)

```bash
# 1. Khởi động PostgreSQL (nếu chưa chạy)
/home/linuxbrew/.linuxbrew/opt/postgresql@16/bin/pg_ctl -D /home/vutun/pgdata -l /tmp/pg.log start

# 2. Khởi động backend (terminal 1)
cd /home/vutun/pmo_project/backend
node src/index.js
# → http://localhost:3000

# 3. Mở browser → http://localhost:3000
```

## Tài khoản demo (7 accounts, 6 roles + admin)

| Email | Password | Role | Làm gì |
|---|---|---|---|
| `admin@hbg.com` | `admin123` | Admin (PMO full) | Toàn quyền, dùng cho dev/test |
| `ceo@hbg.com` | `ceo123` | **CEO** | Ra chỉ thị cho issue, xem tất cả project |
| `pm@hbg.com` | `pm123` | PM | Quản lý dự án, transition shop drawing |
| `pmo@hbg.com` | `pmo123` | PMO | Vận hành + governance, master data + approval |
| `site@hbg.com` | `site123` | **Site** | Hiện trường, chỉ ghi daily report |
| `procurement@hbg.com` | `proc123` | Procurement | Mua vật tư, tạo material submittal |
| `accounting@hbg.com` | `acc123` | Accounting | Thanh toán, payment request |

> 💡 Trên màn hình login, **click chip "CEO", "PM", "Site"...** để auto-fill email + password, không cần gõ.

## Kịch bản 10 phút

### Phase 1 — Login & Khám phá (2 phút, role: Admin)

1. Mở `http://localhost:3000` → màn hình login
2. Click chip **"PMO (Admin)"** → click **ĐĂNG NHẬP**
3. **Project Control Center** hiện ra:
   - 2 dự án: BTE-WP4-HBC, LAWRENCE-STING-2
   - 4 pillar cards: Material / Shop / Progress / Payment — mỗi cái có **pie chart**
   - Hover vào từng lát pie → tooltip breakdown chi tiết

### Phase 2 — Phân quyền (1 phút, role: Site vs Admin)

4. **Logout** (click avatar góc trên phải) → Login lại bằng **`site@hbg.com`** / `site123`
5. Sidebar **chỉ có Field**, không có Project Control Center
6. Vào `/hq` → **bị chặn** (Site không có quyền truy cập HQ)
7. Logout → Login lại bằng **`ceo@hbg.com`** / `ceo123`
8. Sidebar có **tất cả modules** + có chỉ thị CEO

### Phase 3 — CEO ra chỉ thị (1 phút, role: CEO)

9. Vào **Issues** (sidebar) → click issue **"Fire system chậm 6%"**
10. Trong Issue Detail, scroll xuống phần **"Chỉ thị từ CEO"**
11. Gõ vào ô textarea: `Ưu tiên vendor X, họp lại tuần sau`
12. Click **Gửi chỉ thị**
13. Notification bell (góc trên phải) tăng count từ X → X+1
14. Bell dropdown hiển thị notification mới → **click** → navigate về Issue Detail

### Phase 4 — PM transition Shop Drawing (2 phút, role: PM)

15. Logout → Login bằng **`pm@hbg.com`** / `pm123`
16. Vào **BTE-WP4-HBC** → **Shop Drawings** → filter status = REVIEW (50 records)
17. Click 1 shop drawing → modal/panel hiện ra với các nút:
    - **APPROVE** → status chuyển REVIEW → APPROVED
    - **REJECT** → nhập lý do "Thiếu dimension" → status REVIEW → REJECTED
    - **REVERT TO DRAFT** → chỉ enable khi status = REJECTED → chuyển về DRAFT
18. Audit log ghi nhận mỗi transition (CEO có thể check)

### Phase 5 — Procurement reject Material (1 phút, role: Procurement)

19. Logout → Login bằng **`procurement@hbg.com`** / `proc123`
20. Vào **BTE-WP4-HBC** → **Materials** → tab **Submittals**
21. Click submittal MEP-PLB-001 → **Reject** → nhập lý do "Không đạt chất lượng"
22. Submittal status: SUBMITTED → REJECTED, sla_deadline vẫn giữ
23. Có thể tạo revision: bấm **Create Revision** → submittal mới với `revision_number = 1`

### Phase 6 — Payment + KPI (2 phút, role: Accounting)

24. Logout → Login bằng **`accounting@hbg.com`** / `acc123`
25. Vào **BTE-WP4-HBC** → **Payments**:
    - 3 contracts: CT-2026-001 (MEP BOH), CT-2026-002 (BPV-1BR), CT-2026-003 (RES-3BR)
    - Mỗi contract có 2 invoices, mỗi invoice 1 payment request
    - **Retention 5%** + **VAT** + **Due date** hiển thị rõ
26. Click **APPROVE** payment request → status PENDING → APPROVED

27. Vào **Master Data** → **KPI Targets**:
    - 4 KPIs: Progress%, Shop Approved%, Material OTD, Safety
    - **Q2 2026 KPI "Material OTD"** có badge `🔒 LOCKED` — bấm Edit → backend trả 423 (không sửa được)
    - Q3 KPIs vẫn edit được

### Phase 7 — Field (1 phút, role: Site)

28. Logout → Login bằng **`site@hbg.com`** / `site123`
29. Auto redirect về `/field`
30. **Field Home** → danh sách 9 màn hình PWA
31. Tap **Daily Progress** → ghi nhận hôm nay: weather, manpower, materials
32. Tap **Sync** → thấy offline queue, network status, conflicts log

### Phase 8 — Audit (30 giây, role: PMO)

33. Logout → Login bằng **`pmo@hbg.com`** / `pmo123`
34. Vào **Governance** → **Audit Log**
35. Mỗi action trong demo (CEO directive, PM transition, Procurement reject, Accounting approve) đều xuất hiện ở đây với timestamp + user

## Demo data có sẵn

| Bảng | Số records | Mô tả |
|---|---|---|
| projects | 2 | BTE-WP4-HBC, LAWRENCE-STING-2 |
| zones | 19 | BOH, BPV, BSN, BUT, BZONE, CLU, GEN, HPV, INF, KID, LOB-SPA, RES, RES-3BR, RES-4BR, VNR, ... |
| shop_drawings | 102 | 50 REVIEW, 52 DRAFT |
| construction_schedule_items | 521 | 121 zone BOH, 113 BPV, ... |
| materials | 242 | Theo 19 zones |
| subcontractors | 41 | Master data |
| suppliers | 2 | Master data |
| business_process_steps | 8 | BP1-BP8 |
| daily_reports | 2 | 23.5.2021 + 24.5.2021 |
| daily_work_items | 12 | |
| daily_manpower | 32 | |
| daily_acceptance | 22 | |
| **issues** | 12 | Demo |
| **notifications** | 15 | Demo (5 unread) |
| **directives** | 4 | Demo CEO directives |
| **audit_log** | 5+ | Tăng theo mỗi action |
| **material_submittals** | 2 | MEP-PLB-001 (SUBMITTED), STR-CEM-002 (DRAFT) |
| **area_hierarchy** | 21 | 2 projects + 19 zones |
| **schedule_baselines** | 1 | v1, 2026-08-01 |
| **contracts** | 3 | CT-2026-001, 002, 003 |
| **invoices** | 6 | 2 invoices/contract |
| **payment_requests** | 6 | 1 request/invoice, retention 5% |
| **kpi_targets** | 4 | 3 Q3 (unlocked) + 1 Q2 (locked) |
| **offline_sync_queue** | 2 | Demo conflict resolution |

## File log quan trọng

- Backend log: `/tmp/backend.log`
- PostgreSQL log: `/tmp/pg.log`
- DB SQLite: `/home/vutun/pmo_project/backend/data/pmo.db`
- DB PG: `postgresql://pmo_user:pmo_pass@localhost:5432/pmo`

## Phím tắt nhanh

| Phím | Tác dụng |
|---|---|
| `Ctrl+L` | Focus vào URL bar |
| `Cmd+R` / `F5` | Reload page |
| `F12` | Open DevTools (check Network tab) |
| `Cmd+Shift+R` | Hard reload (clear cache) |
