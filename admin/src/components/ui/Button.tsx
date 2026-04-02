import { type ButtonHTMLAttributes, type ReactNode } from 'react';

interface Props extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'accent' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  children: ReactNode;
}

export default function Button({
  variant = 'primary', size = 'md', loading, children, disabled, style, ...rest
}: Props) {
  const base: React.CSSProperties = {
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 6,
    borderRadius: 'var(--radius)', fontWeight: 500, border: 'none',
    transition: 'all .15s', opacity: disabled || loading ? 0.6 : 1,
    cursor: disabled || loading ? 'not-allowed' : 'pointer',
  };

  const sizes: Record<string, React.CSSProperties> = {
    sm: { padding: '6px 12px', fontSize: '0.8rem' },
    md: { padding: '8px 16px', fontSize: '0.875rem' },
    lg: { padding: '10px 24px', fontSize: '1rem' },
  };

  const variants: Record<string, React.CSSProperties> = {
    primary: { background: 'var(--primary)', color: '#fff' },
    accent: { background: 'var(--accent)', color: '#fff' },
    outline: { background: 'transparent', color: 'var(--primary)', border: '1px solid var(--primary)' },
    ghost: { background: 'transparent', color: 'var(--gray-600)' },
    danger: { background: 'var(--red)', color: '#fff' },
  };

  return (
    <button
      disabled={disabled || loading}
      style={{ ...base, ...sizes[size], ...variants[variant], ...style }}
      {...rest}
    >
      {loading && <span className="spinner" />}
      {children}
    </button>
  );
}

