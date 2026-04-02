import type { ReactNode } from 'react';

interface Props {
  icon: ReactNode;
  title: string;
  value: string | number;
  color?: string;
  subtitle?: string;
}

export default function StatCard({ icon, title, value, color = 'var(--primary)', subtitle }: Props) {
  return (
    <div style={{
      background: 'var(--white)', borderRadius: 'var(--radius)', padding: 20,
      boxShadow: 'var(--shadow)', display: 'flex', alignItems: 'center', gap: 16,
      borderLeft: `4px solid ${color}`,
    }}>
      <div style={{
        width: 48, height: 48, borderRadius: '50%', display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        background: `${color}14`, color,
      }}>
        {icon}
      </div>
      <div>
        <div style={{ fontSize: '0.8rem', color: 'var(--gray-500)', marginBottom: 2 }}>{title}</div>
        <div style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--gray-900)' }}>{value}</div>
        {subtitle && <div style={{ fontSize: '0.75rem', color: 'var(--gray-400)', marginTop: 2 }}>{subtitle}</div>}
      </div>
    </div>
  );
}

