interface Props {
  page: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}

export default function Pagination({ page, totalPages, onPageChange }: Props) {
  if (totalPages <= 1) return null;

  // Build page numbers: always show first, last, and pages around current
  const pages: (number | 'dots')[] = [];
  const siblings = 1; // how many pages around current

  const addPage = (p: number) => {
    if (!pages.includes(p)) pages.push(p);
  };

  // Always show first page
  addPage(0);

  // Pages around current
  const rangeStart = Math.max(1, page - siblings);
  const rangeEnd = Math.min(totalPages - 2, page + siblings);

  if (rangeStart > 1) pages.push('dots');
  for (let i = rangeStart; i <= rangeEnd; i++) addPage(i);
  if (rangeEnd < totalPages - 2) pages.push('dots');

  // Always show last page
  if (totalPages > 1) addPage(totalPages - 1);

  const btnStyle = (active: boolean, disabled?: boolean): React.CSSProperties => ({
    padding: '6px 12px', borderRadius: 'var(--radius)', border: '1px solid var(--gray-200)',
    background: active ? 'var(--primary)' : '#fff',
    color: active ? '#fff' : 'var(--gray-700)',
    fontSize: '0.8rem', fontWeight: 500,
    cursor: disabled ? 'default' : 'pointer',
    opacity: disabled ? 0.5 : 1,
  });

  const dotsStyle: React.CSSProperties = {
    padding: '6px 8px', fontSize: '0.8rem', color: 'var(--gray-400)',
    userSelect: 'none',
  };

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 4, justifyContent: 'center', marginTop: 16, padding: '12px 0' }}>
      <button style={btnStyle(false, page === 0)} disabled={page === 0} onClick={() => onPageChange(page - 1)}>
        Prev
      </button>
      {pages.map((p, i) =>
        p === 'dots' ? (
          <span key={`dots-${i}`} style={dotsStyle}>…</span>
        ) : (
          <button key={p} style={btnStyle(p === page)} onClick={() => onPageChange(p)}>
            {p + 1}
          </button>
        )
      )}
      <button style={btnStyle(false, page >= totalPages - 1)} disabled={page >= totalPages - 1} onClick={() => onPageChange(page + 1)}>
        Next
      </button>
    </div>
  );
}

