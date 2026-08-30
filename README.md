# PMO MVP - Project Management Office

> Construction project management system with 4-pillar dashboard (Construction / Shop Drawing / Material / Payment), 7 role-based accounts, Excel upload pipeline for 9 doc types, approval workflow, dark mode (WCAG AA), and full PostgreSQL/SQLite data layer.

## Tech Stack

- **Backend:** Node.js 20 + Express 4 + better-sqlite3 / PostgreSQL 16 (Drizzle ORM)
- **Frontend:** Vite 5 + React 18 + React Router 6
- **Auth:** Cookie-based session (HTTP-only) + Bearer token
- **Security:** express-rate-limit (5/min login, 100/min API), bcrypt password
- **Storage:** Local filesystem for uploads, SQLite/PG for data

## Quick Start

### Prerequisites
- Node.js 20+ (tested with 20.11)
- npm 10+
- PostgreSQL 16+ (optional, defaults to SQLite)
- Git

### 1. Clone & Install

```bash
git clone https://github.com/TungLinhh/pmo-project.git
cd pmo-project

# Install backend deps
cd backend
npm install

# Install frontend deps
cd ../frontend
npm install
```

### 2. Setup Database

**Option A: SQLite (default, no setup needed)**
- DB file auto-created at `backend/data/pmo.db`
- Default: 7 demo accounts + 2 projects + sample data

**Option B: PostgreSQL (production)**
```bash
# Create database
psql -U postgres -c "CREATE USER pmo_user WITH PASSWORD 'pmo_pass';"
psql -U postgres -c "CREATE DATABASE pmo OWNER pmo_user;"

# Set environment
export DATABASE_URL="postgresql://pmo_user:pmo_pass@localhost:5432/pmo"
export DB_DRIVER=pg

# Run migrations
cd backend
psql $DATABASE_URL -f drizzle/0000_naive_nick_fury.sql
node seed-users.mjs
```

### 3. Start Backend

```bash
cd backend
npm run dev  # auto-reload mode
# Or
npm start    # production mode
```

Backend runs on `http://localhost:3000`. Health check: `GET /api/health`.

### 4. Start Frontend (dev)

```bash
cd frontend
npm run dev
```

Frontend dev server runs on `http://localhost:5173`, proxies API to `localhost:3000`.

### 5. Build Frontend (prod)

```bash
cd frontend
npm run build  # outputs to dist/
```

The Express backend serves the built `dist/` automatically.

### 6. Docker (alternative)

```bash
# Requires Docker Desktop with WSL integration (Windows) or native Docker (Linux/Mac)
docker build -t pmo-mvp .
docker run -d -p 3000:3000 --name pmo-test pmo-mvp
curl http://localhost:3000/api/health
docker stop pmo-test && docker rm pmo-test
```

## Demo Accounts

| Email | Password | Role | Use for |
|---|---|---|---|
| `admin@hbg.com` | `admin123` | admin | Full access all projects |
| `ceo@hbg.com` | `ceo123` | CEO | View all + KPI |
| `pm@hbg.com` | `pm123` | PM | Manage assigned projects |
| `pmo@hbg.com` | `pmo123` | PMO | Approval, monitoring |
| `site@hbg.com` | `site123` | Site | Field reports, photos |
| `procurement@hbg.com` | `proc123` | Procurement | Materials, contracts |
| `accounting@hbg.com` | `acc123` | Accounting | Payment, invoices |

## Features

### MVP Scope (20 screens, per UI Spec mục 40)
1. Login (role-based redirect)
2. App Shell (sidebar + header + dark mode toggle)
3. Project Control Center (4-pillar dashboard với pie chart)
4. Project Overview (KPIs, schedule, contacts)
5. Construction Progress (Gantt, daily update)
6. Shop Drawing (L1-L5 approval workflow)
7. Material Submittal (REVIEW → APPROVED/REJECTED)
8. Manpower & Machinery (4 tabs: Workers/Machinery/Teams/Suppliers)
9. Payment (contract → invoice → milestone)
10. Issues (create / track / resolve)
11. Notification Center
12. Master Data (subcontractors, suppliers, BP, workers)
13. Approval Center (3 loại pending: shop/submittal/payment)
14. Audit Log
15. Field PWA (login, materials, shopdrawing, issues, sync)
16-20. (more screens)

### Data Pipeline
- 9 doc types ingest: shop_drawing, construction_schedule, material_supply, subcontractor_directory, resource_directory, daily_report, rfa_log, business_process, file_uploads
- Idempotency: re-uploading same file returns same upload_id, no duplicate rows
- Validation: zone not found → clear error, missing data → skip with reason

### Security
- Rate limiting: 5 login/min/IP, 100 API/min/IP (express-rate-limit)
- Password hashing: bcrypt (10 rounds)
- Session: HTTP-only cookie, 7-day expiry
- CORS: open in dev, configurable for prod

## Testing

```bash
# Run permission test (76 admin/CEO endpoint tests)
cd backend
node scripts/test-admin-full-access.mjs

# Run upload pipeline test (9/11 file OK, 2 intentional fail)
node scripts/upload-test-pipeline.mjs

# Run UI verification (Playwright, requires chromium)
cd ..
node scripts/ui-verify.mjs all
```

## Project Structure

```
pmo-project/
├── backend/
│   ├── src/
│   │   ├── index.js              # Express routes
│   │   ├── db/index.js           # DB abstraction (SQLite/PG)
│   │   ├── lib/                  # auth, excel, storage, validation
│   │   └── services/ingest/      # 8 ingestor modules
│   ├── scripts/
│   │   ├── generate-test-excel.mjs
│   │   ├── upload-test-pipeline.mjs
│   │   ├── test-admin-full-access.mjs
│   │   ├── seed-users.mjs
│   │   └── archive/              # deprecated scripts
│   ├── drizzle/                  # PG schema
│   ├── data/
│   │   ├── pmo.db                # SQLite (gitignored)
│   │   └── test-fixtures/        # Test Excel files
│   ├── package.json
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── App.jsx               # Router root
│   │   ├── api/                  # API client
│   │   ├── components/           # Toast, PieChart, CursorTooltip
│   │   ├── hq/                   # 14 HQ screens
│   │   ├── field/                # 5 Field PWA screens
│   │   ├── governance/           # 3 governance screens
│   │   ├── icons.jsx             # 50+ SVG icons
│   │   └── styles/global.css     # Design system + dark mode
│   ├── package.json
│   └── vite.config.js
├── docs/
│   ├── demo_script.md            # Live demo guide
│   ├── backup_verification/      # pg_dump/restore proof
│   ├── daily_report_verification.md
│   ├── docker_build_test_report.md
│   └── bug_screenshots/          # UI bug before/after
├── scripts/                      # Cross-stack scripts
├── .github/workflows/            # CI (TODO)
├── Dockerfile
├── docker-entrypoint.sh
├── README.md                     # This file
├── CHECKLIST.md                  # Feature completion tracking
└── .gitignore
```

## Contributing

1. Fork the repo
2. Create feature branch: `git checkout -b feature/your-feature`
3. Commit: `git commit -m "Add: your feature"`
4. Push: `git push origin feature/your-feature`
5. Open Pull Request

## License

Proprietary - internal use only.

## Contact

Tùng Linh - tunglinh@hbg.com
