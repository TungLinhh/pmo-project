# PMO MVP - User Guide

> Hướng dẫn sử dụng cho end-user (PM, PMO, CEO, Site, Procurement, Accounting).

**Phiên bản:** 2026-08-31
**Đối tượng:** Người dùng cuối (không cần biết kỹ thuật)

---

## 🚀 Bắt đầu nhanh

### 1. Truy cập

Mở browser (Chrome/Edge/Firefox/Safari), gõ:
```
https://pmo.your-company.com
```
(URL cụ thể sẽ do admin cung cấp)

### 2. Đăng nhập

Nhập email + mật khẩu được admin cấp.

**Các role và quyền:**

| Role | Truy cập | Chức năng chính |
|---|---|---|
| **Admin** | `/hq` | Tất cả: cấu hình, quản lý user, xem báo cáo |
| **CEO** | `/hq` | Dashboard, directive, phê duyệt cấp cao |
| **PM** (Project Manager) | `/hq` | Quản lý dự án, upload file, theo dõi tiến độ |
| **PMO** | `/hq` | Theo dõi portfolio, audit, master data |
| **Site** | `/field` | Báo cáo công việc hàng ngày (mobile) |
| **Procurement** | `/hq` | Vật tư, mua hàng, supplier |
| **Accounting** | `/hq` | Hợp đồng, hóa đơn, thanh toán |

### 3. Giao diện chính

**HQ Dashboard (PM/PMO/CEO/Admin):**
- **Top bar:** Logo, project selector, user menu, notification bell
- **Sidebar (trái):** Menu điều hướng
- **Main area:** Nội dung trang hiện tại

**Field App (Site, mobile):**
- **Top bar:** Project, weather, sync status
- **Main area:** Form báo cáo
- **Bottom tabs:** Home / Daily / Manpower / Shop / Photo / Review

---

## 📊 HQ Dashboard - Các màn hình chính

### 1. Control Center (Trang chủ)

4 cards tổng quan dự án:
- **Construction:** Tiến độ thi công (% hoàn thành)
- **Shop Drawing:** % shop drawing đã duyệt
- **Material:** Số lượng vật tư + submittals
- **Payment:** Thanh toán + retention

**Pie chart:** Hover để xem chi tiết từng category. Click vào card để xem chi tiết.

**Project selector (góc trên trái):** Chọn dự án để xem data của dự án đó.

### 2. Project Overview

- **Danh sách dự án:** Card view, mỗi dự án 1 card
- **Status badge:** Đang chạy / Tạm dừng / Hoàn thành
- **Click vào card:** Mở chi tiết dự án

### 3. Construction Progress (Tiến độ thi công)

**Bảng:**
- Cột: Zone | Level | Item | Plan start | Plan end | Actual start | Actual end | Progress % | Status
- **Filter:** Zone, status, date range
- **Sort:** Click vào header

**Chi tiết item:**
- Click vào 1 dòng → expand inline (xem full description, comments, photos)
- Có thể edit % tiến độ (nếu có quyền)

**Export:** Nút "Export Excel" góc trên phải → tải file .xlsx

### 4. Shop Drawing (Bản vẽ thiết kế)

**5 trạng thái:**
- `DRAFT` (xám) - PM mới tạo
- `SUBMITTED` (xanh dương) - Gửi BQL duyệt
- `REVIEW` (vàng) - Đang xem xét
- `APPROVED` (xanh lá) - Đã duyệt
- `REJECTED` (đỏ) - Bị từ chối, cần sửa

**Filter:** Status, zone

**Action (theo quyền):**
- Submit (DRAFT → SUBMITTED)
- Review (SUBMITTED → REVIEW)
- Approve (REVIEW → APPROVED)
- Reject (REVIEW → REJECTED) - kèm lý do
- Resubmit (REJECTED → DRAFT)

### 5. Materials (Vật tư)

**2 tab:**
- **Materials:** Danh sách vật tư (code, tên, zone, progress, ngày yêu cầu)
- **Submittals:** Vật tư chờ duyệt (5-state workflow)

**Submittal workflow:** DRAFT → PENDING → SUBMITTED → APPROVED/REJECTED

**Overdue:** Submittal có `sla_deadline` quá khứ và chưa approve → badge đỏ "OVERDUE"

### 6. Payment (Thanh toán)

**4 tab:**
- **Contracts:** Hợp đồng với nhà thầu
- **Invoices:** Hóa đơn theo hợp đồng
- **Payment Requests:** Yêu cầu thanh toán (workflow PLANNED → SUBMITTED → APPROVED → PAID)
- **Milestones:** Các mốc thanh toán của dự án

**Retention:** Phần giữ lại (thường 5-10%) - hiển thị riêng

**VAT:** Thuế VAT - hiển thị riêng

**Due date:** Màu đỏ nếu quá hạn (status=SUBMITTED và due_date < today)

### 7. Manpower (Nhân lực)

- Danh sách team + workers
- Phân bổ theo zone
- Tổng giờ OT, đi muộn, vắng
- Số ngày công theo tuần/tháng

### 8. Issues (Vấn đề)

**4 severity:**
- `CRITICAL` (đỏ) - Cần xử lý ngay
- `HIGH` (cam)
- `MEDIUM` (vàng)
- `LOW` (xanh)

**Status:** OPEN → IN_PROGRESS → RESOLVED → CLOSED (hoặc ESCALATED)

**CEO Directive:** Issue được CEO gắn "directive" → ưu tiên cao nhất

### 9. KPI Target

