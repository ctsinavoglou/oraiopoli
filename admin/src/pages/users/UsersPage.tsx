import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getUsers, toggleUserStatus } from '../../api/admin';
import Input from '../../components/ui/Input';
import Button from '../../components/ui/Button';
import Pagination from '../../components/ui/Pagination';
import Spinner from '../../components/ui/Spinner';
import toast from 'react-hot-toast';

export default function UsersPage() {
  const qc = useQueryClient();
  const [page, setPage] = useState(0);
  const [search, setSearch] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['users', page, search],
    queryFn: () => getUsers({ page, size: 20, search: search || undefined }).then((r) => r.data.data),
  });

  const toggleMut = useMutation({
    mutationFn: (id: number) => toggleUserStatus(id),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['users'] }); toast.success('User status updated'); },
  });

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h1 style={{ fontSize: '1.4rem', fontWeight: 700 }}>Users</h1>
        <Input
          placeholder="Search users..." value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(0); }}
          style={{ width: 280 }}
        />
      </div>

      {isLoading ? <Spinner /> : (
        <div style={{ background: '#fff', borderRadius: 'var(--radius)', boxShadow: 'var(--shadow)', overflow: 'hidden' }}>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
              <thead>
                <tr style={{ background: 'var(--gray-50)', textAlign: 'left' }}>
                  <th style={th}>ID</th><th style={th}>Name</th><th style={th}>Email</th>
                  <th style={th}>Phone</th><th style={th}>Role</th><th style={th}>Status</th><th style={th}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data?.content.map((u) => (
                  <tr key={u.id} style={{ borderBottom: '1px solid var(--gray-100)' }}>
                    <td style={td}>{u.id}</td>
                    <td style={td}>{u.fullName}</td>
                    <td style={td}>{u.email}</td>
                    <td style={td}>{u.phone}</td>
                    <td style={td}><span style={{
                      padding: '2px 8px', borderRadius: 12, fontSize: '0.75rem', fontWeight: 600,
                      background: u.role === 'CUSTOMER' ? 'var(--primary-light)' : '#fef3c7',
                      color: u.role === 'CUSTOMER' ? 'var(--primary)' : '#92400e',
                    }}>{u.role}</span></td>
                    <td style={td}>
                      <span style={{ color: u.enabled ? 'var(--green)' : 'var(--red)', fontWeight: 600, fontSize: '0.8rem' }}>
                        {u.enabled ? 'Active' : 'Disabled'}
                      </span>
                    </td>
                    <td style={td}>
                      <Button
                        size="sm"
                        variant={u.enabled ? 'danger' : 'primary'}
                        onClick={() => toggleMut.mutate(u.id)}
                      >
                        {u.enabled ? 'Disable' : 'Enable'}
                      </Button>
                    </td>
                  </tr>
                ))}
                {data?.content.length === 0 && (
                  <tr><td colSpan={7} style={{ ...td, textAlign: 'center', color: 'var(--gray-400)' }}>No users found</td></tr>
                )}
              </tbody>
            </table>
          </div>
          {data && <Pagination page={page} totalPages={data.totalPages} onPageChange={setPage} />}
        </div>
      )}
    </div>
  );
}

const th: React.CSSProperties = { padding: '10px 16px', fontWeight: 600, fontSize: '0.78rem', color: 'var(--gray-500)' };
const td: React.CSSProperties = { padding: '12px 16px' };

