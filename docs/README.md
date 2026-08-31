# PMO MVP - Documentation

> Complete documentation for the PMO MVP project. Start here.

**Last updated:** 2026-08-31
**Project status:** MVP ready for client deployment
**Stack:** Node 20 + Express + SQLite/PostgreSQL + React 19 + Vite

---

## 📚 Documentation index

| Doc | Audience | Purpose |
|---|---|---|
| **[CODEBASE.md](CODEBASE.md)** | Developers, tech leads | Complete file-by-file reference. Every file, every function, every API route. |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Architects, senior devs | System design, data flow diagrams, deployment topology, design decisions. |
| **[SETUP_FOR_CLIENT.md](SETUP_FOR_CLIENT.md)** | DevOps, sysadmin | How to deploy for a client. 3 deployment options (Docker, Docker Compose+PG, manual). |
| **[OPERATIONS.md](OPERATIONS.md)** | DevOps, sysadmin | Daily runbook: monitoring, backup, restore, common fixes, incident response. |
| **[USER_GUIDE.md](USER_GUIDE.md)** | End users (PM, CEO, site, etc.) | How to use the app. Per-role guide for HQ and Field app. |
| **[DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)** | New developers | Setup, conventions, common tasks, debugging, git workflow. |

---

## 🎯 Quick links

### For the developer who just joined
1. Read [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) - setup + workflow
2. Read [ARCHITECTURE.md](ARCHITECTURE.md) - understand the design
3. Use [CODEBASE.md](CODEBASE.md) as reference while coding

### For the dev deploying to a client
1. Read [SETUP_FOR_CLIENT.md](SETUP_FOR_CLIENT.md) - 3 options
2. Use [OPERATIONS.md](OPERATIONS.md) after deployment - runbook

### For the PM/stakeholder
1. [USER_GUIDE.md](USER_GUIDE.md) - how to use the app
2. [../demo_script.md](../demo_script.md) - 30-min demo flow

### For tech support
1. [OPERATIONS.md](OPERATIONS.md) - troubleshooting + incident response
2. [CODEBASE.md](CODEBASE.md) - find the function that handles X

---

## 🚀 Quick start (TL;DR)

### Run locally
```bash
# 1. Install
cd backend && npm install
cd ../frontend && npm install && npm run build

# 2. Seed
cd ../backend
node scripts/seed-test-master-business.mjs
node scripts/seed-demo-data-enrich.mjs

# 3. Start
node src/index.js          # Backend on :3000 (serves API + built FE)

# Or dev mode (HMR):
cd ../frontend && npm run dev  # Vite on :5173 with proxy
```

Open http://localhost:3000 → login `admin@hbg.com` / `admin123`

### Deploy with Docker
```bash
docker build -t pmo-mvp .
docker run -d --name pmo -p 3000:3000 \
  -v ~/pmo-data:/app/backend/data pmo-mvp
```

### Expose via Cloudflare Tunnel
```bash
# Quick tunnel (5 min)
cloudflared tunnel --url http://localhost:3000
# Returns: https://xxx.trycloudflare.com

# Named tunnel (URL cố định, 30 min)
cloudflared tunnel login
cloudflared tunnel create pmo-prod
# ... see SETUP_FOR_CLIENT.md for full steps
```

---

## 📂 Project layout

