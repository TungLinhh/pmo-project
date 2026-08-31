# PMO MVP - Setup Guide for Client

> Hướng dẫn từng bước để deploy PMO MVP cho khách hàng. Từ chuẩn bị server đến go-live.

**Ngày tạo:** 2026-08-31
**Thời gian ước tính:** 1-2 giờ cho setup lần đầu

---

## 🎯 Chuẩn bị trước khi deploy

### Yêu cầu phần cứng (cho 1-20 users)

| Tier | CPU | RAM | Disk | Users |
|---|---|---|---|---|
| **Small** (1-5 users) | 2 vCPU | 2 GB | 20 GB | Site, PM |
| **Medium** (5-20 users) | 4 vCPU | 4 GB | 50 GB | + HQ team |
| **Large** (20-100 users) | 8 vCPU | 8 GB | 100 GB | + Field (PostgreSQL required) |

### Yêu cầu phần mềm

- **OS:** Ubuntu 22.04 LTS (khuyến nghị) hoặc bất kỳ Linux nào
- **Docker** 24+ và Docker Compose v2
- **Domain** (vd: `pmo.khachhang.com`) - tùy chọn nhưng khuyến nghị
- **SSL Certificate** (Cloudflare tunnel cung cấp miễn phí)

---

## 🚀 Phương án A: Docker + Cloudflare Tunnel (Khuyến nghị cho MVP)

**Ưu điểm:**
- Không cần cấu hình HTTPS, firewall, port forwarding
- Cloudflare CDN miễn phí + DDoS protection
- URL cố định (named tunnel) hoặc URL random (quick tunnel)
- Triển khai trong 10 phút

### Bước 1: Cài Docker

```bash
# Update + install
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg

# Add Docker repo
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group (avoid sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker --version
```

### Bước 2: Copy code lên server

```bash
# Option 1: Git clone (if private repo)
ssh user@server
git clone https://github.com/your-org/pmo-project.git
cd pmo-project

# Option 2: SCP from local
scp -r /path/to/pmo-project user@server:~/
ssh user@server
cd ~/pmo-project
```

### Bước 3: Build Docker image

```bash
cd ~/pmo-project
docker build -t pmo-mvp:latest .
```

**Quá trình build mất ~3 phút** (frontend + backend deps + final image ~200MB)

### Bước 4: Khởi động container

```bash
# Create data directory on host (for persistence)
mkdir -p ~/pmo-data/uploads

# Run container
docker run -d \
  --name pmo-app \
  --restart unless-stopped \
  -p 3000:3000 \
  -v ~/pmo-data:/app/backend/data \
  -v ~/pmo-data/uploads:/app/backend/uploads \
  -e NODE_ENV=production \
  -e PORT=3000 \
  pmo-mvp:latest

# Check logs
docker logs -f pmo-app
# Should see: 🚀 PMO Backend running on http://localhost:3000
```

### Bước 5: Verify hoạt động

```bash
# Local health check
curl http://localhost:3000/api/health
# {"status":"ok","timestamp":"...","authenticated":false}

# Test login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@hbg.com","password":"admin123"}'
# Should return token
```

### Bước 6: Setup Cloudflare Tunnel

#### Option A: Quick tunnel (URL random, 5 phút)

```bash
# Install cloudflared
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install -y cloudflared

# Start quick tunnel
cloudflared tunnel --url http://localhost:3000
# Returns: https://random-name.trycloudflare.com
```

**Lưu ý:** URL thay đổi mỗi lần restart. Dùng cho demo/test nhanh.

#### Option B: Named tunnel (URL cố định, 30 phút)

```bash
# 1. Login to Cloudflare
cloudflared tunnel login
# Mở browser, chọn domain (vd: khachhang.com)

# 2. Create tunnel
cloudflared tunnel create pmo-prod
# Returns: tunnel ID + credentials file

# 3. Create config
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml <<EOF
tunnel: pmo-prod
credentials-file: /home/user/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: pmo.khachhang.com
    service: http://localhost:3000
  - service: http_status:404
EOF

# 4. Add DNS record
cloudflared tunnel route dns pmo-prod pmo.khachhang.com

# 5. Run as service
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared

# 6. Test
curl https://pmo.khachhang.com/api/health
```

