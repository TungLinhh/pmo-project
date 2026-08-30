// Placeholders for unused pages (now Manpower has real component in hq/Manpower.jsx)
import { ICON } from '../icons.jsx';

// Re-export real Manpower from hq/Manpower.jsx
export { default as Manpower } from './Manpower.jsx';

export function Payment() {
  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Payment</h1>
          <div className="meta">Quản lý thanh toán NCC</div>
        </div>
      </div>
      <div className="empty" style={{ padding: 40 }}>
        TODO: mục 43.5 - Payment transaction model chưa chốt<br />
        (contract/invoice/payment request/retention/VAT/due date/status).<br /><br />
        Hiện có <code>payment_milestones</code> (41 rows) chưa migrate sang PG.
      </div>
    </div>
  );
}

export function Issues() {
  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Issues</h1>
          <div className="meta">Vấn đề phát sinh trong quá trình thi công</div>
        </div>
      </div>
      <div className="empty" style={{ padding: 40 }}>
        TODO: Issues chưa có schema. Cần BA quyết định fields<br />
        (issue type, severity, owner, due date, photos, status).
      </div>
    </div>
  );
}

export function AuditLog() {
  return <></>;  // re-export from governance
}
