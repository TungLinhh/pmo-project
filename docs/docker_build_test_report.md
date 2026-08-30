# Docker Build Test Report

**Ngày chạy:** 2026-08-30
**Môi trường:** WSL (Ubuntu) trên Windows, user `vutun` (non-root)

## Kết quả: KHÔNG THỂ test `docker build` trong môi trường hiện tại

### Giới hạn
- `docker` command: **không có** (`which docker` → empty)
- `dockerd` daemon: **không chạy**
- `/var/run/docker.sock`: **không tồn tại**
- `apt install docker.io`: **thất bại** (permission denied, không có root)
- `sudo`: **không hoạt động** (no tty, no askpass)
- Docker Desktop trên Windows: **không cài** (không tìm thấy `/mnt/c/Program Files/Docker/`)
- `podman`, `nerdctl`, `buildah`: **không có**
- `unprivileged_userns_clone` kernel feature: **không available**

### Phương án thay thế để user tự test

#### Phương án A: Docker Desktop trên Windows (khuyến nghị)
1. Cài Docker Desktop: https://www.docker.com/products/docker-desktop/
2. Bật WSL integration: Settings → Resources → WSL Integration → Enable
3. Restart WSL: `wsl --shutdown` rồi mở lại
4. Test:
   ```bash
   cd /home/vutun/pmo_project
   docker build -t pmo-mvp:latest .
   docker run -d -p 3000:3000 --name pmo-test pmo-mvp:latest
   sleep 5
   curl http://localhost:3000/api/health
   docker logs pmo-test
   docker stop pmo-test && docker rm pmo-test
   ```

#### Phương án B: Máy khác có Docker
```bash
git clone https://github.com/TungLinhh/pmo-project.git
cd pmo-project
docker build -t pmo-mvp .
docker run -p 3000:3000 pmo-mvp
```

#### Phương án C: GitHub Actions (CI test build)
Tạo `.github/workflows/docker-build.yml` để GitHub tự test build:
```yaml
name: Docker Build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t pmo-mvp .
      - run: docker run -d -p 3000:3000 pmo-mvp && sleep 5
      - run: curl -f http://localhost:3000/api/health
```

### Dockerfile syntax review (đã verify trước đó)
- Multi-stage: 2 stages (frontend build + backend serve)
- Base image: `node:20-alpine` (nhỏ, an toàn)
- Healthcheck: `wget http://localhost:3000/api/health`
- Entrypoint: `docker-entrypoint.sh` chạy migration idempotent trước khi start
- .dockerignore: loại trừ node_modules, data, docs, .git

### Risk assessment
- Build có khả năng fail ở:
  - `npm ci` nếu `package-lock.json` có conflict với peer deps (đã verify `npm install` thành công local)
  - `npm run build` nếu Vite có vấn đề với alias imports (đã verify `npm run build` thành công local)
  - Multer `memoryStorage` có thể cần `tmpfs` trong container (đã có giới hạn 50MB, OK cho demo)
- Khuyến nghị: test trên Docker Desktop trước khi deploy production
