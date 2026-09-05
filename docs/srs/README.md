# PMO MVP — SRS Documents

> Thư mục chứa **Software Requirements Specification (SRS)** + **UML Diagrams** cho dự án PMO MVP.

## Files

| File | Mô tả | Kích thước |
|---|---|---|
| `SRS.md` | **Bản đầy đủ** — 13 chương, chuẩn IEEE 830 + ISO 25010 | ~50KB |
| `01_use_case.mmd` + `.png` | Use Case Diagram (7 actors × 17 use cases) | 2368×527 |
| `02_class_diagram.mmd` + `.png` | Class Diagram (16 domain classes) | 1702×1768 |
| `03_sequence_login.mmd` + `.png` | Sequence: Login Flow (rate limit → bcrypt → token) | 1616×1543 |
| `04_sequence_upload_wizard.mmd` + `.png` | Sequence: Upload Wizard 4 bước | 2136×1768 |
| `05_activity_upload.mmd` + `.png` | Activity: Upload Excel Flow (decision nodes) | 971×1768 |
| `06_state_shop_workflow.mmd` + `.png` | State Machine: Shop Drawing DRAFT→APPROVED | 956×936 |
| `07_er_diagram.mmd` + `.png` | ER Diagram (16 entities) | 2368×1768 |
| `08_deployment.mmd` + `.png` | Deployment (Client → Cloudflare → Express → PG) | 1470×1647 |
| `render_mermaid.mjs` | Script render Mermaid → PNG (dùng Playwright) | — |

## Cách xem diagrams

**Cách 1: Trong IDE / GitHub**
- Mở file `.mmd` (text) hoặc `.md` (SRS.md có nhúng mermaid)
- GitHub tự render Mermaid

**Cách 2: File PNG**
- Mở file `.png` (kích thước đã phù hợp)

**Cách 3: Render lại (sau khi sửa .mmd)**
```bash
cd docs/srs
node render_mermaid.mjs 01_use_case.mmd 01_use_case.png
# Hoặc tất cả:
for f in *.mmd; do node render_mermaid.mjs "$f" "${f%.mmd}.png"; done
```

**Cách 4: Online editor**
- Copy nội dung `.mmd` vào https://mermaid.live/

## Cấu trúc SRS.md (13 chương)

1. **Giới thiệu** — Mục đích, phạm vi, định nghĩa, tham chiếu
2. **Mô tả tổng quan** — Bối cảnh, 6 nhóm chức năng, 7 users, 10 constraints
3. **Yêu cầu chức năng** — 60+ FRs chia 9 modules (AUTH, INGEST, PROJ, PILLAR, WORKFLOW, FIELD, RPT, ADMIN)
4. **Yêu cầu phi chức năng** — 8 đặc tính ISO 25010 (FS, PE, CO, UA, RE, SE, MA, PO)
5. **Yêu cầu giao diện** — 25 màn hình (HQ + Field + Governance)
6. **Yêu cầu dữ liệu** — 40+ bảng, ER diagram
7. **Mô hình hệ thống (UML)** — 7 diagrams (use case, class, 2 sequence, activity, state, ER, deployment)
8. **Yêu cầu bảo mật** — OWASP Top 10 mitigations
9. **Ràng buộc thiết kế** — Tech stack, coding convention
10. **Hiệu năng & khả năng mở rộng** — Targets, optimizations
11. **Tiêu chí chấp nhận** — 10 tiêu chí chung + 7 tiêu chí chất lượng + 12 bước demo
12. **Phụ lục** — Glossary, 15 loại Excel, 50+ API endpoints
13. **Lịch sử thay đổi** — 4 phiên bản

## Tính năng chính được tài liệu hóa

- ✅ **Mô hình A Wizard** (4-step upload): parse() + commit() dual API
- ✅ **15 doc types** Excel được hỗ trợ
- ✅ **7 roles** RBAC với permission matrix
- ✅ **40+ tables** PostgreSQL schema
- ✅ **60+ REST endpoints** + auth/rate-limit
- ✅ **Idempotency** qua SHA-256 file hash
- ✅ **Audit log** cho mọi mutation
- ✅ **Dark mode** + WCAG 2.1 AA
- ✅ **PG sequence auto-`setval`** (tránh race condition)
- ✅ **Ingestor 10 file types** (shop, schedule, material, RFA, ...)

## Liên hệ

- Tài liệu này là **As-Built** — phản ánh implementation thực tế
- Khi sửa code, cần cập nhật SRS tương ứng
- Câu hỏi: xem `../CODEBASE.md`, `../ARCHITECTURE.md`
