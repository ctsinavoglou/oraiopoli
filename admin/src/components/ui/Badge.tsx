import type { OrderStatus } from '../../types';

const colors: Record<OrderStatus, { bg: string; text: string }> = {
  PENDING: { bg: '#fef3c7', text: '#92400e' },
  CONFIRMED: { bg: '#dbeafe', text: '#1e40af' },
  PROCESSING: { bg: '#e0e7ff', text: '#3730a3' },
  SHIPPED: { bg: '#cffafe', text: '#155e75' },
  DELIVERED: { bg: '#d1fae5', text: '#065f46' },
  COMPLETED: { bg: '#d1fae5', text: '#065f46' },
  CANCELLED: { bg: '#fee2e2', text: '#991b1b' },
  REFUNDED: { bg: '#fde68a', text: '#78350f' },
};

export default function Badge({ status }: { status: OrderStatus | string }) {
  const c = colors[status as OrderStatus] || { bg: 'var(--gray-100)', text: 'var(--gray-700)' };
  return (
    <span style={{
      display: 'inline-block', padding: '3px 10px', borderRadius: 20,
      fontSize: '0.75rem', fontWeight: 600, background: c.bg, color: c.text,
    }}>
      {status}
    </span>
  );
}

