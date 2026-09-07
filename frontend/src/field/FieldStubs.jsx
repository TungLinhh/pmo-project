// Field stubs cho Material, Manpower, Issue, Review, Sync, WBS
// Updated: gọi API thật cho material_submittals, area_hierarchy, issues (mục 43.4/43.8)
import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { projects, issues as issuesApi } from '../api/index.js';
import { ICON } from '../icons.jsx';

// ===== Material Usage (mục 43.4) =====
export function FieldMaterial() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  useEffect(() => {
    fetch('/api/projects/1/materials?limit=20', { headers: { Authorization: `Bearer ${localStorage.getItem('pmo_token')}` }})
      .then(r => r.json()).then(d => { setItems(Array.isArray(d) ? d.slice(0, 10) : []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);
  return (
    <div>
      <div className="field-card">
        <h2>Material sử dụng hôm nay</h2>
        <p style={{ color: 'var(--c-text-2)', fontSize: 12, marginBottom: 12 }}>Ghi nhận vật tư tại công trường</p>
        <div className="field-stat"><span className="k">Có sẵn trong DB</span><span className="v">{loading ? '...' : items.length} mã</span></div>
        <div className="field-stat"><span className="k">Đã ghi nhận hôm nay</span><span className="v">0</span></div>
        <button className="field-button" style={{ marginTop: 12 }} onClick={() => navigate('/field/wbs')}>
          <ICON.plus size={14} />Thêm vật tư (chọn WBS)
        </button>
        {!loading && items.length > 0 && (
          <ul className="field-list" style={{ marginTop: 12 }}>
            {items.slice(0, 3).map(m => (
              <li key={m.id}>
                <div>
                  <div className="label">{m.name_vi || m.material_code}</div>
                  <div className="meta">#{m.material_code} · zone {m.zone_id}</div>
                </div>
                <span className="v">{m.progress_pct || 0}%</span>
              </li>
            ))}
          </ul>
        )}
        <p className="empty" style={{ marginTop: 16, fontSize: 11 }}>
          Material submittal: tạo qua HQ Procurement. Field chỉ ghi nhận usage hằng ngày.
        </p>
      </div>
    </div>
  );
}

export function FieldManpower() {
  return (
    <div>
      <div className="field-card">
        <h2>Manpower</h2>
        <p style={{ color: 'var(--c-text-2)', fontSize: 12, marginBottom: 12 }}>Số lượng công nhân theo tổ đội</p>
        <div className="field-stat"><span className="k">Tổng số công nhân (từ daily)</span><span className="v">32</span></div>
        <div className="field-stat"><span className="k">Tổ đội hiện tại</span><span className="v">3</span></div>
        <button className="field-button" style={{ marginTop: 12 }}><ICON.plus size={14} />Thêm tổ đội</button>
        <p className="empty" style={{ marginTop: 16, fontSize: 11 }}>
          32 manpower records từ daily reports đã ingest. UI chưa wire với API.
        </p>
      </div>
    </div>
  );
}

// ===== Issue / Photo (mục 6.5) =====
export function FieldIssue() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    issuesApi.list(1).then(d => { setItems(Array.isArray(d) ? d.slice(0, 5) : []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);
  return (
    <div>
      <div className="field-card">
        <h2>Issue / Photo</h2>
        <p style={{ color: 'var(--c-text-2)', fontSize: 12, marginBottom: 12 }}>Báo cáo vấn đề kèm ảnh</p>
        <div className="field-stat"><span className="k">Issues open (project 1)</span><span className="v">{loading ? '...' : items.length}</span></div>
        <button className="field-button"><ICON.camera size={14} />Chụp ảnh</button>
        <button className="field-button secondary" onClick={() => alert('Demo: tạo issue mới — sẽ route về /hq/issues trong production')}>
          <ICON.edit size={14} />Mô tả vấn đề
        </button>
        {!loading && items.length > 0 && (
          <ul className="field-list" style={{ marginTop: 12 }}>
            {items.slice(0, 3).map(it => (
              <li key={it.id}>
                <div>
                  <div className="label">{it.title}</div>
                  <div className="meta">{it.severity} · {it.status}</div>
                </div>
                <span className="badge" style={{ fontSize: 10 }}>{it.severity}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}

export function FieldReview() {
  const { id } = useParams();
  return (
    <div>
      <div className="field-card">
        <h2>Review / Submit #{id}</h2>
        <p style={{ color: 'var(--c-text-2)', fontSize: 12, marginBottom: 12 }}>Kiểm tra trước khi gửi</p>
        <div style={{ padding: 12, background: 'var(--c-surface-2)', border: '1px solid var(--c-border)', borderRadius: 6, marginBottom: 12 }}>
          <div className="field-stat"><span className="k">Ngày</span><span className="v">{new Date().toLocaleDateString('vi-VN')}</span></div>
          <div className="field-stat"><span className="k">Trạng thái</span><span className="v"><span className="badge workflow-DRAFT">DRAFT</span></span></div>
        </div>
        <button className="field-button"><ICON.arrow size={14} />Gửi duyệt (Submit)</button>
        <button className="field-button secondary"><ICON.edit size={14} />Sửa lại</button>
      </div>
    </div>
  );
}

// ===== Sync Queue (mục 43.7) =====
export function FieldSync() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    fetch('/api/sync/queue', { headers: { Authorization: `Bearer ${localStorage.getItem('pmo_token')}` }})
      .then(r => r.json()).then(d => { setItems(Array.isArray(d) ? d : []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);
  return (
    <div>
      <div className="field-card">
        <h2>Offline / Sync Queue</h2>
        <p style={{ color: 'var(--c-text-2)', fontSize: 12, marginBottom: 12 }}>Trạng thái đồng bộ (mục 43.7 - last-write-wins)</p>
        <ul className="field-list">
          <li>
            <div>
              <div className="label">Network</div>
              <div className="meta">Hiện tại</div>
            </div>
            <span className="badge" style={{ background: navigator.onLine ? 'var(--c-on-track-bg)' : 'var(--c-behind-bg)', color: navigator.onLine ? 'var(--c-on-track)' : 'var(--c-behind)' }}>
              {navigator.onLine ? 'ONLINE' : 'OFFLINE'}
            </span>
          </li>
          <li>
            <div>
              <div className="label">Trong queue</div>
              <div className="meta">Items chờ sync</div>
            </div>
            <span className="v">{loading ? '...' : items.length}</span>
          </li>
          <li>
            <div>
              <div className="label">Conflicts (server thắng)</div>
              <div className="meta">Last-write-wins log</div>
            </div>
            <span className="v">{items.filter(i => i.conflict_resolution === 'SERVER_NEWER' || i.conflict_resolution === 'SERVER').length}</span>
          </li>
        </ul>
        {!loading && items.length > 0 && (
          <ul className="field-list" style={{ marginTop: 12 }}>
            {items.slice(0, 3).map(it => (
              <li key={it.id}>
                <div>
                  <div className="label" style={{ fontSize: 11 }}>{it.resource_type} #{it.server_record_id || '?'}</div>
                  <div className="meta">{it.conflict_resolution || 'NONE'}</div>
                </div>
                <span className="badge" style={{ fontSize: 10 }}>{it.status || 'PENDING'}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}

// ===== Project / Area hierarchy (mục 43.8) =====
export function ProjectWbsSelection() {
  const [step, setStep] = useState(1);
  const [projectList, setProjectList] = useState([]);
  const [hierarchy, setHierarchy] = useState([]);
  const [selected, setSelected] = useState(null);
  useEffect(() => {
    projects.list().then(d => setProjectList(Array.isArray(d) ? d : [])).catch(() => {});
  }, []);
  useEffect(() => {
    if (step === 2 && selected) {
      fetch(`/api/projects/${selected}/area-hierarchy`, { headers: { Authorization: `Bearer ${localStorage.getItem('pmo_token')}` }})
        .then(r => r.json()).then(d => setHierarchy(Array.isArray(d) ? d : [])).catch(() => {});
    }
  }, [step, selected]);
  return (
    <div>
      <div className="field-card">
        <h2>Project / Area</h2>
        {step === 1 ? (
          <>
            <p style={{ color: 'var(--c-text-2)', fontSize: 12, marginBottom: 12 }}>Bước 1: Chọn dự án ({projectList.length} projects)</p>
            {projectList.map(p => (
              <button key={p.id} className="field-button" onClick={() => { setSelected(p.id); setStep(2); }}>
                {p.code} <span style={{ fontSize: 11, opacity: 0.7 }}>· {p.name_vi || p.name_en}</span>
              </button>
            ))}
            {projectList.length === 0 && <div className="empty">Đang tải...</div>}
          </>
        ) : (
          <>
            <p style={{ color: 'var(--c-text-2)', fontSize: 12, marginBottom: 12 }}>
              Bước 2: Chọn khu vực (mục 43.8 - 6 cấp) · {hierarchy.length} nodes
            </p>
            {hierarchy.filter(n => n.level === 'zone').map(z => (
              <button key={z.id} className="field-button secondary" onClick={() => setStep(3)}>
                {z.code} <span style={{ fontSize: 11, opacity: 0.7 }}>· {z.name_vi || ''}</span>
              </button>
            ))}
            {hierarchy.filter(n => n.level === 'zone').length === 0 && <div className="empty">Không có zone nào.</div>}
            <button className="field-button" style={{ marginTop: 12, background: 'var(--c-surface-2)' }} onClick={() => setStep(1)}>
              ← Quay lại
            </button>
            <p className="empty" style={{ marginTop: 16, fontSize: 11 }}>
              Hierarchy hiện có: project + zone. Building/Floor/Area NULL (chưa có data).
            </p>
          </>
        )}
      </div>
    </div>
  );
}
