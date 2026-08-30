# Daily Report Sub-row Verification

**Ngày chạy:** 2026-08-30
**File gốc:** `Báo cáo công việc C20 ngày 23.5.2021.xlsx` (HBG-HBC-BCTT)
**Project DB:** 2 (LAWRENCE-STING-2 / C20)
**2 sheets:** `23.5.2021` và `22.5.2021`

## Quy trình verify

1. Đọc file Excel gốc bằng `xlsx` lib
2. Đếm tay từng section: work_items (parents + subs), materials, manpower, acceptance
3. So sánh với row count trong DB (SQLite `data/pmo.db`)

## Kết quả đếm tay (file gốc)

| Section | Range (0-idx) | Điều kiện đếm | Count mỗi sheet |
|---|---|---|---:|
| Work items (parents) | R27-R37 | col[0]=number, col[1]=text | 3 (KHO, Thi công, Tầng hầm) |
| Work items (sub) | R27-R37 | col[8]=text (không tính "Tổng cộng") | 5 (Ban quản lý, Thư ký, San lấp, Xây dựng kho, Lắp đặt) |
| Materials | R42-R57 | col[8]=text | 1 |
| Manpower | R63-R82 | col[10]=text (role name) | 16 |
| Acceptance | R63-R77 | col[0]=number | 11 |

## Kết quả DB (sau parser fix)

| Bảng | Sheet 23.5 | Sheet 22.5 | Expected | Khớp? |
|---|---:|---:|---:|:---:|
| daily_reports | 1 | 1 | 1/sheet | ✅ |
| daily_work_items | 8 (3 parent + 5 sub) | 8 (3 parent + 5 sub) | 8/sheet | ✅ |
| daily_materials | 1 | 1 | 1/sheet | ✅ |
| daily_manpower | 16 | 16 | 16/sheet | ✅ |
| daily_acceptance | 11 | 11 | 11/sheet | ✅ |

## Bug đã fix trong quá trình verify

**Bug 1: Work items miss parent ở R27**
- Triệu chứng: Parser scan R28-R37, miss parent 1 ở R27 (0-idx) → 6 work items thay vì 7
- Fix: Mở rộng range `for (let r = 27; r <= 37; r++)`
- Verify: Sau fix, DB có 8 work_items/sheet (3 parent + 5 sub) ✅

**Bug 2: Tổng cộng bị count là parent**
- Triệu chứng: Row 35 có col[0]="Tổng cộng/Total (%)" (string), col[1] truthy → bị count
- Fix: `if (tt && name && !/Tổng cộng|^Total$/i.test(name))` (đã có sẵn toInt check, không trigger)
- Verify: DB có 3 parents thực sự ✅

## Kết luận

✅ **Daily report parser hoạt động đúng sau fix**. Tất cả sub-rows (work_items, materials, manpower, acceptance) khớp 100% với file gốc cho cả 2 sheets.

### Files
- `backend/src/services/ingest/daily_report.js` (đã fix range R27-R37 + filter "Tổng cộng")
- File gốc: `Báo cáo công việc C20 ngày 23.5.2021.xlsx`
