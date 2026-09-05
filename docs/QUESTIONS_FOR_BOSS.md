# Câu hỏi cho sếp tổng — PMO MVP

> **Người soạn**: PMO team · **Ngày**: 2026-09-04
> **Mục đích**: Chốt các quyết định nghiệp vụ còn để TODO (mục 43.x + nhóm 2 trong SRS §11)
> **Cách dùng**: Sếp trả lời từng câu, team chốt vào codebase, đóng các TODO mục 43.x.

---

## 📋 Trạng thái đã chốt (2026-09-04)

| Mục | Câu hỏi | Đã chốt |
|---|---|---|
| 43.9 | Planned quantity baseline versioning | ✅ Có history, không compare |
| 43.10 | KPI targets governance | ✅ CEO + PM sửa, không period lock, có history (versioning) |
| 43.6 | Notification channels | ✅ in_app (luôn) + email (nếu config) + Zalo (nếu OA) |
| 43.3 | Shop REJECTED state | ✅ Cho phép PM sửa + re-submit, không tạo mới |
| 43.2 | User role enum | ✅ CEO dùng `pmo + is_ceo=true` (code đã có) |
| 43.4 | Material submittal workflow | ✅ Đã có DRAFT/SUBMITTED/REJECTED, SLA auto-compute |
| 43.5 | Payment chain | ✅ 4 bảng (contracts → invoices → payment_requests → payments) |
| 43.7 | Offline sync | ✅ Last-write-wins theo timestamp |
| 43.8 | Area hierarchy | ✅ Tạm 4 cấp (project → zone → sub-area → work-item) |
| Daily report C41-C42 | Cột 0.7→1.0 | ✅ Bỏ qua, không map |
| Zone naming | Quy ước đặt tên | ✅ Sếp + PMO tự quyết (không cố định) |
| Project archive | Hết hạn / closed | ✅ CEO mark closed, có revoke, mặc định ẩn khỏi list |

---

## ❓ Câu hỏi còn cần sếp trả lời (12 câu)

### A. Workflow nghiệp vụ

**A1. Workflow approval shop drawing (mục 6.2)**
- Hiện tại: `DRAFT → SUBMITTED → REVIEW → APPROVED/REJECTED`
- Câu hỏi: Có bao nhiêu cấp duyệt? (Hiện có 4 mốc BQL L1-L4)
- Cấp nào có quyền APPROVE cuối cùng?
- Có cần CEO ký duyệt cuối (final sign-off) hay BQL đủ?
- Nếu BQL từ chối (REJECTED), PM sửa và re-submit — đã chốt OK. Nhưng có cần escalation nếu BQL không phản hồi trong X ngày?

**A2. RFA (Request For Approval)**
- Form gồm những field gì? (Hiện tại: code, status, sla_days, sla_deadline, revision_number, parent_id)
- Ai được quyền raise RFA? (PM? Site engineer? Subcontractor?)
- Có template RFA chuẩn của HBG không? (xlsx/pdf form mẫu)

**A3. Material rating (mục 7.4)**
- `P` trong rating NCC (nhà cung cấp) là gì? (Pass / Pending / Premium?)
- Mapping `P/F` (Pass/Fail) — đã confirm. Nhưng `GOOD/MEDIUM/BAD` cho warranty, `HIGH/MEDIUM/LOW` cho price — chuẩn nào?
- Có bao nhiêu tiêu chí đánh giá NCC?

### B. Báo cáo & Export

**B1. Báo cáo cần export ra Excel**
- Báo cáo nào cần export? (Daily progress, weekly summary, monthly KPI, payment request?)
- Format: `.xlsx` đã có. Có cần `.pdf` không? Template có sẵn?
- Tần suất export: tuần / tháng / quý / ad-hoc?

**B2. KPI calculation (mục 9.6)**
- OTD (On-Time Delivery) tính thế nào?
  - Option A: `Số mốc hoàn thành đúng hạn / Tổng số mốc`
  - Option B: Tính theo `actual_date ≤ planned_date` của từng item
- % hoàn thành trung bình = trung bình cộng % của tất cả item? Hay weighted theo planned_qty?
- Threshold đạt/không đạt KPI là bao nhiêu? (≥80% xanh, 50-80% vàng, <50% đỏ?)

### C. Master Data & Tích hợp

**C1. Subcontractor / Supplier / Resource / Worker**
- Mỗi bảng cần bao nhiêu trường? (Hiện có: name, system, category, contact, status)
- Có tích hợp với HR system không? (mã nhân viên, hợp đồng lao động)
- Tích hợp với Accounting? (mã NCC, MST, tài khoản ngân hàng)

**C2. Manpower tracking**
- Theo dõi theo ngày / tuần / tháng?
- Cross-project hay chỉ trong 1 project?
- Có dùng để tính lương không? (nếu có → cần link với HR)

**C3. Machinery tracking**
- Sếp bảo "còn tùy". Câu hỏi cụ thể: tracking theo ca / theo ngày / theo dự án?
- Có cần maintenance schedule không? (bảo dưỡng định kỳ)

### D. Bảo mật & Tuân thủ

**D1. Audit log retention**
- Giữ audit log bao lâu? (1 năm / 3 năm / vĩnh viễn?)
- Có cần archive sang cold storage (S3 Glacier) sau X năm không?

**D2. Multi-tenant**
- Có khách hàng thuê hệ thống không? (multi-tenant ready nhưng chỉ 1 tenant hiện tại)
- Nếu có → cần chứng nhận gì? (SOC2, ISO 27001?)

### E. Triển khai & Vận hành

**E1. Cloud deploy (mục SETUP_FOR_CLIENT.md)**
- Dùng Cloudflare Tunnel hay direct domain?
- Domain chính thức: `pmo.hbg.com`? Có SSL chứng chỉ riêng?
- Backup tự động: mỗi ngày / tuần? Giữ bao lâu?

**E2. Mobile native (sẽ làm ở v2)**
- Có cần mobile app (iOS/Android) hay chỉ web responsive đủ?

**E3. Training & onboarding**
- Sếp muốn tổ chức training cho 7 users khi nào?
- Có cần viết user guide PDF/Word không?

---

## 🎯 Đề xuất thứ tự trả lời

| Ưu tiên | Câu hỏi | Lý do |
|---|---|---|
| 🥇 Critical | A1, A2, B1, B2 | Cốt lõi nghiệp vụ, chặn workflow |
| 🥈 High | A3, C1, E1 | Quan trọng cho data quality + deploy |
| 🥉 Medium | C2, C3, D1, E2 | Có thể làm sau |
| ❓ Low | D2, E3 | Strategic, không gấp |

---

## 📝 Ghi chú

- File này tạo ngày 2026-09-04 từ session phân tích TODO + user request
- Khi sếp trả lời, PMO team sẽ update file `docs/CHECKLIST.md` mục 43.x tương ứng
- Câu nào sếp không trả lời → giữ TODO, code chạy với default hiện tại

**Người gửi**: PMO team · **Kính gửi**: Sếp tổng · **Hạn trả lời đề xuất**: 2026-09-15
