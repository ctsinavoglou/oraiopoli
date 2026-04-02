export default function Spinner({ size = 32 }: { size?: number }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'center', padding: 40 }}>
      <div style={{
        width: size, height: size, border: '3px solid var(--gray-200)',
        borderTopColor: 'var(--primary)', borderRadius: '50%',
        animation: 'spin 0.6s linear infinite',
      }} />
      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}