### Bước 7: Đổi mật khẩu admin (QUAN TRỌNG)

```bash
# SSH into server
ssh user@server

# Connect to DB
sqlite3 ~/pmo-data/pmo.db

# Change admin password (use a known bcrypt hash, or use the seed script)
# Easier: use the reset script
docker exec -it pmo-app sh
cd /app/backend
node -e "
import('./lib/auth.js').then(async (m) => {
  const db = (await import('./db/index.js')).getDb();
  // Generate new token for admin
  const token = Math.random().toString(36).slice(2) + Math.random().toString(36).slice(2);
  db.prepare('UPDATE users SET session_token=? WHERE email=?').run(token, 'admin@hbg.com');
  console.log('New token:', token);
});
"
```

**Tốt hơn:** Thêm user mới với email của khách, xóa admin mặc định:

```bash
docker exec -it pmo-app sh
cd /app/backend
# Edit and run:
node -e "
import('./db/index.js').then(async (m) => {
  const db = m.getDb();
  db.prepare('INSERT INTO users (tenant_id, email, password_hash, full_name, role, is_ceo) VALUES (1, ?, ?, ?, ?, ?)')
    .run('admin@khachhang.com', 'HASHED_PW', 'Khách Admin', 'admin', 0);
  console.log('Done');
});
"
```

**Hash password** dùng Node:
```bash
node -e "console.log(require('bcryptjs').hashSync('matkhaumoi', 10))"
```

---

## 🐘 Phương án B: Docker Compose + PostgreSQL (cho production lớn)

### File: `docker-compose.yml`

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_DRIVER=postgres
      - PG_HOST=db
      - PG_PORT=5432
      - PG_USER=pmo
      - PG_PASSWORD=${DB_PASSWORD}
      - PG_DATABASE=pmo
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - pmo-uploads:/app/backend/uploads
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=pmo
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=pmo
    volumes:
      - pmo-pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U pmo"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  pmo-pgdata:
  pmo-uploads:
```

```bash
# Create .env
echo "DB_PASSWORD=YourSecurePassword123!" > .env

# Start
docker compose up -d

# Migrate (one-time)
docker compose exec app node scripts/archive/migrate-sqlite-to-pg.mjs
```

---

## 🛠 Phương án C: Manual (không Docker, cho dev/test nội bộ)

```bash
# 1. Install Node 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 2. Clone + setup
git clone https://github.com/your-org/pmo-project.git
cd pmo-project
cd backend && npm ci
cd ../frontend && npm ci && npm run build
cd ..

# 3. Seed database
cd backend
node scripts/seed-test-master-business.mjs
node scripts/seed-demo-data-enrich.mjs

# 4. Start with PM2 (process manager)
sudo npm install -g pm2
pm2 start src/index.js --name pmo-backend
pm2 startup  # follow instructions
pm2 save

# 5. Setup nginx reverse proxy (optional)
sudo apt install -y nginx
# /etc/nginx/sites-available/pmo:
# server {
#   listen 80;
#   server_name pmo.khachhang.com;
#   location / {
#     proxy_pass http://localhost:3000;
#     proxy_set_header Host $host;
#     proxy_set_header X-Real-IP $remote_addr;
#   }
# }
sudo ln -s /etc/nginx/sites-available/pmo /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

---

## 📋 Checklist go-live cho khách

### Trước go-live
- [ ] Server provisioned (đủ tài nguyên)
- [ ] Docker installed và test thành công `docker run hello-world`
- [ ] Domain trỏ về server (hoặc Cloudflare tunnel setup)
- [ ] SSL/HTTPS hoạt động (qua Cloudflare)
- [ ] Database seeded với data thực của dự án khách
- [ ] Admin password đã đổi (không còn `admin@hbg.com`/`admin123`)
- [ ] Backup database script setup
- [ ] Firewall chỉ mở port SSH (22) + Docker (nếu cần)

