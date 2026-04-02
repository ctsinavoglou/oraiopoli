import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getPromotions, createPromotion, updatePromotion, deletePromotion } from '../../api/admin';
import type { Promotion } from '../../types';
import Button from '../../components/ui/Button';
import Input from '../../components/ui/Input';
import Modal from '../../components/ui/Modal';
import Spinner from '../../components/ui/Spinner';
import toast from 'react-hot-toast';
import { Plus, Pencil, Trash2 } from 'lucide-react';

const emptyForm = { title: '', description: '', code: '', discountPercentage: '', discountAmount: '', minOrderAmount: '', imageUrl: '', active: true, startDate: '', endDate: '' };

export default function PromotionsPage() {
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Promotion | null>(null);
  const [form, setForm] = useState(emptyForm);

  const { data: promotions, isLoading } = useQuery({
    queryKey: ['promotions'],
    queryFn: () => getPromotions().then((r) => r.data.data),
  });

  const saveMut = useMutation({
    mutationFn: (d: Record<string, unknown>) => editing ? updatePromotion(editing.id, d) : createPromotion(d),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['promotions'] }); toast.success(editing ? 'Promotion updated' : 'Promotion created'); closeModal(); },
    onError: () => toast.error('Failed to save promotion'),
  });

  const delMut = useMutation({
    mutationFn: deletePromotion,
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['promotions'] }); toast.success('Promotion deleted'); },
  });

  const openCreate = () => { setEditing(null); setForm(emptyForm); setModalOpen(true); };
  const openEdit = (p: Promotion) => {
    setEditing(p);
    setForm({
      title: p.title, description: p.description || '', code: p.code || '',
      discountPercentage: p.discountPercentage?.toString() || '', discountAmount: p.discountAmount?.toString() || '',
      minOrderAmount: p.minOrderAmount?.toString() || '', imageUrl: p.imageUrl || '',
      active: p.active, startDate: p.startDate || '', endDate: p.endDate || '',
    });
    setModalOpen(true);
  };
  const closeModal = () => { setModalOpen(false); setEditing(null); };

  const handleSave = () => {
    if (!form.title.trim()) { toast.error('Title required'); return; }
    saveMut.mutate({
      title: form.title, description: form.description, code: form.code || null,
      discountPercentage: form.discountPercentage ? parseFloat(form.discountPercentage) : null,
      discountAmount: form.discountAmount ? parseFloat(form.discountAmount) : null,
      minOrderAmount: form.minOrderAmount ? parseFloat(form.minOrderAmount) : null,
      imageUrl: form.imageUrl, active: form.active,
      startDate: form.startDate || null, endDate: form.endDate || null,
    });
  };

  const set = (k: string, v: unknown) => setForm((f) => ({ ...f, [k]: v }));

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h1 style={{ fontSize: '1.4rem', fontWeight: 700 }}>Promotions</h1>
        <Button onClick={openCreate}><Plus size={16} /> Add Promotion</Button>
      </div>

      {isLoading ? <Spinner /> : (
        <div style={{ background: '#fff', borderRadius: 'var(--radius)', boxShadow: 'var(--shadow)', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
            <thead>
              <tr style={{ background: 'var(--gray-50)', textAlign: 'left' }}>
                <th style={th}>Title</th><th style={th}>Code</th><th style={th}>Discount</th>
                <th style={th}>Status</th><th style={th}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {promotions?.map((p) => (
                <tr key={p.id} style={{ borderBottom: '1px solid var(--gray-100)' }}>
                  <td style={td}>{p.title}</td>
                  <td style={td}>{p.code ? <code style={{ background: 'var(--gray-100)', padding: '2px 6px', borderRadius: 4, fontSize: '0.8rem' }}>{p.code}</code> : '—'}</td>
                  <td style={td}>{p.discountPercentage ? `${p.discountPercentage}%` : p.discountAmount ? `€${p.discountAmount}` : '—'}</td>
                  <td style={td}><span style={{ color: p.active ? 'var(--green)' : 'var(--red)', fontWeight: 600, fontSize: '0.8rem' }}>{p.active ? 'Active' : 'Inactive'}</span></td>
                  <td style={{ ...td, display: 'flex', gap: 6 }}>
                    <Button size="sm" variant="outline" onClick={() => openEdit(p)}><Pencil size={14} /></Button>
                    <Button size="sm" variant="danger" onClick={() => { if (confirm('Delete?')) delMut.mutate(p.id); }}><Trash2 size={14} /></Button>
                  </td>
                </tr>
              ))}
              {promotions?.length === 0 && (
                <tr><td colSpan={5} style={{ ...td, textAlign: 'center', color: 'var(--gray-400)' }}>No promotions</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      <Modal isOpen={modalOpen} onClose={closeModal} title={editing ? 'Edit Promotion' : 'Add Promotion'} width={600}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
          <Input label="Title *" value={form.title} onChange={(e) => set('title', e.target.value)} />
          <Input label="Code" value={form.code} onChange={(e) => set('code', e.target.value)} />
          <Input label="Discount %" type="number" step="0.01" value={form.discountPercentage} onChange={(e) => set('discountPercentage', e.target.value)} />
          <Input label="Discount €" type="number" step="0.01" value={form.discountAmount} onChange={(e) => set('discountAmount', e.target.value)} />
          <Input label="Min Order €" type="number" step="0.01" value={form.minOrderAmount} onChange={(e) => set('minOrderAmount', e.target.value)} />
          <Input label="Image URL" value={form.imageUrl} onChange={(e) => set('imageUrl', e.target.value)} />
          <div style={{ gridColumn: '1 / -1' }}>
            <Input label="Description" value={form.description} onChange={(e) => set('description', e.target.value)} />
          </div>
          <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.85rem' }}>
            <input type="checkbox" checked={form.active} onChange={(e) => set('active', e.target.checked)} /> Active
          </label>
        </div>
        <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', marginTop: 20 }}>
          <Button variant="ghost" onClick={closeModal}>Cancel</Button>
          <Button onClick={handleSave} loading={saveMut.isPending}>Save</Button>
        </div>
      </Modal>
    </div>
  );
}

const th: React.CSSProperties = { padding: '10px 16px', fontWeight: 600, fontSize: '0.78rem', color: 'var(--gray-500)' };
const td: React.CSSProperties = { padding: '12px 16px' };

