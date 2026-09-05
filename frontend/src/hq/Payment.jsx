// Payment page (Mục 6.4) - dùng schema mới 43.5
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.5) - Payment transaction model
import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { projects, getToken } from '../api/index.js';
import { ICON } from '../icons.jsx';
import PieChart from '../components/PieChart.jsx';
import PieTooltip from '../components/PieTooltip.jsx';
import { toast } from '../components/Toast.jsx';
import ProjectPicker from '../components/ProjectPicker.jsx';

const STATUS_COLORS = {
  PENDING: 'var(--c-draft)',
  APPROVED: 'var(--c-submitted)',
  REJECTED: 'var(--c-behind)',
  PAID: 'var(--c-on-track)',
};

export default function Payment() {
  const [params] = useSearchParams();
  const [allProjects, setAllProjects] = useState([]);
  const [selectedProject, setSelectedProject] = useState(params.get('project'));
  const [contracts, setContracts] = useState([]);
  const [invoices, setInvoices] = useState({});  // contractId -> [invoices]
  const [paymentRequests, setPaymentRequests] = useState({});  // invoiceId -> [requests]
  const [loading, setLoading] = useState(false);
  const [hovered, setHovered] = useState(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [addForm, setAddForm] = useState({ contract_id: '', invoice_id: '', request_no: '', amount: '', retention_amount: 0, due_date: '' });
  const [addBusy, setAddBusy] = useState(false);

  useEffect(() => {
    projects.list().then(list => {
      setAllProjects(list);
      if (!selectedProject && list[0]) setSelectedProject(list[0].id);
    });
  }, []);

  useEffect(() => {
    if (!selectedProject) return;
    setLoading(true);
    fetch(`/api/projects/${selectedProject}/contracts`, { headers: { Authorization: `Bearer ${getToken()}` }})
      .then(r => r.json())
      .then(async cs => {
        setContracts(cs);
        const invs = {};
        const prs = {};
        for (const c of cs) {
          const list = await fetch(`/api/contracts/${c.id}/invoices`, { headers: { Authorization: `Bearer ${getToken()}` } }).then(r => r.json()).catch(() => []);
          invs[c.id] = list;
          for (const inv of list) {
            const reqs = await fetch(`/api/invoices/${inv.id}/payment-requests`, { headers: { Authorization: `Bearer ${getToken()}` } }).then(r => r.json()).catch(() => []);
            prs[inv.id] = reqs;
          }
        }
        setInvoices(invs);
        setPaymentRequests(prs);
        setLoading(false);
      });
  }, [selectedProject]);

  // KPI
  const allRequests = Object.values(paymentRequests).flat();
  const totalAmount = allRequests.reduce((s, r) => s + (r.amount || 0), 0);
  const totalRetention = allRequests.reduce((s, r) => s + (r.retention_amount || 0), 0);
  const paid = allRequests.filter(r => r.status === 'APPROVED' || r.status === 'PAID').length;
  const overdue = allRequests.filter(r => r.due_date && new Date(r.due_date) < new Date() && r.status !== 'APPROVED' && r.status !== 'PAID').length;

  const byStatus = {};
  allRequests.forEach(r => { byStatus[r.status || 'PENDING'] = (byStatus[r.status || 'PENDING'] || 0) + 1; });
  const pieData = Object.entries(byStatus).map(([label, value]) => ({
    label, value, color: STATUS_COLORS[label] || 'var(--c-draft)',
    breakdown: [{ k: 'Count', v: value }, { k: 'Tỉ lệ', v: allRequests.length > 0 ? `${Math.round(value / allRequests.length * 100)}%` : '0%' }],
  }));

  async function doAdd() {
    if (!addForm.contract_id || !addForm.invoice_id || !addForm.request_no || !addForm.amount) {
      toast.error('Vui lòng điền đủ: contract, invoice, request_no, amount');
      return;
    }
    setAddBusy(true);
    try {
      const r = await fetch(`/api/invoices/${addForm.invoice_id}/payment-requests`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${getToken()}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          request_no: addForm.request_no,
          request_date: new Date().toISOString().slice(0, 10),
          amount: Number(addForm.amount),
          retention_amount: Number(addForm.retention_amount) || 0,
          due_date: addForm.due_date || null,
        })
      }).then(r => r.json());
      if (r.error) throw new Error(r.error);
      toast.success('Đã tạo payment request: ' + addForm.request_no);
      setShowAddModal(false);
      setAddForm({ contract_id: '', invoice_id: '', request_no: '', amount: '', retention_amount: 0, due_date: '' });
      // Reload
      const list = await fetch(`/api/invoices/${addForm.invoice_id}/payment-requests`, { headers: { Authorization: `Bearer ${getToken()}` } }).then(r => r.json());
      setPaymentRequests({ ...paymentRequests, [addForm.invoice_id]: list });
    } catch (e) {
      toast.error('Lỗi: ' + e.message);
    } finally { setAddBusy(false); }
  }

  const totalFmt = (n) => (n / 1e9).toFixed(2);
  const availableInvoices = Object.entries(invoices).flatMap(([cid, invs]) => invs.filter(inv => String(inv.contract_id) === String(addForm.contract_id)).map(inv => ({ ...inv, contract_id: cid })));

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Payment</h1>
          <div className="meta">{contracts.length} contracts · {allRequests.length} payment requests · {totalFmt(totalAmount)} tỷ VND</div>
        </div>
        <div className="page-header-right">
          <button className="btn" onClick={() => setShowAddModal(true)}><ICON.plus size={13} />Add milestone</button>
        </div>
      </div>

      <div className="filter-bar">
        <label>Project</label>
        <ProjectPicker value={selectedProject} onChange={setSelectedProject} placeholder="Chọn dự án..." />
      </div>

      <div className="kpi-strip" style={{ gridTemplateColumns: 'repeat(4, 1fr)' }}>
        <div className="kpi-card">
          <div className="label">Total amount</div>
          <div className="value">{totalFmt(totalAmount)} tỷ</div>
          <div className="sub">Tổng {allRequests.length} payment requests</div>
        </div>
        <div className="kpi-card on-track">
          <div className="label">Approved</div>
          <div className="value">{paid}</div>
          <div className="sub">{totalAmount > 0 ? Math.round(paid / allRequests.length * 100) : 0}% số request</div>
        </div>
        <div className="kpi-card critical">
          <div className="label">Overdue</div>
          <div className="value">{overdue}</div>
          <div className="sub">Đã quá due_date</div>
        </div>
        <div className="kpi-card watch" onMouseEnter={() => setHovered('status')} onMouseLeave={() => setHovered(null)} style={{ position: 'relative' }}>
          <div className="label">By status</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            {pieData.length > 0 ? (
              <div className="pie-wrap">
                <PieChart data={pieData} size={64} thickness={14} centerText={`${paid}`} centerSub="paid" />
                {hovered === 'status' && <PieTooltip data={pieData} />}
              </div>
            ) : <div style={{ color: 'var(--c-text-3)' }}>—</div>}
          </div>
        </div>
      </div>

      {/* Contracts + Invoices + Payment Requests */}
      {loading ? <div className="empty">Loading...</div> :
       contracts.length === 0 ? <div className="empty">Chưa có contract. <a href="/hq/master-data?r=contracts">Upload Excel Contracts</a>.</div> :
       contracts.map(c => (
        <div key={c.id} className="section">
          <div className="section-title">
            <span>📄 {c.contract_no} — {c.contract_name}</span>
            <span style={{ fontSize: 12, color: 'var(--c-text-2)' }}>{(c.total_value / 1e9).toFixed(2)} tỷ · {c.signed_date || '—'}</span>
          </div>
          <div className="data-table">
            <div className="data-table-body">
              <table>
                <thead>
                  <tr>
                    <th>Invoice</th>
                    <th>Date</th>
                    <th className="num">Amount (VND)</th>
                    <th className="num">VAT</th>
                    <th>Payment Request</th>
                    <th className="num">Amount</th>
                    <th className="num">Retention (5%)</th>
                    <th>Due date</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {(invoices[c.id] || []).map(inv => {
                    const reqs = paymentRequests[inv.id] || [];
                    return reqs.length > 0 ? reqs.map((req, i) => (
                      <tr key={req.id}>
                        {i === 0 && (
                          <>
                            <td rowSpan={reqs.length}><code>{inv.invoice_no}</code></td>
                            <td rowSpan={reqs.length}>{inv.invoice_date || '—'}</td>
                            <td rowSpan={reqs.length} className="num">{(inv.amount || 0).toLocaleString('vi-VN')}</td>
                            <td rowSpan={reqs.length} className="num">{(inv.vat_amount || 0).toLocaleString('vi-VN')}</td>
                          </>
                        )}
                        <td><code>{req.request_no}</code></td>
                        <td className="num">{(req.amount || 0).toLocaleString('vi-VN')}</td>
                        <td className="num" style={{ color: 'var(--c-behind)' }}>{(req.retention_amount || 0).toLocaleString('vi-VN')}</td>
                        <td>{req.due_date || '—'}</td>
                        <td><span className={`badge workflow-${req.status || 'PENDING'}`}>{req.status || 'PENDING'}</span></td>
                      </tr>
                    )) : (
                      <tr key={inv.id}>
                        <td><code>{inv.invoice_no}</code></td>
                        <td>{inv.invoice_date || '—'}</td>
                        <td className="num">{(inv.amount || 0).toLocaleString('vi-VN')}</td>
                        <td className="num">{(inv.vat_amount || 0).toLocaleString('vi-VN')}</td>
                        <td colSpan={4} style={{ color: 'var(--c-text-2)', fontSize: 11 }}>Chưa có payment request</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
       ))
      }

      <p className="empty" style={{ marginTop: 16, fontSize: 11 }}>
        TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.5) - retention release workflow, multi-level approver.
      </p>

      {/* Add milestone modal */}
      {showAddModal && (
        <div className="modal-backdrop" onClick={() => !addBusy && setShowAddModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 520 }}>
            <h3>Add Payment Request (Milestone)</h3>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 12 }}>
              <label style={{ gridColumn: 'span 2' }}>
                <div style={{ fontSize: 11, color: 'var(--c-text-2)' }}>Contract *</div>
                <select value={addForm.contract_id} onChange={e => setAddForm({...addForm, contract_id: e.target.value, invoice_id: ''})} style={{ width: '100%', padding: 6 }}>
                  <option value="">-- Chọn contract --</option>
                  {contracts.map(c => <option key={c.id} value={c.id}>{c.contract_no} - {c.contract_name}</option>)}
                </select>
              </label>
              <label style={{ gridColumn: 'span 2' }}>
                <div style={{ fontSize: 11, color: 'var(--c-text-2)' }}>Invoice *</div>
                <select value={addForm.invoice_id} onChange={e => setAddForm({...addForm, invoice_id: e.target.value})} style={{ width: '100%', padding: 6 }} disabled={!addForm.contract_id}>
                  <option value="">-- Chọn invoice --</option>
                  {availableInvoices.map(inv => <option key={inv.id} value={inv.id}>{inv.invoice_no} ({inv.invoice_date})</option>)}
                </select>
              </label>
              <label style={{ gridColumn: 'span 2' }}>
                <div style={{ fontSize: 11, color: 'var(--c-text-2)' }}>Request No *</div>
                <input value={addForm.request_no} onChange={e => setAddForm({...addForm, request_no: e.target.value})} style={{ width: '100%', padding: 6 }} placeholder="REQ-2026-XXX" />
              </label>
              <label>
                <div style={{ fontSize: 11, color: 'var(--c-text-2)' }}>Amount (VND) *</div>
                <input type="number" value={addForm.amount} onChange={e => setAddForm({...addForm, amount: e.target.value})} style={{ width: '100%', padding: 6 }} />
              </label>
              <label>
                <div style={{ fontSize: 11, color: 'var(--c-text-2)' }}>Retention</div>
                <input type="number" value={addForm.retention_amount} onChange={e => setAddForm({...addForm, retention_amount: e.target.value})} style={{ width: '100%', padding: 6 }} />
              </label>
              <label style={{ gridColumn: 'span 2' }}>
                <div style={{ fontSize: 11, color: 'var(--c-text-2)' }}>Due date</div>
                <input type="date" value={addForm.due_date} onChange={e => setAddForm({...addForm, due_date: e.target.value})} style={{ width: '100%', padding: 6 }} />
              </label>
            </div>
            <div style={{ display: 'flex', gap: 8, marginTop: 16, justifyContent: 'flex-end' }}>
              <button className="btn btn-secondary" onClick={() => setShowAddModal(false)} disabled={addBusy}>Hủy</button>
              <button className="btn" onClick={doAdd} disabled={addBusy}>{addBusy ? '...' : 'Tạo'}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