### Test sau khi deploy
- [ ] Mở browser, truy cập URL
- [ ] Login với admin mới → vào Control Center
- [ ] Test upload 1 file Excel mẫu → check rows được insert
- [ ] Test approval flow: tạo 1 draft, approve, check status
- [ ] Test mobile: mở URL trên điện thoại, check drawer hoạt động
- [ ] Test các role: login với 6 users khác nhau, check permission
- [ ] Test rate limit: spam login → check bị block 1 phút

### Handover cho khách
- [ ] Bàn giao tài liệu:
  - `docs/USER_GUIDE.md` (hướng dẫn sử dụng)
  - `docs/OPERATIONS.md` (runbook vận hành)
  - Bảng credentials (an toàn, mã hóa)
- [ ] Training session 2-4 giờ:
  - PM: dashboard, upload, approval
  - Site: field app, daily report
  - CEO: portfolio view, directive
- [ ] Hỗ trợ 1-2 tuần đầu (fix bug, support user)
- [ ] Hợp đồng bảo trì (nếu có)

---

## 🔄 Quy trình update version

```bash
# 1. Backup database TRƯỚC
ssh user@server
cd ~/pmo-project
docker exec pmo-app sh -c "cp /app/backend/data/pmo.db /app/backend/data/pmo.db.bak"

# Or for PG
docker compose exec db pg_dump -U pmo pmo > backup-$(date +%Y%m%d).sql

# 2. Pull new code
git pull origin main

# 3. Rebuild image
docker build -t pmo-mvp:latest .

# 4. Restart (zero-downtime with blue-green if needed)
docker stop pmo-app
docker rm pmo-app
docker run -d --name pmo-app ...  # same command as before
```

**Rollback** nếu có vấn đề:
```bash
# Stop current
docker stop pmo-app && docker rm pmo-app

# Restore previous image (if you tagged it)
docker run -d --name pmo-app pmo-mvp:previous ...

# Restore DB backup
docker exec -it pmo-app sh
cp /app/backend/data/pmo.db.bak /app/backend/data/pmo.db
```

---

## 🆘 Troubleshooting thường gặp

### Container không start
```bash
docker logs pmo-app
# Common: "EADDRINUSE :::3000" → port 3000 bị chiếm
# Fix: lsof -i :3000 → kill process
```

### Database locked
```bash
# SQLite
docker exec pmo-app sh
cd /app/backend/data
ls -la pmo.db*
# Remove -wal, -shm files if orphan
rm pmo.db-shm pmo.db-wal  # chỉ khi container đã stop
```

### 502 Bad Gateway qua Cloudflare
- Check `cloudflared` đang chạy: `sudo systemctl status cloudflared`
- Check port 3000: `curl http://localhost:3000/api/health`
- Restart tunnel: `sudo systemctl restart cloudflared`

### Login không hoạt động (401)
- Token có thể đã expire hoặc user bị xóa
- Check logs: `docker logs pmo-app | grep -i "auth"`
- Reset admin: dùng script trong phần "Đổi mật khẩu admin"

### Upload file lỗi
- File > 50MB? Check `multer` config in `index.js`
- Excel corrupted? Open in Excel, re-save
- Wrong doc type? Check `detectDocType` matches your filename

### Frontend không load (404)
- `frontend/dist/` không tồn tại trong container?
- `docker exec pmo-app ls /app/frontend/dist`
- Re-build image if needed

### Database hết dung lượng
- SQLite max ~140 TB (không lo)
- Disk: check `df -h`, archive old uploads

---

## 📞 Support

Sau khi deploy, nếu khách gặp vấn đề:
1. Check `docs/OPERATIONS.md` - runbook
2. Check `docs/CODEBASE.md` - file/function reference
3. Check logs: `docker logs pmo-app`
4. Reproduce locally với data backup
5. Fix → rebuild → redeploy
</content>
