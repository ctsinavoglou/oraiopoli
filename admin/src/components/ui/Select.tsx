import { type SelectHTMLAttributes, forwardRef } from 'react';

interface Props extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  error?: string;
  options: { value: string; label: string }[];
}

const Select = forwardRef<HTMLSelectElement, Props>(({ label, error, options, style, ...rest }, ref) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
    {label && (
      <label style={{ fontSize: '0.8rem', fontWeight: 500, color: 'var(--gray-700)' }}>{label}</label>
    )}
    <select
      ref={ref}
      style={{
        padding: '8px 12px', borderRadius: 'var(--radius)',
        border: `1px solid ${error ? 'var(--red)' : 'var(--gray-300)'}`,
        fontSize: '0.875rem', outline: 'none', background: '#fff', ...style,
      }}
      {...rest}
    >
      {options.map((o) => (
        <option key={o.value} value={o.value}>{o.label}</option>
      ))}
    </select>
    {error && <span style={{ fontSize: '0.75rem', color: 'var(--red)' }}>{error}</span>}
  </div>
));

Select.displayName = 'Select';
export default Select;

