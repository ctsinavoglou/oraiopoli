import { useQuery } from '@tanstack/react-query';
import { getDashboard } from '../../api/admin';
import StatCard from '../../components/ui/StatCard';
import Badge from '../../components/ui/Badge';
import Spinner from '../../components/ui/Spinner';
import {
  Users, Package, AlertTriangle, Clock, CheckCircle, XCircle, DollarSign,
} from 'lucide-react';

export default function DashboardPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['dashboard'],
    queryFn: () => getDashboard().then((r) => r.data.data),
  });

  if (isLoading || !data) return <Spinner />;

  return (
    <div>
      <h1 style={{ fontSize: '1.4rem', fontWeight: 700, marginBottom: 24 }}>Dashboard</h1>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))', gap: 16, marginBottom: 32 }}>
        <StatCard icon={<Users size={22} />} title="Total Customers" value={data.totalUsers} />
        <StatCard icon={<Package size={22} />} title="Total Products" value={data.totalProducts} color="var(--green)" />
        <StatCard icon={<AlertTriangle size={22} />} title="Low Stock" value={data.lowStockProducts} color="var(--yellow)" />
        <StatCard icon={<Clock size={22} />} title="Pending Orders" value={data.pendingOrders} color="var(--yellow)" />
        <StatCard icon={<CheckCircle size={22} />} title="Completed" value={data.completedOrders} color="var(--green)" />
        <StatCard icon={<XCircle size={22} />} title="Cancelled" value={data.cancelledOrders} color="var(--red)" />
        <StatCard icon={<DollarSign size={22} />} title="Revenue" value={`€${data.totalRevenue.toLocaleString()}`} color="var(--primary)" />
      </div>

      <div style={{ background: '#fff', borderRadius: 'var(--radius)', boxShadow: 'var(--shadow)', overflow: 'hidden' }}>
        <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--gray-200)', fontWeight: 600 }}>
          Latest Orders
        </div>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
            <thead>
              <tr style={{ background: 'var(--gray-50)', textAlign: 'left' }}>
                <th style={th}>Order #</th>
                <th style={th}>Customer</th>
                <th style={th}>Amount</th>
                <th style={th}>Status</th>
                <th style={th}>Date</th>
              </tr>
            </thead>
            <tbody>
              {data.latestOrders.map((o) => (
                <tr key={o.id} style={{ borderBottom: '1px solid var(--gray-100)' }}>
                  <td style={td}>{o.orderNumber}</td>
                  <td style={td}>{o.customerName}</td>
                  <td style={td}>€{o.totalAmount.toFixed(2)}</td>
                  <td style={td}><Badge status={o.status} /></td>
                  <td style={td}>{new Date(o.createdAt).toLocaleDateString()}</td>
                </tr>
              ))}
              {data.latestOrders.length === 0 && (
                <tr><td colSpan={5} style={{ ...td, textAlign: 'center', color: 'var(--gray-400)' }}>No orders yet</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

const th: React.CSSProperties = { padding: '10px 16px', fontWeight: 600, fontSize: '0.78rem', color: 'var(--gray-500)' };
const td: React.CSSProperties = { padding: '12px 16px' };

