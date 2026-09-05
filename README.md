# PMO MVP — Project Management Office

> Construction project management system for multi-zone projects (BTE, Lawrence, etc.) with 4-pillar dashboard (Construction / Shop Drawing / Material / Payment), 7 role-based accounts, Excel upload pipeline, L1-L5 shop drawing approval, OTD KPI, photo gallery, payment chain, and PostgreSQL data layer.

**Live demo**: https://firm-writings-ids-basename.trycloudflare.com (login: `admin@hbg.com` / `admin123`)

---

## ⚡ Quick Start (5 phút)

### Prerequisites
- Node.js 20+
- npm 10+
- PostgreSQL 16+ (or use the included Docker Compose)
- Git

### Option A — Local with Docker Compose (easiest)

```bash
git clone https://github.com/TungLinhh/pmo-project.git
cd pmo-project
docker compose up -d        # spins up postgres + backend
curl http://localhost:3000/api/health
# Open http://localhost:3000 in browser
```

### Option B — Local with native PostgreSQL

```bash
# 1. Start PostgreSQL on port 5433
# Option: use system pg, homebrew postgres, or run helper:
#   ./backend/scripts/pg-ctl.sh start
#   (WSL2 / Linux only)

# 2. Clone & install
git clone https://github.com/TungLinhh/pmo-project.git
cd pmo-project
npm install                 # installs all workspaces (root + backend + frontend)

# 3. Apply DB schema + seed
cd backend
npm run init-db             # applies drizzle migrations + seeds demo data
cd ..

# 4. Start backend (port 3000) + frontend (port 5173 dev, or build for prod)
npm run dev                 # runs both concurrently
# Open http://localhost:5173 in browser
```

### Option C — Production build (single port)

```bash
npm install
npm run build               # build frontend → frontend/dist/
npm start                   # backend serves dist/ on port 3000
# Open http://localhost:3000
```

---

## 📚 Documentation

Full product specification: **[docs/PRODUCT_TECHNICAL_DOCUMENTATION.md](docs/PRODUCT_TECHNICAL_DOCUMENTATION.md)** — covers:
- Architecture & data model
- All 22 backend routers + 3 lib helpers
- Frontend structure (10 components + 12 HQ screens)
- 7 demo accounts + permission matrix
- Deployment, backup, troubleshooting
- All API endpoints with request/response shapes

UML diagrams: **[docs/srs/](docs/srs/)** — use case, class, sequence, activity, state, ER, deployment (mermaid source + PNG).

---

## 🛠 Tech Stack

| Layer | Tech | Notes |
|-------|------|-------|
| Backend | Node.js 20 + Express 4 | 22 routers in `backend/src/routes/` |
| Database | PostgreSQL 16 (raw `pg`) | Drizzle migrations in `backend/drizzle/` |
| Frontend | Vite + React 19 + React Router 7 | SPA, served as static files by backend in prod |
| Auth | Bearer token (in-memory) | 7 demo accounts, role-based permissions |
| File upload | multer (multipart) | Excel parsing via `xlsx` |
| Container | Docker + Docker Compose | Single command bring-up |

---

## 📁 Project Structure

```
pmo-project/
├── backend/
│   ├── src/
│   │   ├── index.js              # Express composition (130 LOC)
│   │   ├── lib/                  # auth.js, tx.js, with-audit.js, validation.js
│   │   ├── routes/               # 22 routers (auth, projects, issues, ...)
│   │   ├── db/                   # index.js (PG pool), init.js (migrations + seed)
│   │   └── services/             # ingest/ (Excel parsing) + notify.js
│   ├── drizzle/                  # SQL migrations
│   ├── data/                     # PG data + uploads (gitignored)
│   ├── scripts/                  # pg-ctl.sh
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── App.jsx               # Router + role-based shell
│   │   ├── api/                  # API client
│   │   ├── components/           # BellDropdown, ProjectPicker, DailyReportForm, etc.
│   │   ├── hq/                   # 12 HQ screens (ControlCenter, OTD, etc.)
│   │   ├── field/                # 4 Field screens
│   │   ├── governance/           # Audit log
│   │   └── styles/               # Design system
│   └── package.json
├── tests/
│   ├── e2e/                      # 5 E2E test scripts (api, payment-sla, shop-approval, schema, browser)
│   └── tools/                    # schema-audit (SQL vs schema)
├── docs/                         # PRODUCT_TECHNICAL_DOCUMENTATION.md + srs/
├── scripts/                      # UI verify scripts (vòng 6/7)
├── .github/workflows/            # CI (lint + E2E)
├── Dockerfile                    # Multi-stage build (PG)
├── docker-compose.yml            # postgres + backend stack
├── docker-entrypoint.sh          # wait-for-pg + migrate + seed
├── package.json                  # workspaces + scripts
├── README.md                     # this file
└── .gitignore
```

