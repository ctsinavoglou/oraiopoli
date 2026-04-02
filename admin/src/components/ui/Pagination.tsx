interface Props {
  page: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}

export default function Pagination({ page, totalPages, onPageChange }: Props) {
  if (totalPages <= 1) return null;

  const pages: number[] = [];
  const start = Math.max(0, page - 2);
  const end = Math.min(totalPages - 1, page + 2);
  for (let i = start; i <= end; i++) pages.push(i);

  const btnStyle = (active: boolean): React.CSSProperties => ({
    padding: '6px 12px', borderRadius: 'var(--radius)', border: '1px solid var(--gray-200)',
    background: active ? 'var(--primary)' : '#fff',
    color: active ? '#fff' : 'var(--gray-700)',
    fontSize: '0.8rem', fontWeight: 500, cursor: 'pointer',
  });

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 4, justifyContent: 'center', marginTop: 16 }}>
      <button style={btnStyle(false)} disabled={page === 0} onClick={() => onPageChange(page - 1)}>
        Prev
      </button>
      {pages.map((p) => (
        <button key={p} style={btnStyle(p === page)} onClick={() => onPageChange(p)}>
          {p + 1}
        </button>
      ))}
      <button style={btnStyle(false)} disabled={page >= totalPages - 1} onClick={() => onPageChange(page + 1)}>
        Next
      </button>
    </div>
  );
}

