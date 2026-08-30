// UI-007: Notification Center
// TODO: mục 43.6 - channels chưa chốt
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ICON } from '../icons.jsx';
import { notifications, directives } from '../api/index.js';

function relativeTime(iso) {
  if (!iso) return '—';
  const date = new Date(iso.replace(' ', 'T') + 'Z');
  const diff = (Date.now() - date.getTime()) / 1000;
  if (diff < 60) return 'Vừa xong';
  if (diff < 3600) return `${Math.floor(diff / 60)} phút trước`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} giờ trước`;
  if (diff < 604800) return `${Math.floor(diff / 86400)} ngày trước`;
  return date.toLocaleString('vi-VN');
}

function navFor(n) {
  if (n.resource_type === 'issue' && n.resource_id) return `/hq/issues?item=${n.resource_id}`;
  if (n.resource_type === 'directive' && n.issue_id) return `/hq/issues?item=${n.issue_id}`;
  if (n.issue_id) return `/hq/issues?item=${n.issue_id}`;
  return '/hq';
}

export default function NotificationCenter() {
  const [data, setData] = useState({ items: [], counts: { total: 0, unread: 0, critical: 0, warning: 0 } });
  const [filter, setFilter] = useState('all');
  const nav = useNavigate();

  async function load() {
    const d = await notifications.list(filter === 'unread');
    setData(d);
  }
  useEffect(() => { load(); }, [filter]);

  const items = data.items;
  const c = data.counts;
  const filtered = filter === 'critical' ? items.filter(n => n.severity === 'critical') :
                    filter === 'warning' ? items.filter(n => n.severity === 'warning') :
                    filter === 'info' ? items.filter(n => n.severity === 'info') :
                    items;

  async function handleClick(n) {
    if (!n.is_read) {
      await notifications.markRead(n.id);
      load();
    }
    nav(navFor(n));
  }

  async function markAll() {
    await notifications.markAllRead();
    load();
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Notification Center</h1>
          <div className="meta">{c.unread} chưa đọc · {items.length} hiển thị · {c.critical} critical</div>
        </div>
        <div className="page-header-right">
          {c.unread > 0 && <button className="btn btn-secondary" onClick={markAll}>Đánh dấu tất cả đã đọc</button>}
        </div>
      </div>

      <div className="filter-bar">
        <label>Filter</label>
        <select value={filter} onChange={e => setFilter(e.target.value)}>
          <option value="all">All ({c.total})</option>
          <option value="unread">Unread ({c.unread})</option>
          <option value="critical">Critical ({items.filter(n => n.severity === 'critical').length})</option>
          <option value="warning">Warning ({items.filter(n => n.severity === 'warning').length})</option>
          <option value="info">Info ({items.filter(n => n.severity === 'info').length})</option>
        </select>
      </div>

      <div className="stat-strip">
        <div className="stat"><div className="label">Total</div><div className="value">{c.total}</div></div>
        <div className="stat"><div className="label">Unread</div><div className="value" style={{ color: 'var(--c-accent)' }}>{c.unread}</div></div>
        <div className="stat"><div className="label">Critical</div><div className="value" style={{ color: 'var(--c-critical)' }}>{c.critical}</div></div>
        <div className="stat"><div className="label">Warning</div><div className="value" style={{ color: 'var(--c-watch)' }}>{c.warning}</div></div>
        <div className="stat"><div className="label">Info</div><div className="value">{c.total - c.critical - c.warning}</div></div>
      </div>

      <div className="data-table">
        {filtered.length === 0 ? <div className="empty">Không có thông báo</div> :
          filtered.map(n => {
            const isCrit = n.severity === 'critical';
            const isWarn = n.severity === 'warning';
            return (
              <button
                key={n.id}
                onClick={() => handleClick(n)}
                style={{
                  padding: '12px 16px',
                  borderBottom: '1px solid #f1f5f9',
                  background: n.is_read ? 'var(--c-surface)' : (isCrit ? 'var(--c-critical-bg)' : isWarn ? 'var(--c-watch-bg)' : 'var(--c-primary-bg)'),
                  display: 'flex',
                  alignItems: 'flex-start',
                  gap: 12,
                  width: '100%',
                  textAlign: 'left',
                  cursor: 'pointer',
                  fontFamily: 'inherit',
                  borderLeft: n.is_read ? '3px solid transparent' : `3px solid ${isCrit ? 'var(--c-critical)' : isWarn ? 'var(--c-watch)' : 'var(--c-primary)'}`,
                }}
              >
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                    <div style={{ fontWeight: n.is_read ? 400 : 600, fontSize: 13 }}>{n.title}</div>
                    {!n.is_read && <span style={{ fontSize: 10, fontWeight: 600, color: isCrit ? 'var(--c-critical)' : isWarn ? 'var(--c-watch)' : 'var(--c-primary)' }}>NEW</span>}
                  </div>
                  {n.body && <div style={{ color: 'var(--c-text-2)', fontSize: 12.5 }}>{n.body}</div>}
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontSize: 11 }}>
                    <span style={{ color: 'var(--c-text-3)' }}>{relativeTime(n.created_at)}</span>
                    <code style={{ color: 'var(--c-text-3)' }}>{n.resource_type}{n.resource_id ? `:${n.resource_id}` : ''}</code>
                  </div>
                </div>
              </button>
            );
          })
        }
      </div>
      <p className="empty" style={{ marginTop: 16, fontSize: 11 }}>
        TODO: mục 43.6 - Notification channels (Email/Zalo OA/Telegram/Push) chưa chốt. MVP chỉ in-app.
      </p>
    </div>
  );
}