---

## 🔐 Demo Accounts

| Email | Password | Role | Use for |
|-------|----------|------|---------|
| `admin@hbg.com` | `admin123` | admin | Full access |
| `ceo@hbg.com` | `ceo123` | CEO | Portfolio + KPI + approve |
| `pm@hbg.com` | `pm123` | PM | Manage assigned projects |
| `pmo@hbg.com` | `pmo123` | PMO | Cross-project monitoring |
| `site@hbg.com` | `site123` | Site | Field reports, photos |
| `procurement@hbg.com` | `proc123` | Procurement | Materials, contracts |
| `accounting@hbg.com` | `acc123` | Accounting | Payment chain |

---

## 🧪 Testing

```bash
# All 4 E2E suites (70 tests)
npm test

# Individual suites
npm run test:api        # 29 tests — full API flow
npm run test:payment    # 13 tests — payment 4-step chain + submittal SLA
npm run test:shop       # 13 tests — L1-L5 shop drawing + TVGS escalation
npm run test:schema     # 15 tests — PG schema integrity
npm run test:browser    # UI test via Cloudflare tunnel (Playwright)

# Schema vs SQL audit (catches column mismatches)
npm run audit:schema
```

**Requirements**: backend must be running on `localhost:3000`. PostgreSQL on port 5433 with `pmo_user` / `pmo_dev_pwd` / `pmo` database.

---

## 🚀 NPM Scripts (root)

| Script | What it does |
|--------|--------------|
| `npm run dev` | Start backend + frontend dev (concurrently) |
| `npm run dev:backend` | Backend only (`node --watch src/index.js`) |
| `npm run dev:frontend` | Vite dev server (port 5173, HMR) |
| `npm run build` | Build frontend → `frontend/dist/` |
| `npm start` | Backend only (serves dist/ in production) |
| `npm test` | All 4 E2E suites sequentially |
| `npm run audit:schema` | SQL queries vs schema validator |
| `npm run lint` | Lint all workspaces |

---

## 🐳 Docker

```bash
# Build image
docker build -t pmo-mvp .

# Run with compose (Postgres + backend)
docker compose up -d

# Or standalone (point to existing PG)
docker run -d -p 3000:3000 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_NAME=pmo \
  -e DB_USER=pmo_user \
  -e DB_PASSWORD=your_pwd \
  pmo-mvp
```

Image: `node:20-alpine` (frontend-build stage + runtime stage). Entrypoint waits for PG, applies migrations, seeds.

---

## 🌐 Environment Variables

| Var | Default | Notes |
|-----|---------|-------|
| `DB_HOST` | `127.0.0.1` | PostgreSQL host |
| `DB_PORT` | `5433` | `5432` for system PG, `5433` for local cluster |
| `DB_NAME` | `pmo` | |
| `DB_USER` | `pmo_user` | |
| `DB_PASSWORD` | `pmo_dev_pwd` | **dev only** — set real value in prod |
| `DATABASE_URL` | (built from above) | Optional override |
| `PORT` | `3000` | Backend HTTP port |
| `NODE_ENV` | `development` | Set `production` in deploy |

---

## 🔧 Troubleshooting

| Problem | Fix |
|---------|-----|
| `EADDRINUSE :::3000` | `lsof -i :3000` → `kill -9 <pid>` |
| `ECONNREFUSED 127.0.0.1:5433` | PG not running. Start with `docker compose up -d postgres` or `./backend/scripts/pg-ctl.sh start` |
| `column "xyz" does not exist` | Schema drift. Run `npm run audit:schema` to find bad queries |
| White screen on dashboard | Check browser console — usually a runtime error. `npm test` to verify backend |
| `npm install` fails on Windows | Use WSL2 or Docker |

---

## 📜 License

Proprietary — internal use only. © 2026 HBG Construction.

---

## 🤝 Contributing

1. Fork + create branch: `git checkout -b feature/your-feature`
2. Make changes + add tests
3. `npm test` must pass + `npm run audit:schema` clean
4. Commit: `git commit -m "Add: your feature"`
5. Push + open Pull Request
