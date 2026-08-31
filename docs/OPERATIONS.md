# PMO MVP - Operations Runbook

> Hướng dẫn vận hành hàng ngày cho admin/super-user. Backup, monitor, fix lỗi thường gặp, restore.

---

## 📊 Monitoring hàng ngày

### Health check
```bash
# Application health
curl -s http://localhost:3000/api/health | jq

# Container status
docker ps | grep pmo-app
docker stats pmo-app --no-stream

# Disk usage
df -h /var/lib/docker
du -sh ~/pmo-data
```

### Log check
```bash
# Last 100 lines
docker logs --tail 100 pmo-app

# Follow live
docker logs -f pmo-app

# Search for errors
docker logs --since 24h pmo-app 2>&1 | grep -iE "error|warn|fail" | tail -30

# Audit log (user actions)
sqlite3 ~/pmo-data/pmo.db "SELECT * FROM audit_log ORDER BY id DESC LIMIT 20"
```

### Key metrics to watch
- **Response time** > 1s: investigate
- **Error rate** > 5%: check logs
- **Disk usage** > 80%: archive old files
- **Memory** > 80%: consider upgrade
- **DB size** > 10GB: archive old data

---

## 💾 Backup & restore

### Automated backup (recommended)

```bash
# Create backup script
sudo tee /usr/local/bin/backup-pmo.sh > /dev/null <<'EOF'
#!/bin/bash
set -e
BACKUP_DIR=/var/backups/pmo
DATE=$(date +%Y%m%d-%H%M%S)
mkdir -p $BACKUP_DIR

# Backup SQLite
docker stop pmo-app
cp ~/pmo-data/pmo.db $BACKUP_DIR/pmo-$DATE.db
docker start pmo-app

# Backup uploads
tar czf $BACKUP_DIR/uploads-$DATE.tar.gz ~/pmo-data/uploads

# Keep last 30 days
find $BACKUP_DIR -type f -mtime +30 -delete

echo "Backup complete: $BACKUP_DIR"
EOF
sudo chmod +x /usr/local/bin/backup-pmo.sh

# Schedule daily at 2 AM
echo "0 2 * * * root /usr/local/bin/backup-pmo.sh" | sudo tee /etc/cron.d/backup-pmo
```

### Manual backup
```bash
# 1. Stop container (so DB is consistent)
docker stop pmo-app

# 2. Backup
cp -r ~/pmo-data ~/pmo-data-backup-$(date +%Y%m%d)

# 3. Restart
docker start pmo-app
```

### Restore from backup
```bash
# 1. Stop container
docker stop pmo-app

# 2. Replace data
rm -rf ~/pmo-data
cp -r ~/pmo-data-backup-20260830 ~/pmo-data

# 3. Restart
docker start pmo-app

# 4. Verify
curl http://localhost:3000/api/health
```

### PostgreSQL backup (if using PG)
```bash
# Backup
docker compose exec db pg_dump -U pmo pmo | gzip > backup-$(date +%Y%m%d).sql.gz

# Restore
gunzip < backup-20260830.sql.gz | docker compose exec -T db psql -U pmo pmo
```

---

## 👥 User management

### Add new user
```bash
docker exec -it pmo-app sh
cd /app/backend

# Generate bcrypt hash for password
HASH=$(node -e "console.log(require('bcryptjs').hashSync('NewPassword123', 10))")
echo "Hash: $HASH"

# Insert user
node -e "
import('./db/index.js').then(async (m) => {
  const db = m.getDb();
  db.prepare(\`
    INSERT INTO users (tenant_id, email, password_hash, full_name, role, is_ceo, is_active)
    VALUES (1, 'new.user@khachhang.com', '$HASH', 'Nguyễn Văn A', 'pm', 0, 1)
  \`).run();
  console.log('User created');
});
"
```

### List users
```bash
sqlite3 ~/pmo-data/pmo.db \
  "SELECT id, email, full_name, role, is_active FROM users ORDER BY id"
```

### Disable user
```bash
sqlite3 ~/pmo-data/pmo.db \
  "UPDATE users SET is_active = 0 WHERE id = 5"
```

### Reset password
```bash
HASH=$(docker exec pmo-app node -e "console.log(require('bcryptjs').hashSync('NewPw', 10))")
sqlite3 ~/pmo-data/pmo.db "UPDATE users SET password_hash = '$HASH' WHERE id = 5"
```

### Deactivate old tokens (force logout all)
```bash
sqlite3 ~/pmo-data/pmo.db "UPDATE users SET session_token = NULL"
```

---

## 📁 File upload management

### List recent uploads
```bash
sqlite3 ~/pmo-data/pmo.db \
  "SELECT id, original_filename, status, ok_rows, error_rows, created_at
   FROM file_uploads ORDER BY id DESC LIMIT 20"
```

### Re-process failed upload
```bash
# 1. Find the upload ID
sqlite3 ~/pmo-data/pmo.db "SELECT id, original_filename FROM file_uploads WHERE status = 'FAILED'"

# 2. Delete the record (so it can be re-ingested)
sqlite3 ~/pmo-data/pmo.db "DELETE FROM file_uploads WHERE id = 123"

# 3. User re-uploads the file in UI
```

### Free disk space (delete old uploads)
```bash
# Check size
du -sh ~/pmo-data/uploads

# List oldest
ls -lt ~/pmo-data/uploads | tail -20

# Delete files older than 90 days
find ~/pmo-data/uploads -type f -mtime +90 -delete

# Also delete from DB (optional)
sqlite3 ~/pmo-data/pmo.db "DELETE FROM file_uploads WHERE created_at < datetime('now', '-90 days')"
```

