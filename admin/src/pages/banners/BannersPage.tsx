import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getBanners, createBanner, updateBanner, deleteBanner } from '../../api/admin';
import type { Banner } from '../../types';
import Button from '../../components/ui/Button';
import Input from '../../components/ui/Input';
import Modal from '../../components/ui/Modal';
import Spinner from '../../components/ui/Spinner';
import toast from 'react-hot-toast';
import { Plus, Pencil, Trash2 } from 'lucide-react';

const emptyForm = { title: '', subtitle: '', imageUrl: '', linkUrl: '', displayOrder: 0, active: true, startDate: '', endDate: '' };

export default function BannersPage() {
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Banner | null>(null);
  const [form, setForm] = useState(emptyForm);

  const { data: banners, isLoading } = useQuery({
    queryKey: ['banners'],
    queryFn: () => getBanners().then((r) => r.data.data),
  });

  const saveMut = useMutation({
    mutationFn: (d: Record<string, unknown>) => editing ? updateBanner(editing.id, d) : createBanner(d),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['banners'] }); toast.success(editing ? 'Banner updated' : 'Banner created'); closeModal(); },
    onError: () => toast.error('Failed to save banner'),
  });

  const delMut = useMutation({
    mutationFn: deleteBanner,
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['banners'] }); toast.success('Banner deleted'); },
  });

  const openCreate = () => { setEditing(null); setForm(emptyForm); setModalOpen(true); };
  const openEdit = (b: Banner) => {
    setEditing(b);
    setForm({ title: b.title, subtitle: b.subtitle || '', imageUrl: b.imageUrl, linkUrl: b.linkUrl || '', displayOrder: b.displayOrder, active: b.active, startDate: b.startDate || '', endDate: b.endDate || '' });
    setModalOpen(true);
  };
  const closeModal = () => { setModalOpen(false); setEditing(null); };

  const handleSave = () => {
    if (!form.title.trim() || !form.imageUrl.trim()) { toast.error('Title and Image URL required'); return; }
    saveMut.mutate({
      ...form, startDate: form.startDate || null, endDate: form.endDate || null,
    });
  };

  const set = (k: string, v: unknown) => setForm((f) => ({ ...f, [k]: v }));

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <h1 style={{ fontSize: '1.4rem', fontWeight: 700 }}>Banners</h1>
        <Button onClick={openCreate}><Plus size={16} /> Add Banner</Button>
      </div>

      {isLoading ? <Spinner /> : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 16 }}>
          {banners?.map((b) => (
            <div key={b.id} style={{ background: '#fff', borderRadius: 'var(--radius)', boxShadow: 'var(--shadow)', overflow: 'hidden' }}>
              <img src={b.imageUrl} alt={b.title} style={{ width: '100%', height: 160, objectFit: 'cover', background: 'var(--gray-100)' }}
                onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }} />
              <div style={{ padding: 16 }}>
                <div style={{ fontWeight: 600, marginBottom: 4 }}>{b.title}</div>
                {b.subtitle && <div style={{ fontSize: '0.8rem', color: 'var(--gray-500)', marginBottom: 8 }}>{b.subtitle}</div>}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span style={{ color: b.active ? 'var(--green)' : 'var(--red)', fontWeight: 600, fontSize: '0.8rem' }}>{b.active ? 'Active' : 'Inactive'}</span>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <Button size="sm" variant="outline" onClick={() => openEdit(b)}><Pencil size={14} /></Button>
                    <Button size="sm" variant="danger" onClick={() => { if (confirm('Delete?')) delMut.mutate(b.id); }}><Trash2 size={14} /></Button>
                  </div>
                </div>
              </div>
            </div>
          ))}
          {banners?.length === 0 && <div style={{ color: 'var(--gray-400)', padding: 40, textAlign: 'center' }}>No banners yet</div>}
        </div>
      )}

      <Modal isOpen={modalOpen} onClose={closeModal} title={editing ? 'Edit Banner' : 'Add Banner'}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <Input label="Title *" value={form.title} onChange={(e) => set('title', e.target.value)} />
          <Input label="Subtitle" value={form.subtitle} onChange={(e) => set('subtitle', e.target.value)} />
          <Input label="Image URL *" value={form.imageUrl} onChange={(e) => set('imageUrl', e.target.value)} />
          <Input label="Link URL" value={form.linkUrl} onChange={(e) => set('linkUrl', e.target.value)} />
          <Input label="Display Order" type="number" value={form.displayOrder} onChange={(e) => set('displayOrder', Number(e.target.value))} />
          <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.85rem' }}>
            <input type="checkbox" checked={form.active} onChange={(e) => set('active', e.target.checked)} /> Active
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

