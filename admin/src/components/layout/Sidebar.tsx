import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard, Users, FolderTree, Tag, Package, ShoppingCart,
  Image, Megaphone, Settings, ChevronLeft, ChevronRight,
} from 'lucide-react';
import { useState } from 'react';

const links = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/users', icon: Users, label: 'Users' },
  { to: '/categories', icon: FolderTree, label: 'Categories' },
  { to: '/brands', icon: Tag, label: 'Brands' },
  { to: '/products', icon: Package, label: 'Products' },
  { to: '/orders', icon: ShoppingCart, label: 'Orders' },
  { to: '/banners', icon: Image, label: 'Banners' },
  { to: '/promotions', icon: Megaphone, label: 'Promotions' },
  { to: '/settings', icon: Settings, label: 'Settings' },
];

export default function Sidebar() {
  const [collapsed, setCollapsed] = useState(false);

  return (
    <aside style={{
      width: collapsed ? 64 : 240, minHeight: '100vh', background: 'var(--primary)',
      color: '#fff', display: 'flex', flexDirection: 'column', transition: 'width .2s',
      position: 'fixed', top: 0, left: 0, zIndex: 100,
    }}>
      <div style={{
        padding: collapsed ? '16px 12px' : '16px 20px', display: 'flex',
        alignItems: 'center', justifyContent: collapsed ? 'center' : 'space-between',
        borderBottom: '1px solid rgba(255,255,255,.15)', minHeight: 60,
      }}>
        {!collapsed && <span style={{ fontWeight: 700, fontSize: '1.1rem' }}>Oraiopoli</span>}
        <button
          onClick={() => setCollapsed(!collapsed)}
          style={{
            background: 'rgba(255,255,255,.1)', border: 'none', color: '#fff',
            borderRadius: 6, padding: 4, display: 'flex',
          }}
        >
          {collapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
        </button>
      </div>
      <nav style={{ flex: 1, padding: '12px 8px', display: 'flex', flexDirection: 'column', gap: 2 }}>
        {links.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            style={({ isActive }) => ({
              display: 'flex', alignItems: 'center', gap: 12,
              padding: collapsed ? '10px 12px' : '10px 14px',
              borderRadius: 8, color: '#fff', fontSize: '0.875rem', fontWeight: 500,
              background: isActive ? 'rgba(255,255,255,.18)' : 'transparent',
              transition: 'background .15s', justifyContent: collapsed ? 'center' : 'flex-start',
            })}
          >
            <Icon size={20} />
            {!collapsed && label}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}

