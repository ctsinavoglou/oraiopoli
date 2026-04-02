import { type InputHTMLAttributes, forwardRef } from 'react';

interface Props extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

const Input = forwardRef<HTMLInputElement, Props>(({ label, error, style, ...rest }, ref) => {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      {label && (
        <label style={{ fontSize: '0.8rem', fontWeight: 500, color: 'var(--gray-700)' }}>
          {label}
        </label>
      )}
      <input
        ref={ref}
        style={{
          padding: '8px 12px', borderRadius: 'var(--radius)',
          border: `1px solid ${error ? 'var(--red)' : 'var(--gray-300)'}`,
          fontSize: '0.875rem', outline: 'none', transition: 'border .15s',
          ...style,
        }}
        {...rest}
      />
      {error && <span style={{ fontSize: '0.75rem', color: 'var(--red)' }}>{error}</span>}
    </div>
  );
});

Input.displayName = 'Input';
export default Input;

