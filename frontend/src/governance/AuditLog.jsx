// UI-020: Audit Log
export default function AuditLog() {
  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Audit Log</h1>
          <div className="meta">Lịch sử thay đổi dữ liệu</div>
        </div>
      </div>
      <div className="stat-strip">
        <div className="stat"><div className="label">Total events</div><div className="value">0</div></div>
        <div className="stat"><div className="label">Today</div><div className="value">0</div></div>
        <div className="stat"><div className="label">Critical actions</div><div className="value">0</div></div>
      </div>
      <div className="empty" style={{ padding: 60 }}>
        Bảng <code>audit_log</code> đã có schema (PG migration: ✅).<br />
        Cần trigger/hook tự động ghi log khi UPDATE/DELETE trên các bảng nghiệp vụ.<br />
        MVP: chưa có data.
      </div>
    </div>
  );
}
