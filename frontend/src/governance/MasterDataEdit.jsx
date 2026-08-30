// UI-018: Master Data Edit
import { useSearchParams, useNavigate } from 'react-router-dom';
import { ICON } from '../icons.jsx';

export default function MasterDataEdit() {
  const [params] = useSearchParams();
  const nav = useNavigate();
  const resource = params.get('r') || 'subcontractors';
  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Edit · {resource}</h1>
          <div className="meta">Tạo / sửa master data record</div>
        </div>
        <div className="page-header-right">
          <button className="btn btn-secondary" onClick={() => nav(-1)}>Hủy</button>
          <button className="btn"><ICON.check size={13} />Lưu</button>
        </div>
      </div>
      <div className="card empty" style={{ padding: 40 }}>
        TODO: mục 38 - Create/Edit form chưa implement cho MVP.<br />
        Cần BA quyết định fields per resource, validation rules, auto IDs (Material ID 12 chars).
      </div>
    </div>
  );
}
