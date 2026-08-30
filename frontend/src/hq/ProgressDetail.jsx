// UI-005: Progress Detail (mục 7)
import { useEffect, useState } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { projects, construction, exportApi } from '../api/index.js';
import { getToken } from '../api/index.js';
import { ICON } from '../icons.jsx';
import { HEALTH } from '../constants.js';

export default function ProgressDetail() {
  const [params] = useSearchParams();
  const nav = useNavigate();
  const projectId = params.get('project');
  const initialZone = params.get('zone') || '';
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [allProjects, setAllProjects] = useState([]);
  const [selectedProject, setSelectedProject] = useState(projectId);
  const [zone, setZone] = useState(initialZone);
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    projects.list().then(list => {
      setAllProjects(list);
      if (!selectedProject && list[0]) setSelectedProject(list[0].id);
    });
  }, []);

  useEffect(() => {
    if (!selectedProject) return;
    setLoading(true);
    construction.schedule(selectedProject, { zone, search: search || undefined, status: statusFilter || undefined })
      .then(items => { setItems(items); setLoading(false); });
  }, [selectedProject, zone, search, statusFilter]);

  function healthOf(item) {
    const pct = item.progress_pct || 0;
    if (pct >= 1) return HEALTH.ON_TRACK;
    if (item.plan_end_date && new Date(item.plan_end_date) < new Date()) return HEALTH.OVERDUE;
    if (pct >= 0.7) return HEALTH.WATCH;
    return HEALTH.BEHIND;
  }

  async function download() {
    const r = await fetch(exportApi.constructionSchedule(selectedProject), {
      headers: { Authorization: `Bearer ${getToken()}` }
    });
    const blob = await r.blob();
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `construction-schedule-${selectedProject}.xlsx`;
    a.click();
  }

  // Zone options
  const zones = Array.from(new Set(items.map(i => i.zone_code))).sort();

  // KPI strip
  const total = items.length;
  const done = items.filter(i => (i.progress_pct || 0) >= 1).length;
  const overdue = items.filter(i => healthOf(i) === HEALTH.OVERDUE).length;
  const behind = items.filter(i => healthOf(i) === HEALTH.BEHIND).length;

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Progress Detail</h1>
          <div className="meta">Construction schedule · {total} items · {zones.length} zones</div>
        </div>
        <div className="page-header-right">
          <button className="btn btn-secondary" onClick={download}><ICON.download size={13} />Export Excel</button>
        </div>
      </div>

      <div className="filter-bar">
        <label>Project</label>
        <select value={selectedProject || ''} onChange={e => { setSelectedProject(Number(e.target.value)); setZone(''); }}>
          {allProjects.map(p => <option key={p.id} value={p.id}>{p.code}</option>)}
        </select>
        <label>Zone</label>
        <select value={zone} onChange={e => setZone(e.target.value)}>
          <option value="">All</option>
          {zones.map(z => <option key={z} value={z}>{z}</option>)}
        </select>
        <label>Status</label>
        <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
          <option value="">All</option>
          <option value="DONE">Done</option>
          <option value="PENDING">Pending</option>
        </select>
        <input
          placeholder="Search by name..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          style={{ flex: 1, minWidth: 180 }}
        />
      </div>

      <div className="stat-strip">
        <div className="stat"><div className="label">Total</div><div className="value">{total}</div></div>
        <div className="stat"><div className="label">Done</div><div className="value" style={{ color: 'var(--c-on-track)' }}>{done}</div></div>
        <div className="stat"><div className="label">In progress</div><div className="value" style={{ color: 'var(--c-watch)' }}>{total - done - overdue}</div></div>
        <div className="stat"><div className="label">Overdue</div><div className="value" style={{ color: 'var(--c-behind)' }}>{overdue}</div></div>
        <div className="stat"><div className="label">Behind</div><div className="value" style={{ color: 'var(--c-behind)' }}>{behind}</div></div>
        <div className="stat"><div className="label">Completion</div><div className="value">{total > 0 ? Math.round(done / total * 100) : 0}%</div></div>
      </div>

      <div className="data-table">
        <div className="data-table-header">
          <h2>Items</h2>
          <div className="filters">
            <span style={{ fontSize: 11, color: 'var(--c-text-2)' }}>Click row để xem issues</span>
          </div>
        </div>
        {loading ? <div className="empty">Loading...</div> :
         items.length === 0 ? <div className="empty">Chưa có dữ liệu. Upload file "TĐ [zone].xlsx".</div> :
        <div className="data-table-body">
          <table>
            <thead>
              <tr>
                <th>Zone</th>
                <th>Level</th>
                <th>Name</th>
                <th>Source sheet</th>
                <th className="num">Progress</th>
                <th>Plan end</th>
                <th>Status</th>
                <th>Health</th>
              </tr>
            </thead>
            <tbody>
              {items.slice(0, 500).map(item => {
                const h = healthOf(item);
                const cls = h === HEALTH.OVERDUE || h === HEALTH.CRITICAL ? 'critical' : h === HEALTH.BEHIND ? 'exception' : '';
                return (
                  <tr key={item.id} className={cls} onClick={() => nav(`/hq/issues?item=${item.id}`)} style={{ cursor: 'pointer' }}>
                    <td><code>{item.zone_code}</code></td>
                    <td>{item.level_roman || item.level_arabic || '—'}</td>
                    <td style={{ maxWidth: 320, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.name_vi || '—'}</td>
                    <td style={{ color: 'var(--c-text-2)', fontSize: 11 }}>{item.source_sheet || '—'}</td>
                    <td className="num">
                      <div className="cell-bar" style={{ display: 'inline-flex', minWidth: 100 }}>
                        <div className="bar"><div className="fill" style={{ width: `${(item.progress_pct || 0) * 100}%` }} /></div>
                        <span style={{ minWidth: 30 }}>{item.progress_pct ? Math.round(item.progress_pct * 100) : 0}%</span>
                      </div>
                    </td>
                    <td style={{ fontSize: 12 }}>{item.plan_end_date || '—'}</td>
                    <td><span className={`badge workflow-${item.status || 'DRAFT'}`}>{item.status || 'DRAFT'}</span></td>
                    <td><span className={`badge health-${h}`}>{h.replace('_', ' ')}</span></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>}
      </div>
    </div>
  );
}
