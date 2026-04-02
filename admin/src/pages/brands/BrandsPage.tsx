import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getBrands, createBrand, updateBrand, deleteBrand } from '../../api/admin';
import type { Brand } from '../../types';
import Button from '../../components/ui/Button';
import Input from '../../components/ui/Input';
import Modal from '../../components/ui/Modal';
import Spinner from '../../components/ui/Spinner';
import toast from 'react-hot-toast';
import { Plus, Pencil, Trash2 } from 'lucide-react';

export default function BrandsPage() {
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Brand | null>(null);
  const [form, setForm] = useState({ name: '', logoUrl: '', description: '', active: true });

  const { data: brands, isLoading } = useQuery({
    queryKey: ['brands'],
    queryFn: () => getBrands().then((r) => r.data.data),
  });

  const saveMut = useMutation({
    mutationFn: (data: Record<string, unknown>) =>
      editing ? updateBrand(editing.id, data) : createBrand(data),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['brands'] }); toast.success(editing ? 'Brand updated' : 'Brand created'); closeModal(); },
    onError: () => toast.error('Failed to save brand'),
  });

  const delMut = useMutation({
    mutationFn: deleteBrand,
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['brands'] }); toast.success('Brand deleted'); },
  });

  const openCreate = () => { setEditing(null); setForm({ name: '', logoUrl: '', description: '', active: true }); setModalOpen(true); };
  const openEdit = (b: Brand) => { setEditing(b); setForm({ name: b.name, logoUrl: b.logoUrl || '', description: b.description || '', active: b.active }); setModalOpen(true); };
  const closeModal = () => { setModalOpen(false); setEditing(null); };

  const handleSave = () => {
    if (!form.name.trim()) { toast.error('Name is required'); return; }
    saveMut.mutate(form);
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h1 style={{ fontSize: '1.4rem', fontWeight: 700 }}>Brands</h1>
        <Button onClick={openCreate}><Plus size={16} /> Add Brand</Button>
      </div>

      {isLoading ? <Spinner /> : (
        <div style={{ background: '#fff', borderRadius: 'var(--radius)', boxShadow: 'var(--shadow)', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
            <thead>
              <tr style={{ background: 'var(--gray-50)', textAlign: 'left' }}>
                <th style={th}>ID</th><th style={th}>Name</th><th style={th}>Slug</th>
                <th style={th}>Status</th><th style={th}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {brands?.map((b) => (
                <tr key={b.id} style={{ borderBottom: '1px solid var(--gray-100)' }}>
                  <td style={td}>{b.id}</td>
                  <td style={td}><div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    {b.logoUrl && <img src={b.logoUrl} alt="" style={{ width: 28, height: 28, borderRadius: 4, objectFit: 'cover' }} />}
                    {b.name}
                  </div></td>
                  <td style={td}><code style={{ fontSize: '0.78rem', color: 'var(--gray-500)' }}>{b.slug}</code></td>
                  <td style={td}><span style={{ color: b.active ? 'var(--green)' : 'var(--red)', fontWeight: 600, fontSize: '0.8rem' }}>{b.active ? 'Active' : 'Inactive'}</span></td>
                  <td style={{ ...td, display: 'flex', gap: 6 }}>
                    <Button size="sm" variant="outline" onClick={() => openEdit(b)}><Pencil size={14} /></Button>
                    <Button size="sm" variant="danger" onClick={() => { if (confirm('Delete?')) delMut.mutate(b.id); }}><Trash2 size={14} /></Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <Modal isOpen={modalOpen} onClose={closeModal} title={editing ? 'Edit Brand' : 'Add Brand'}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <Input label="Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
          <Input label="Logo URL" value={form.logoUrl} onChange={(e) => setForm({ ...form, logoUrl: e.target.value })} />
          <Input label="Description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.85rem' }}>
            <input type="checkbox" checked={form.active} onChange={(e) => setForm({ ...form, active: e.target.checked })} /> Active
          </label>
          <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', marginTop: 8 }}>
            <Button variant="ghost" onClick={closeModal}>Cancel</Button>
            <Button onClick={handleSave} loading={saveMut.isPending}>Save</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}

const th: React.CSSProperties = { padding: '10px 16px', fontWeight: 600, fontSize: '0.78rem', color: 'var(--gray-500)' };
const td: React.CSSProperties = { padding: '12px 16px' };

