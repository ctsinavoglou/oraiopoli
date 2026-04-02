import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getProducts, createProduct, updateProduct, deleteProduct, getCategories, getBrands, uploadImage } from '../../api/admin';
import type { Product } from '../../types';
import Button from '../../components/ui/Button';
import Input from '../../components/ui/Input';
import Modal from '../../components/ui/Modal';
import Pagination from '../../components/ui/Pagination';
import Spinner from '../../components/ui/Spinner';
import toast from 'react-hot-toast';
import { Plus, Pencil, Trash2, Star, Upload, Link, X } from 'lucide-react';

const emptyForm = {
  name: '', sku: '', description: '', price: '', discountPrice: '', unit: '',
  active: true, featured: false, thumbnailUrl: '', categoryId: '', brandId: '',
  stockQuantity: '0', lowStockThreshold: '10',
};

export default function ProductsPage() {
  const qc = useQueryClient();
  const [page, setPage] = useState(0);
  const [search, setSearch] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Product | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [uploading, setUploading] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ['products', page, search],
    queryFn: () => getProducts({ page, size: 20, search: search || undefined }).then((r) => r.data.data),
  });

  const { data: categories } = useQuery({ queryKey: ['categories'], queryFn: () => getCategories().then((r) => r.data.data) });
  const { data: brands } = useQuery({ queryKey: ['brands'], queryFn: () => getBrands().then((r) => r.data.data) });

  const saveMut = useMutation({
    mutationFn: (d: Record<string, unknown>) => editing ? updateProduct(editing.id, d) : createProduct(d),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['products'] }); toast.success(editing ? 'Product updated' : 'Product created'); closeModal(); },
    onError: () => toast.error('Failed to save product'),
  });

  const delMut = useMutation({
    mutationFn: deleteProduct,
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['products'] }); toast.success('Product deleted'); },
  });

  const openCreate = () => { setEditing(null); setForm(emptyForm); setModalOpen(true); };
  const openEdit = (p: Product) => {
    setEditing(p);
    setForm({
      name: p.name, sku: p.sku, description: p.description || '', price: p.price.toString(),
      discountPrice: p.discountPrice?.toString() || '', unit: p.unit || '',
      active: p.active, featured: p.featured, thumbnailUrl: p.thumbnailUrl || '',
      categoryId: p.categoryId?.toString() || '', brandId: p.brandId?.toString() || '',
      stockQuantity: p.stockQuantity.toString(), lowStockThreshold: '10',
    });
    setModalOpen(true);
  };
  const closeModal = () => { setModalOpen(false); setEditing(null); };

  const handleSave = () => {
    if (!form.name.trim() || !form.sku.trim() || !form.price || !form.categoryId) {
      toast.error('Name, SKU, Price, and Category are required'); return;
    }
    saveMut.mutate({
      name: form.name, sku: form.sku, description: form.description,
      price: parseFloat(form.price),
      discountPrice: form.discountPrice ? parseFloat(form.discountPrice) : null,
      unit: form.unit, active: form.active, featured: form.featured,
      thumbnailUrl: form.thumbnailUrl, categoryId: Number(form.categoryId),
      brandId: form.brandId ? Number(form.brandId) : null,
      stockQuantity: parseInt(form.stockQuantity), lowStockThreshold: parseInt(form.lowStockThreshold),
    });
  };

  const set = (key: string, val: unknown) => setForm((f) => ({ ...f, [key]: val }));

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, flexWrap: 'wrap', gap: 10 }}>
        <h1 style={{ fontSize: '1.4rem', fontWeight: 700 }}>Products</h1>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          <Input
            placeholder="Search products..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(0); }}
            style={{ width: 220 }}
          />
          <Button onClick={openCreate}><Plus size={16} /> Add Product</Button>
        </div>
      </div>

      {isLoading ? <Spinner /> : (
        <div style={{ background: '#fff', borderRadius: 'var(--radius)', boxShadow: 'var(--shadow)', overflow: 'hidden' }}>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
              <thead>
                <tr style={{ background: 'var(--gray-50)', textAlign: 'left' }}>
                  <th style={th}>Image</th><th style={th}>Name</th><th style={th}>SKU</th>
                  <th style={th}>Price</th><th style={th}>Stock</th><th style={th}>Category</th>
                  <th style={th}>Status</th><th style={th}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data?.content.map((p) => (
                  <tr key={p.id} style={{ borderBottom: '1px solid var(--gray-100)' }}>
                    <td style={td}>
                      {p.thumbnailUrl ? (
                        <img src={p.thumbnailUrl.startsWith('/uploads') ? `http://localhost:8080${p.thumbnailUrl}` : p.thumbnailUrl} alt="" style={{ width: 40, height: 40, borderRadius: 6, objectFit: 'cover' }} />
                      ) : (
                        <div style={{ width: 40, height: 40, borderRadius: 6, background: 'var(--gray-100)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--gray-400)', fontSize: '0.7rem' }}>N/A</div>
                      )}
                    </td>
                    <td style={td}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                        {p.name} {p.featured && <Star size={14} fill="var(--yellow)" color="var(--yellow)" />}
                      </div>
                    </td>
                    <td style={td}><code style={{ fontSize: '0.78rem', color: 'var(--gray-500)' }}>{p.sku}</code></td>
                    <td style={td}>
                      {p.discountPrice ? (
                        <><span style={{ textDecoration: 'line-through', color: 'var(--gray-400)', marginRight: 4 }}>€{p.price}</span><span style={{ color: 'var(--accent)', fontWeight: 600 }}>€{p.discountPrice}</span></>
                      ) : <span>€{p.price}</span>}
                    </td>
                    <td style={td}><span style={{ color: p.stockQuantity <= 10 ? 'var(--red)' : 'var(--green)', fontWeight: 600 }}>{p.stockQuantity}</span></td>
                    <td style={td}>{p.categoryName}</td>
                    <td style={td}><span style={{ color: p.active ? 'var(--green)' : 'var(--red)', fontWeight: 600, fontSize: '0.8rem' }}>{p.active ? 'Active' : 'Inactive'}</span></td>
                    <td style={td}>
                      <div style={{ display: 'flex', gap: 6 }}>
                        <Button size="sm" variant="outline" onClick={() => openEdit(p)}><Pencil size={14} /></Button>
                        <Button size="sm" variant="danger" onClick={() => { if (confirm('Delete?')) delMut.mutate(p.id); }}><Trash2 size={14} /></Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {data && <Pagination page={page} totalPages={data.totalPages} onPageChange={setPage} />}
        </div>
      )}

      <Modal isOpen={modalOpen} onClose={closeModal} title={editing ? 'Edit Product' : 'Add Product'} width={750}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
          <Input label="Name *" value={form.name} onChange={(e) => set('name', e.target.value)} />
          <Input label="SKU *" value={form.sku} onChange={(e) => set('sku', e.target.value)} />
          <Input label="Price *" type="number" step="0.01" value={form.price} onChange={(e) => set('price', e.target.value)} />
          <Input label="Discount Price" type="number" step="0.01" value={form.discountPrice} onChange={(e) => set('discountPrice', e.target.value)} />
          <Input label="Unit (e.g. kg, piece)" value={form.unit} onChange={(e) => set('unit', e.target.value)} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            <label style={{ fontSize: '0.8rem', fontWeight: 500, color: 'var(--gray-700)' }}>Thumbnail</label>
            {form.thumbnailUrl ? (
              <div style={{ position: 'relative', width: 80, height: 80 }}>
                <img src={form.thumbnailUrl.startsWith('/uploads') ? `http://localhost:8080${form.thumbnailUrl}` : form.thumbnailUrl}
                  alt="" style={{ width: 80, height: 80, borderRadius: 8, objectFit: 'cover', border: '1px solid var(--gray-200)' }} />
                <button onClick={() => set('thumbnailUrl', '')}
                  style={{ position: 'absolute', top: -6, right: -6, width: 20, height: 20, borderRadius: '50%', background: 'var(--red)', color: '#fff', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 0 }}>
                  <X size={12} />
                </button>
              </div>
            ) : (
              <div style={{ display: 'flex', gap: 6 }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 4, padding: '6px 12px', borderRadius: 'var(--radius)', border: '1px solid var(--gray-300)', cursor: uploading ? 'wait' : 'pointer', fontSize: '0.8rem', background: '#fff', color: 'var(--gray-600)' }}>
                  <Upload size={14} /> {uploading ? 'Uploading...' : 'Upload'}
                  <input type="file" accept="image/*" hidden disabled={uploading} onChange={async (e) => {
                    const file = e.target.files?.[0];
                    if (!file) return;
                    setUploading(true);
                    try {
                      const res = await uploadImage(file);
                      set('thumbnailUrl', res.data.data.url);
                      toast.success('Image uploaded');
                    } catch { toast.error('Upload failed'); }
                    setUploading(false);
                    e.target.value = '';
                  }} />
                </label>
                <div style={{ display: 'flex', alignItems: 'center', gap: 4, flex: 1 }}>
                  <Link size={14} style={{ color: 'var(--gray-400)', flexShrink: 0 }} />
                  <input placeholder="or paste URL" value={form.thumbnailUrl} onChange={(e) => set('thumbnailUrl', e.target.value)}
                    style={{ ...selectStyle, flex: 1, fontSize: '0.8rem', padding: '6px 8px' }} />
                </div>
              </div>
            )}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            <label style={{ fontSize: '0.8rem', fontWeight: 500, color: 'var(--gray-700)' }}>Category *</label>
            <select value={form.categoryId} onChange={(e) => set('categoryId', e.target.value)} style={selectStyle}>
              <option value="">Select category</option>
              {categories?.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
            <label style={{ fontSize: '0.8rem', fontWeight: 500, color: 'var(--gray-700)' }}>Brand</label>
            <select value={form.brandId} onChange={(e) => set('brandId', e.target.value)} style={selectStyle}>
              <option value="">No brand</option>
              {brands?.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
            </select>
          </div>
          <Input label="Stock Quantity" type="number" value={form.stockQuantity} onChange={(e) => set('stockQuantity', e.target.value)} />
          <Input label="Low Stock Threshold" type="number" value={form.lowStockThreshold} onChange={(e) => set('lowStockThreshold', e.target.value)} />
          <div style={{ gridColumn: '1 / -1' }}>
            <label style={{ fontSize: '0.8rem', fontWeight: 500, color: 'var(--gray-700)' }}>Description</label>
            <textarea value={form.description} onChange={(e) => set('description', e.target.value)}
              rows={3} style={{ ...selectStyle, width: '100%', resize: 'vertical', marginTop: 4 }} />
          </div>
          <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.85rem' }}>
            <input type="checkbox" checked={form.active} onChange={(e) => set('active', e.target.checked)} /> Active
          </label>
          <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '0.85rem' }}>
            <input type="checkbox" checked={form.featured} onChange={(e) => set('featured', e.target.checked)} /> Featured
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
const selectStyle: React.CSSProperties = {
  padding: '8px 12px', borderRadius: 'var(--radius)', border: '1px solid var(--gray-300)',
  fontSize: '0.875rem', outline: 'none', background: '#fff',
};