### Bulk re-ingest (after schema change)
```bash
docker exec -it pmo-app sh
cd /app/backend

# Re-ingest all files for a project
node -e "
import('./db/index.js').then(async (m) => {
  const db = m.getDb();
  const { ingest } = await import('./services/ingest/index.js');
  const { listSheets } = await import('./lib/excel.js');
  const fs = await import('fs');
  const path = await import('path');

  const uploads = db.prepare(\"SELECT * FROM file_uploads WHERE status='SUCCESS' AND project_id=1\").all();
  for (const u of uploads) {
    const fp = '/app/backend/uploads/' + u.stored_filename;
    if (!fs.existsSync(fp)) continue;
    // Re-ingest
    await ingest(fp, u.expected_doc_type, { projectId: u.project_id, zoneCode: u.zone_code });
    console.log('Re-ingested:', u.original_filename);
  }
});
"
```

---

## 🔧 Common fixes

### App is slow
```bash
# 1. Check DB size
ls -lh ~/pmo-data/pmo.db

# 2. Vacuum SQLite
docker stop pmo-app
sqlite3 ~/pmo-data/pmo.db "VACUUM"
docker start pmo-app

# 3. Add indexes (if specific query is slow)
docker exec pmo-app sh
cd /app/backend
sqlite3 /app/backend/data/pmo.db <<EOF
CREATE INDEX IF NOT EXISTS idx_daily_reports_project_date ON daily_reports(project_id, report_date);
CREATE INDEX IF NOT EXISTS idx_construction_items_zone ON construction_schedule_items(project_id, zone_id);
EOF
```

### Container keeps restarting
```bash
# Check why
docker logs --tail 200 pmo-app

# Common: "EADDRINUSE :::3000" → another process using port
sudo lsof -i :3000
sudo kill <PID>

# Or: OOM (out of memory)
docker stats pmo-app
# → increase memory limit in docker run
docker run --memory=2g ...
```

### Database corruption
```bash
# 1. Try integrity check
sqlite3 ~/pmo-data/pmo.db "PRAGMA integrity_check"

# 2. If corrupt, try to recover
sqlite3 ~/pmo-data/pmo.db ".recover" > recovery.sql 2>&1
head -50 recovery.sql

# 3. Last resort: restore from backup
```

### Frontend blank page
```bash
# 1. Check dist exists
docker exec pmo-app ls /app/frontend/dist/

# 2. If missing, rebuild image
docker build -t pmo-mvp:latest ~/pmo-project
docker stop pmo-app && docker rm pmo-app
docker run -d --name pmo-app -p 3000:3000 \
  -v ~/pmo-data:/app/backend/data pmo-mvp:latest
```

### Login fails for all users
```bash
# Check if users table intact
sqlite3 ~/pmo-data/pmo.db "SELECT id, email FROM users LIMIT 5"

# Check JWT secret / token config
docker exec pmo-app env | grep -i secret
docker exec pmo-app env | grep -i token

# Restart container
docker restart pmo-app
```

---

## 📈 Performance tuning

### SQLite optimization
```sql
-- Apply recommended pragmas (done in init.js, but can re-apply)
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = -20000;  -- 20MB cache
PRAGMA temp_store = MEMORY;
PRAGMA mmap_size = 268435456;  -- 256MB mmap
```

### PostgreSQL optimization (if using PG)
```sql
-- In postgresql.conf
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 16MB
maintenance_work_mem = 128MB
max_connections = 100
```

### Nginx caching (if using nginx reverse proxy)
```nginx
# Cache static frontend
location ~* \.(js|css|png|jpg|svg|woff2)$ {
  expires 1y;
  add_header Cache-Control "public, immutable";
}

# Don't cache API
location /api/ {
  proxy_pass http://localhost:3000;
  add_header Cache-Control "no-store";
}
```

---

## 🚨 Incident response

### Severity 1: App completely down
1. Check `docker ps` - container running?
2. `docker logs pmo-app` - error message?
3. `curl localhost:3000/api/health` - responds?
4. If not, restart: `docker restart pmo-app`
5. If still down, restore from backup

### Severity 2: One feature broken
1. Identify affected endpoint (check audit log, error rate)
2. Reproduce: `curl` the endpoint
3. Check code: which file/function?
4. Fix locally → rebuild → redeploy
5. Test, then communicate to user

### Severity 3: Performance degraded
1. Check `docker stats`, `htop`
2. Check DB: `sqlite3 ... "PRAGMA stats"`
3. Check recent ingest (large file?)
4. Vacuum DB if needed
5. If persistent, scale up server

### Severity 4: User can't login
1. Check user exists: `sqlite3 ... "SELECT * FROM users WHERE email = ?"`
2. Check `is_active = 1`
3. Try password reset
4. If `session_token` corrupted, clear it

---

## 📋 Maintenance windows

### Weekly (Sunday 2 AM)
- Backup DB + uploads
- Vacuum SQLite
- Check disk usage

### Monthly (1st Sunday)
- Update system packages
- Review audit log for anomalies
- Archive old uploads (>90 days)
- Review user list, deactivate inactive

### Quarterly
- Test restore from backup
- Review and rotate API keys
- Capacity planning
- Security audit

---

## 📞 Emergency contacts

- **Server admin:** [your contact]
- **Database admin:** [your contact]
- **Cloudflare account owner:** [your contact]
- **PMO dev team:** [your contact]

Save these in your incident response doc.

---

## 📚 Related docs

- [CODEBASE.md](CODEBASE.md) - file/function reference
- [ARCHITECTURE.md](ARCHITECTURE.md) - system design
- [SETUP_FOR_CLIENT.md](SETUP_FOR_CLIENT.md) - deployment
- [USER_GUIDE.md](USER_GUIDE.md) - end-user docs
- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) - dev workflow
</content>
