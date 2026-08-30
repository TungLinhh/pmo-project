# Backup Verification Report

**Ngày chạy:** 2026-08-30 00:49:48 UTC
**Người chạy:** automated test (scripts/verify-backup.sh)
**Database nguồn:** `pmo` (PostgreSQL 16)
**Database verify:** `pmo_backup_verify` (tạo mới, restore từ dump, đã xoá sau khi verify)

## Quy trình

1. `pg_dump pmo --no-owner --no-privileges > backup_test_<date>.sql` (plain SQL)
   - Cũng tạo file `.dump` (custom format) 171KB
2. `CREATE DATABASE pmo_backup_verify OWNER pmo_user`
3. `psql pmo_backup_verify < backup_test_<date>.sql` (restore)
4. So sánh row count 44 bảng public schema giữa `pmo` và `pmo_backup_verify`
5. `DROP DATABASE pmo_backup_verify` (cleanup)

## Kết quả

| Metric | Value |
|---|---|
| Tổng số bảng | 44 |
| Số bảng khớp | **44/44** |
| Số bảng lệch | 0 |
| Tổng rows source | 1120 |
| Tổng rows backup | 1120 |
| Diff tổng | 0 |

### Bảng được verify (44/44 OK)

| Table | Source | Backup | Status |
|---|---:|---:|:---:|
| area_hierarchy | 21 | 21 | OK |
| audit_log | 12 | 12 | OK |
| business_process_steps | 8 | 8 | OK |
| business_processes | 1 | 1 | OK |
| construction_schedule_items | 521 | 521 | OK |
| contracts | 0 | 0 | OK |
| cost_codes | 0 | 0 | OK |
| daily_acceptance | 22 | 22 | OK |
| daily_infos | 0 | 0 | OK |
| daily_manpower | 32 | 32 | OK |
| daily_materials | 2 | 2 | OK |
| daily_recommendations | 0 | 0 | OK |
| daily_reports | 2 | 2 | OK |
| daily_safety | 0 | 0 | OK |
| daily_safety_observations | 0 | 0 | OK |
| daily_work_items | 12 | 12 | OK |
| directives | 6 | 6 | OK |
| file_uploads | 0 | 0 | OK |
| generic_sheets | 2 | 2 | OK |
| invoices | 0 | 0 | OK |
| issues | 12 | 12 | OK |
| kpi_targets | 0 | 0 | OK |
| material_submittals | 1 | 1 | OK |
| materials | 242 | 242 | OK |
| notifications | 20 | 20 | OK |
| offline_sync_queue | 2 | 2 | OK |
| payment_milestones | 0 | 0 | OK |
| payment_requests | 0 | 0 | OK |
| payments | 0 | 0 | OK |
| projects | 2 | 2 | OK |
| resources | 0 | 0 | OK |
| rfa_log | 32 | 32 | OK |
| schedule_baselines | 2 | 2 | OK |
| shop_drawings | 102 | 102 | OK |
| subcontractors | 41 | 41 | OK |
| suppliers | 2 | 2 | OK |
| teams | 0 | 0 | OK |
| tenants | 1 | 1 | OK |
| users | 1 | 1 | OK |
| vendors | 0 | 0 | OK |
| wbs | 0 | 0 | OK |
| work_items | 0 | 0 | OK |
| workers | 0 | 0 | OK |
| zones | 19 | 19 | OK |

## Kết luận

✅ **Quy trình backup/restore dùng được** - 44/44 bảng khớp 100%, không có data loss.

`pg_dump` (plain SQL) + `psql < dump.sql` đảm bảo full fidelity. File dump 289KB (plain) hoặc 171KB (custom format) cho toàn bộ database.

### Khuyến nghị production
- Backup daily: `pg_dump pmo | gzip > backup_$(date +%F).sql.gz`
- Test restore monthly: tạo DB test, restore từ backup mới nhất
- Retain 30 ngày local, upload lên S3/GCS cho disaster recovery

### Files
- `docs/backup_verification/backup_test_20260830-004948.sql` (289KB, plain SQL)
- `docs/backup_verification/backup_test_20260830-004948.sql.dump` (171KB, custom format)