- Bảng KPI: code, name, target, actual, unit, period
- **Period lock:** KPI đã khóa kỳ → không edit được actual
- **Progress:** Thanh progress bar (actual/target)

### 10. Notification Center

- Danh sách thông báo
- 3 severity: critical (đỏ), warning (vàng), info (xanh)
- **Mark as read:** Click vào thông báo
- **Mark all read:** Nút góc trên
- **Bell badge:** Số thông báo chưa đọc

---

## ✅ Approval Workflow

### Duyệt bản vẽ (Shop Drawing)

1. Vào `/hq/approval` hoặc click bell → notification
2. Xem danh sách pending (chờ duyệt)
3. Click "View Details" → expand inline (xem full bản vẽ)
4. **Approve:**
   - Click "Approve"
   - Confirm modal: "Bạn có chắc chắn muốn DUYỆT?"
   - Click "Đồng ý" → Toast "Đã duyệt"
5. **Reject:**
   - Click "Reject"
   - Nhập lý do (bắt buộc)
   - Click "Từ chối" → Toast "Đã từ chối"
6. List tự động refresh, item biến mất

### Duyệt Material Submittal

Tương tự shop drawing, workflow: DRAFT → PENDING → SUBMITTED → APPROVED/REJECTED

### Duyệt Payment Request

1. PM/Accountant tạo payment request
2. Approver nhận notification
3. Approve → trigger thanh toán (status → APPROVED)
4. Accountant đánh dấu PAID sau khi chuyển khoản

---

## 📱 Field App (Site Engineer)

### Daily Progress Report

1. Mở app trên điện thoại
2. Tab "Daily" → chọn ngày
3. **Work items:** Thêm công việc trong ngày (parent + children)
4. **Manpower:** Ghi số lượng thợ theo team
5. **Materials:** Vật tư đã dùng trong ngày
6. **Acceptance:** Nghiệm thu (nếu có)
7. **Photos:** Chụp ảnh hiện trường
8. **Recommendations:** Đề xuất cho ngày mai
9. **Safety:** Sự cố an toàn (nếu có)
10. Click "Submit" → Toast "Đã gửi"

### Photo upload

- Chụp ảnh trực tiếp trong app
- Tự động compress + GPS tag
- Sync lên server khi có mạng

### Offline mode

- App tự động lưu local khi mất mạng
- Khi có mạng → auto sync
- Badge "Pending sync" hiển thị số record chưa sync

---

## 🔍 Tìm kiếm & Filter

**Hầu hết các table đều có:**

- **Search box (góc trên phải):** Gõ để filter real-time
- **Column filter:** Click icon filter trên header
- **Date range:** Chọn từ-đến
- **Multi-select:** Click vào dropdown → check nhiều giá trị

**Saved filter:** Click "Save filter" để lưu lại (chỉ HQ)

---

## 🌙 Dark mode

- Click icon ☀️/🌙 ở top bar
- Áp dụng cho tất cả screens
- Lưu vào localStorage → giữ qua các lần đăng nhập

---

## 📱 Mobile (Responsive)

**Tất cả screens tự động responsive:**

- **Desktop (≥1024px):** Sidebar cố định, multi-column
- **Tablet (768-1023px):** Sidebar thu nhỏ
- **Mobile (<768px):**
  - Hamburger menu (☰) góc trên trái → drawer overlay
  - Table: 2-column compact
  - KPI cards: 2 per row
  - Touch-friendly (button lớn, tap target ≥44px)

**Test trên mobile:**
1. Mở URL trên điện thoại
2. Check menu, scroll, click đều mượt
3. Test approval flow trên mobile
4. Test upload ảnh từ camera

---

## ⌨️ Phím tắt

- `Ctrl/Cmd + K` - Quick search (planned)
- `Esc` - Đóng modal
- `Tab` - Di chuyển giữa các field trong form
- `Enter` - Submit form

---

## ❓ Câu hỏi thường gặp

### Tôi quên mật khẩu
→ Liên hệ admin. Admin sẽ reset qua Operations runbook.

### Tôi không thấy menu "Approval" / "Payment"
→ Bạn không có quyền truy cập. Liên hệ PM/PMO để được cấp quyền.

### Tôi upload Excel mà không thấy rows
- Check filename có chứa zone code (vd: "Shop BOH.xlsx")
- Check tên file có keyword đúng (vd: "Tiến độ", "vật tư", "shop")
- Check Excel có header đúng format

### Tại sao pie chart hiển thị 0%?
- Project chưa có data → cần upload file
- Filter period chỉ giới hạn ngày hôm nay → chọn "All time"

### Tôi có thể edit data đã upload không?
- Có, vào màn hình tương ứng → click vào dòng → edit
- Hoặc upload lại file (sẽ REPLACE rows cũ cho cùng zone)

### Tôi có thể export báo cáo không?
- Có, nhiều màn hình có nút "Export Excel" góc trên phải
- File tải về có cùng filter đang áp dụng

### Mobile dùng có ổn không?
- Có, app responsive đầy đủ
- Field app (site) thiết kế mobile-first

### Tôi cần training, ai hỗ trợ?
- Liên hệ PM/PMO của dự án
- Hoặc xem lại video demo (nếu có)

---

## 🆘 Liên hệ hỗ trợ

**Trong giờ làm việc:**
- Hotline: [số điện thoại]
- Email: support@your-company.com
- Slack: #pmo-support

**Ngoài giờ (Severity 1):**
- Hotline khẩn: [số điện thoại]

**Bug report:**
- Gửi email kèm screenshot + mô tả các bước tái tạo
- Include: trình duyệt, OS, role của bạn
</content>