```
pmo-project/
├── docs/                    ← You are here
│   ├── README.md            (this file)
│   ├── CODEBASE.md          (35 KB - file/function reference)
│   ├── ARCHITECTURE.md      (17 KB - system design)
│   ├── SETUP_FOR_CLIENT.md  (12 KB - deployment)
│   ├── OPERATIONS.md        (9.5 KB - runbook)
│   ├── USER_GUIDE.md        (9.5 KB - end-user docs)
│   └── DEVELOPER_GUIDE.md   (13.6 KB - dev workflow)
│
├── backend/                 Express + SQLite
│   ├── src/                 25 source files
│   │   ├── index.js         (60 API routes)
│   │   ├── db/              (SQLite + PG schema)
│   │   ├── lib/             (auth, permissions, excel, zone_matcher)
│   │   └── services/        (ingest/, export/)
│   ├── scripts/             10 scripts (seed, test, generate)
│   └── data/                pmo.db + uploads/
│
├── frontend/                React 19 + Vite
│   ├── src/                 50 files
│   │   ├── App.jsx          (Router + Providers)
│   │   ├── api/             (API client)
│   │   ├── components/      (10 shared: Login, HqShell, PieChart, ...)
│   │   ├── hq/              (20 HQ screens)
│   │   ├── field/           (9 Field screens)
│   │   ├── governance/      (4 screens)
│   │   ├── styles/          (4 CSS files)
│   │   ├── constants.js
│   │   └── icons.jsx        (~30 SVG icons)
│   └── dist/                (production build)
│
├── scripts/                 10 Playwright E2E tests
│
├── reference_sheets/        Sample Excel files (HBG-HBC-BTTT project)
│
├── Dockerfile               Multi-stage Docker build
├── docker-entrypoint.sh     Container init
├── package.json             Workspace stub
├── README.md                Top-level readme
├── CHECKLIST.md             Per-vòng progress log
└── demo_script.md           Stakeholder demo guide
```

---

## 🎬 Demo flow (30 min)

See [../demo_script.md](../demo_script.md) for full step-by-step.

**Highlights:**
1. Login as 6 different roles → see different menu items
2. Control Center - 4 pillars pie chart
3. Project Detail - drill into KPIs
4. Construction Schedule - 50/100 done
5. Shop Drawing - 5 status states
6. Material Submittal - workflow + overdue
7. Payment - retention/VAT/overdue
8. Issues - 4 severity + CEO directive
9. **Approval Center** - inline expand + confirm (highlight!)
10. Mobile portrait - 375×812 responsive
11. Dark mode - all pages
12. Audit log + notifications

---

## 🧪 Test accounts

| Email | Password | Role | Use case |
|---|---|---|---|
| `admin@hbg.com` | `admin123` | Admin | Full access |
| `ceo@hbg.com` | `ceo123` | CEO | Portfolio + directive |
| `pm@hbg.com` | `pm123` | PM | Project management |
| `pmo@hbg.com` | `pmo123` | PMO | Multi-project tracking |
| `site@hbg.com` | `site123` | Site | Field app |
| `proc@hbg.com` | `proc123` | Procurement | Material/supplier |
| `acc@hbg.com` | `acc123` | Accounting | Contract/payment |

**⚠️ Change all passwords before going to client!**

---

## 📊 Current state (vòng 8)

- ✅ **Demo data:** 51 shop drawings, 100 schedule items, 84 materials, 30 submittals, 11 payment milestones, 28 issues, 6 KPI, 18 areas, 89 notifications
- ✅ **Mobile responsive:** 12/12 HQ screens tested at 375×812
- ✅ **Permission matrix:** 130/130 tests pass (6 roles × 14 modules)
- ✅ **Approval UX:** inline expand + confirm + same API
- ✅ **Dark mode:** 13/13 pages audited
- ✅ **Ingest:** 29/29 zone files, 16 zones in multi-zone rollup, 80 rows
- ✅ **Tunnel:** working via Cloudflare (no Docker needed)
- ✅ **Production build:** 372KB JS / 103KB gzip

**Git commits:**
- `6091f50` vòng 1
- `ba53873` vòng 2
- `0a874de` vòng 3
- `fc758e9` demo_script
- `4e817d3` ingest fixes
- `26872ac` UI fixes
- `087f39f` CHECKLIST vòng 8

---

## 📞 Support

**Internal (dev team):**
- Slack: #pmo-dev
- Email: dev@your-company.com

**Client (after deploy):**
- Hotline: [số điện thoại]
- Email: support@your-company.com
- SLA: 4h for Sev1, 1 day for Sev2

---

**Next steps:**
1. If you're a developer → [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)
2. If you're deploying → [SETUP_FOR_CLIENT.md](SETUP_FOR_CLIENT.md)
3. If you're operating → [OPERATIONS.md](OPERATIONS.md)
4. If you're using the app → [USER_GUIDE.md](USER_GUIDE.md)
5. If you need code reference → [CODEBASE.md](CODEBASE.md)
</content>
