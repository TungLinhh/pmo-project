// UI-019: Approval Center - wired với transition API thật
// 3 loại pending: shop_drawings (REVIEW), material_submittals (SUBMITTED), payment_requests (PENDING)
import { useEffect, useState } from 'react';
import { projects, shopApi, materials, issues, getToken } from '../api/index.js';
import { toast } from '../components/Toast.jsx';
import { ICON } from '../icons.jsx';

export default function Approval() {
  const [shopItems, setShopItems] = useState([]);
  const [submittalItems, setSubmittalItems] = useState([]);
  const [paymentItems, setPaymentItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [rejectModal, setRejectModal] = useState(null); // { type, id, label }
  const [rejectReason, setRejectReason] = useState('');
  const [busyId, setBusyId] = useState(null);
  const [detailModal, setDetailModal] = useState(null);

  async function load() {
    setLoading(true);
    try {
      // Shop drawings in REVIEW
      const shopResp = await fetch('/api/projects/1/shop-drawings?status=REVIEW&limit=20', {
        headers: { Authorization: `Bearer ${getToken()}` }
      }).then(r => r.json()).catch(() => []);
      setShopItems(Array.isArray(shopResp) ? shopResp : []);

      // Material submittals
      const subResp = await materials.overdue(1).catch(() => []);
      // Submittals in SUBMITTED status — query separately
      const subAll = await fetch('/api/projects/1/material-submittals?status=SUBMITTED&limit=20', {
        headers: { Authorization: `Bearer ${getToken()}` }
      }).then(r => r.json()).catch(() => []);
      const allSub = [...(Array.isArray(subResp) ? subResp : []), ...(Array.isArray(subAll) ? subAll : [])];
      // Dedup by id
      const seen = new Set();
      setSubmittalItems(allSub.filter(x => { if (seen.has(x.id)) return false; seen.add(x.id); return true; }));

      // Payment requests PENDING
      const payResp = await fetch('/api/projects/1/payment-requests?status=PENDING&limit=20', {
        headers: { Authorization: `Bearer ${getToken()}` }
      }).then(r => r.json()).catch(() => []);
      setPaymentItems(Array.isArray(payResp) ? payResp : []);
    } catch (e) {
      toast.error('Lỗi tải approval list: ' + e.message);
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => { load(); }, []);

  // ===== Approve handlers =====
  async function approveShop(id) {
    setBusyId('shop-' + id);
    try {
      await shopApi.transition(id, 'APPROVED', '');
      toast.success('Shop drawing #' + id + ' đã APPROVED');
      setShopItems(arr => arr.filter(x => x.id !== id));
    } catch (e) {
      toast.error('Approve thất bại: ' + e.message);
    } finally { setBusyId(null); }
  }
  async function approveSubmittal(id) {
    setBusyId('sub-' + id);
    try {
      const r = await fetch('/api/material-submittals/' + id + '/approve', {
        method: 'POST',
        headers: { Authorization: `Bearer ${getToken()}`, 'Content-Type': 'application/json' }
      }).then(r => r.json());
      if (r.error) throw new Error(r.error);
      toast.success('Material submittal #' + id + ' đã APPROVED');
      setSubmittalItems(arr => arr.filter(x => x.id !== id));
    } catch (e) {
      toast.error('Approve thất bại: ' + e.message);
    } finally { setBusyId(null); }
  }
  async function approvePayment(id) {
    setBusyId('pay-' + id);
    try {
      const r = await fetch('/api/payment-requests/' + id, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${getToken()}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'APPROVED' })
      }).then(r => r.json());
      if (r.error) throw new Error(r.error);
      toast.success('Payment request #' + id + ' đã APPROVED');
      setPaymentItems(arr => arr.filter(x => x.id !== id));
    } catch (e) {
      toast.error('Approve thất bại: ' + e.message);
    } finally { setBusyId(null); }
  }

  // ===== Reject handlers (modal for reason) =====
  function openReject(type, id, label) {
    setRejectModal({ type, id, label });
    setRejectReason('');
  }
  async function submitReject() {
    if (!rejectReason.trim()) {
      toast.error('Vui lòng nhập lý do reject');
      return;
    }
    const { type, id } = rejectModal;
    setBusyId(type + '-' + id);
    try {
      if (type === 'shop') {
        await shopApi.transition(id, 'REJECTED', rejectReason);
        toast.success('Shop drawing #' + id + ' đã REJECTED');
        setShopItems(arr => arr.filter(x => x.id !== id));
      } else if (type === 'submittal') {
        await materials.reject(id, rejectReason);
        toast.success('Submittal #' + id + ' đã REJECTED');
        setSubmittalItems(arr => arr.filter(x => x.id !== id));
      } else if (type === 'payment') {
        const r = await fetch('/api/payment-requests/' + id, {
          method: 'PUT',
          headers: { Authorization: `Bearer ${getToken()}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({ status: 'REJECTED', notes: rejectReason })
        }).then(r => r.json());
        if (r.error) throw new Error(r.error);
        toast.success('Payment #' + id + ' đã REJECTED');
        setPaymentItems(arr => arr.filter(x => x.id !== id));
      }
      setRejectModal(null);
    } catch (e) {
      toast.error('Reject thất bại: ' + e.message);
    } finally { setBusyId(null); }
  }

  // ===== Detail =====
  async function openDetail(type, id) {
    setDetailModal({ type, id, data: null, loading: true });
    try {
      let url = null;
      if (type === 'shop') url = '/api/shop-drawings/' + id;
      else if (type === 'submittal') url = '/api/material-submittals/' + id;
      else if (type === 'payment') url = '/api/payment-requests/' + id;
      if (!url) return;
      const r = await fetch(url, { headers: { Authorization: `Bearer ${getToken()}` } }).then(r => r.json());
      setDetailModal({ type, id, data: r, loading: false });
    } catch (e) {
      setDetailModal({ type, id, data: { error: e.message }, loading: false });
    }
  }

  const totalPending = shopItems.length + submittalItems.length + paymentItems.length;

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Approval Center</h1>
          <div className="meta">{totalPending} items chờ duyệt {loading ? '(đang tải...)' : ''}</div>
        </div>
        <button className="btn btn-secondary" onClick={load} disabled={loading}><ICON.refresh size={12} />Refresh</button>
      </div>

      <div className="stat-strip">
        <div className="stat"><div className="label">Pending</div><div className="value" style={{ color: 'var(--c-watch)' }}>{totalPending}</div></div>
        <div className="stat"><div className="label">Shop review</div><div className="value">{shopItems.length}</div></div>
        <div className="stat"><div className="label">Material submittal</div><div className="value">{submittalItems.length}</div></div>
        <div className="stat"><div className="label">Payment request</div><div className="value">{paymentItems.length}</div></div>
      </div>

      {/* Section: Shop drawings */}
      <h2 style={{ fontSize: 14, marginTop: 20, marginBottom: 8 }}>Shop Drawing (REVIEW → APPROVE/REJECT)</h2>
      <div className="data-table">
        {loading ? <div className="empty">Đang tải...</div> :
         shopItems.length === 0 ? <div className="empty">Không có shop drawing nào đang REVIEW</div> :
         shopItems.map(i => (
          <div key={i.id} style={{ padding: 14, borderBottom: '1px solid var(--c-border)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 10 }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                  <span className="badge" style={{ background: 'var(--c-surface-2)', color: 'var(--c-text-2)' }}>Shop</span>
                  <span style={{ fontWeight: 600, fontSize: 13 }}>{i.drawing_code || i.name_vi || '#' + i.id}</span>
                </div>
                <div style={{ color: 'var(--c-text-2)', fontSize: 12 }}>Submitted by: {i.submitted_by || '—'} · Revision: {i.revision || 0}</div>
              </div>
              <span className={`badge workflow-${i.status || 'REVIEW'}`}>{i.status || 'REVIEW'}</span>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button className="btn" onClick={() => approveShop(i.id)} disabled={busyId === 'shop-' + i.id}>
                <ICON.check size={12} />{busyId === 'shop-' + i.id ? '...' : 'Approve'}
              </button>
              <button className="btn btn-secondary" onClick={() => openReject('shop', i.id, i.drawing_code || 'Shop #' + i.id)}>
                <ICON.x size={12} />Reject
              </button>
              <button className="btn btn-secondary" onClick={() => openDetail('shop', i.id)}>
                <ICON.eye size={12} />View detail
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Section: Material submittals */}
      <h2 style={{ fontSize: 14, marginTop: 20, marginBottom: 8 }}>Material Submittal (SUBMITTED → APPROVE/REJECT)</h2>
      <div className="data-table">
        {loading ? <div className="empty">Đang tải...</div> :
         submittalItems.length === 0 ? <div className="empty">Không có material submittal nào đang chờ duyệt</div> :
         submittalItems.map(i => (
          <div key={'sub-' + i.id} style={{ padding: 14, borderBottom: '1px solid var(--c-border)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 10 }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                  <span className="badge" style={{ background: 'var(--c-surface-2)', color: 'var(--c-text-2)' }}>Submittal</span>
                  <span style={{ fontWeight: 600, fontSize: 13 }}>{i.submittal_code || '#' + i.id}</span>
                </div>
                <div style={{ color: 'var(--c-text-2)', fontSize: 12 }}>
                  Revision: {i.revision_number || 0} · SLA: {i.sla_deadline || 'N/A'} {i.sla_deadline && new Date(i.sla_deadline) < new Date() ? '⚠️ OVERDUE' : ''}
                </div>
              </div>
              <span className={`badge workflow-${i.status || 'SUBMITTED'}`}>{i.status || 'SUBMITTED'}</span>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button className="btn" onClick={() => approveSubmittal(i.id)} disabled={busyId === 'sub-' + i.id}>
                <ICON.check size={12} />{busyId === 'sub-' + i.id ? '...' : 'Approve'}
              </button>
              <button className="btn btn-secondary" onClick={() => openReject('submittal', i.id, i.submittal_code || 'Submittal #' + i.id)}>
                <ICON.x size={12} />Reject
              </button>
              <button className="btn btn-secondary" onClick={() => openDetail('submittal', i.id)}>
                <ICON.eye size={12} />View detail
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Section: Payment requests */}
      <h2 style={{ fontSize: 14, marginTop: 20, marginBottom: 8 }}>Payment Request (PENDING → APPROVE/REJECT)</h2>
      <div className="data-table">
        {loading ? <div className="empty">Đang tải...</div> :
         paymentItems.length === 0 ? <div className="empty">Không có payment request nào đang PENDING</div> :
         paymentItems.map(i => (
          <div key={'pay-' + i.id} style={{ padding: 14, borderBottom: '1px solid var(--c-border)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 10 }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                  <span className="badge" style={{ background: 'var(--c-surface-2)', color: 'var(--c-text-2)' }}>Payment</span>
                  <span style={{ fontWeight: 600, fontSize: 13 }}>{i.request_no || '#' + i.id}</span>
                </div>
                <div style={{ color: 'var(--c-text-2)', fontSize: 12 }}>
                  Amount: {i.amount?.toLocaleString() || 0} · Retention: {i.retention_amount?.toLocaleString() || 0} · Due: {i.due_date || 'N/A'}
                </div>
              </div>
              <span className={`badge workflow-${i.status || 'PENDING'}`}>{i.status || 'PENDING'}</span>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button className="btn" onClick={() => approvePayment(i.id)} disabled={busyId === 'pay-' + i.id}>
                <ICON.check size={12} />{busyId === 'pay-' + i.id ? '...' : 'Approve'}
              </button>
              <button className="btn btn-secondary" onClick={() => openReject('payment', i.id, i.request_no || 'Payment #' + i.id)}>
                <ICON.x size={12} />Reject
              </button>
              <button className="btn btn-secondary" onClick={() => openDetail('payment', i.id)}>
                <ICON.eye size={12} />View detail
              </button>
            </div>
          </div>
        ))}
      </div>

      {totalPending === 0 && !loading && (
        <div className="empty" style={{ marginTop: 30, padding: 40, textAlign: 'center', color: 'var(--c-text-2)' }}>
          ✓ Tất cả approval items đã xử lý
        </div>
      )}

      {/* Reject modal */}
      {rejectModal && (
        <div className="modal-backdrop" onClick={() => setRejectModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>Reject: {rejectModal.label}</h3>
            <p className="meta">Lý do reject (bắt buộc) sẽ được lưu vào audit log:</p>
            <textarea value={rejectReason} onChange={e => setRejectReason(e.target.value)} rows={4} style={{ width: '100%', padding: 8, border: '1px solid var(--c-border)', borderRadius: 6, fontFamily: 'inherit' }} placeholder="Vd: Thiếu dimension kỹ thuật..." />
            <div style={{ display: 'flex', gap: 8, marginTop: 12, justifyContent: 'flex-end' }}>
              <button className="btn btn-secondary" onClick={() => setRejectModal(null)}>Hủy</button>
              <button className="btn" style={{ background: 'var(--c-critical)', color: '#fff' }} onClick={submitReject} disabled={busyId}>
                {busyId ? 'Đang xử lý...' : 'Xác nhận Reject'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Detail modal */}
      {detailModal && (
        <div className="modal-backdrop" onClick={() => setDetailModal(null)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 600 }}>
            <h3>Detail: {detailModal.type} #{detailModal.id}</h3>
            {detailModal.loading ? <div className="empty">Đang tải...</div> :
             detailModal.data?.error ? <div className="empty" style={{ color: 'var(--c-critical)' }}>Lỗi: {detailModal.data.error}</div> :
             !detailModal.data ? <div className="empty">Không có dữ liệu chi tiết</div> :
             (
              <pre style={{ background: 'var(--c-surface-2)', padding: 12, borderRadius: 6, fontSize: 12, maxHeight: 400, overflow: 'auto' }}>
                {JSON.stringify(detailModal.data, null, 2)}
              </pre>
             )}
            <div style={{ marginTop: 12, textAlign: 'right' }}>
              <button className="btn btn-secondary" onClick={() => setDetailModal(null)}>Đóng</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
