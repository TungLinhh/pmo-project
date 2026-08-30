// Field Daily Progress entry (mục 11)
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { projects, construction } from '../api/index.js';
import { ICON } from '../icons.jsx';

export default function DailyProgress() {
  const nav = useNavigate();
  const [allProjects, setAllProjects] = useState([]);
  const [selectedProject, setSelectedProject] = useState(null);
  const [zones, setZones] = useState([]);
  const [zone, setZone] = useState('');
  const [items, setItems] = useState([]);
  const [selectedItem, setSelectedItem] = useState(null);
  const [progress, setProgress] = useState(0);
  const [notes, setNotes] = useState('');

  useEffect(() => {
    projects.list().then(list => {
      setAllProjects(list);
      if (list[0]) setSelectedProject(list[0].id);
    });
  }, []);

  useEffect(() => {
    if (!selectedProject) return;
    construction.schedule(selectedProject).then(items => {
      const zs = Array.from(new Set(items.map(i => i.zone_code))).sort();
      setZones(zs);
      setItems(items);
    });
  }, [selectedProject]);

  const itemsForZone = items.filter(i => i.zone_code === zone);

  function save(status) {
    // TODO: POST /api/daily-reports (chưa implement)
    alert(`Báo cáo đã ${status}.\n\n- Project: ${selectedProject}\n- Zone: ${zone}\n- Item: ${items.find(i => i.id === Number(selectedItem))?.name_vi}\n- Progress: ${progress}%\n- Notes: ${notes}`);
    nav('/field/home');
  }

  return (
    <div>
      <div className="field-card">
        <h2>New Daily Progress</h2>

        <label className="field-label">Dự án</label>
        <select className="field-input" value={selectedProject || ''} onChange={e => setSelectedProject(Number(e.target.value))}>
          {allProjects.map(p => <option key={p.id} value={p.id}>{p.code} — {p.name_vi}</option>)}
        </select>

        <label className="field-label">Zone</label>
        <select className="field-input" value={zone} onChange={e => setZone(e.target.value)}>
          <option value="">— chọn zone —</option>
          {zones.map(z => <option key={z} value={z}>{z}</option>)}
        </select>

        {zone && (
          <>
            <label className="field-label">Hạng mục</label>
            <select className="field-input" value={selectedItem || ''} onChange={e => setSelectedItem(e.target.value)}>
              <option value="">— chọn hạng mục —</option>
              {itemsForZone.slice(0, 100).map(i => <option key={i.id} value={i.id}>{i.name_vi || '—'}</option>)}
            </select>

            <label className="field-label">Tiến độ (%)</label>
            <input
              type="number"
              className="field-input"
              min="0" max="100"
              value={progress}
              onChange={e => setProgress(Number(e.target.value))}
            />
            <div className="cell-bar" style={{ marginTop: 8 }}>
              <div className="bar"><div className="fill" style={{ width: `${progress}%` }} /></div>
              <span style={{ minWidth: 36, textAlign: 'right' }}>{progress}%</span>
            </div>

            <label className="field-label">Ghi chú</label>
            <textarea
              className="field-input"
              style={{ minHeight: 80, fontSize: 14 }}
              value={notes}
              onChange={e => setNotes(e.target.value)}
              placeholder="Vướng mắc, lưu ý..."
            />
          </>
        )}

        <div style={{ marginTop: 16, display: 'flex', flexDirection: 'column', gap: 8 }}>
          <button className="field-button secondary" disabled={!selectedItem} onClick={() => save('lưu nháp')}>
            Lưu nháp
          </button>
          <button className="field-button" disabled={!selectedItem} onClick={() => save('gửi duyệt')}>
            <ICON.arrow size={14} /> Gửi duyệt (Submit)
          </button>
        </div>
      </div>
    </div>
  );
}
