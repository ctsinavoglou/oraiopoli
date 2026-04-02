import { LogOut, User } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';

export default function Topbar() {
  const { user, logout } = useAuth();

  return (
    <header style={{
      height: 60, background: 'var(--white)', borderBottom: '1px solid var(--gray-200)',
      display: 'flex', alignItems: 'center', justifyContent: 'flex-end',
      padding: '0 24px', gap: 16, boxShadow: 'var(--shadow)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 34, height: 34, borderRadius: '50%', background: 'var(--primary-light)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)',
        }}>
          <User size={18} />
        </div>
        <div>
          <div style={{ fontSize: '0.85rem', fontWeight: 600 }}>{user?.fullName}</div>
          <div style={{ fontSize: '0.7rem', color: 'var(--gray-400)' }}>{user?.role}</div>
        </div>
      </div>
      <button
        onClick={logout}
        style={{
          display: 'flex', alignItems: 'center', gap: 6,
          background: 'none', border: 'none', color: 'var(--gray-500)',
          fontSize: '0.8rem', fontWeight: 500, padding: '6px 10px', borderRadius: 6,
        }}
      >
        <LogOut size={16} /> Logout
      </button>
    </header>
  );
}

