import { useState, useEffect, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getBanners, createBanner, updateBanner, deleteBanner, getProducts } from '../../api/admin';
import type { Banner, BannerLinkType, Product } from '../../types';
import Button from '../../components/ui/Button';
import Input from '../../components/ui/Input';
import Modal from '../../components/ui/Modal';
import Spinner from '../../components/ui/Spinner';
import toast from 'react-hot-toast';
import { Plus, Pencil, Trash2, X, Search } from 'lucide-react';

const LINK_TYPES: { value: BannerLinkType; label: string }[] = [
  { value: 'NONE', label: 'None' },
  { value: 'BANNER_PAGE', label: 'Banner Page (own content)' },
  { value: 'PRODUCT', label: 'Product' },
  { value: 'CATEGORY', label: 'Category' },
  { value: 'EXTERNAL', label: 'External URL' },
];

const emptyForm = {
  title: '', subtitle: '', imageUrl: '', linkUrl: '', linkType: 'NONE' as BannerLinkType,
  contentBody: '', productIds: [] as number[], displayOrder: 0, active: true, startDate: '', endDate: '',
};

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
    setForm({
      title: b.title, subtitle: b.subtitle || '', imageUrl: b.imageUrl,
      linkUrl: b.linkUrl || '', linkType: b.linkType || 'NONE',
      contentBody: b.contentBody || '', productIds: b.productIds || [],
      displayOrder: b.displayOrder, active: b.active,
      startDate: b.startDate || '', endDate: b.endDate || '',
    });
    setModalOpen(true);
  };
  const closeModal = () => { setModalOpen(false); setEditing(null); };

  const handleSave = () => {
    if (!form.title.trim() || !form.imageUrl.trim()) { toast.error('Title and Image URL required'); return; }
    const isBannerPage = form.linkType === 'BANNER_PAGE';
    saveMut.mutate({
      ...form,
      linkUrl: form.linkType === 'NONE' || isBannerPage ? null : form.linkUrl || null,
      contentBody: isBannerPage ? form.contentBody : null,
      productIds: isBannerPage ? form.productIds : [],
      startDate: form.startDate || null,
      endDate: form.endDate || null,
    });
  };

  const set = (k: string, v: unknown) => setForm((f) => ({ ...f, [k]: v }));

  const linkTypeLabel = (lt?: string) => LINK_TYPES.find((t) => t.value === lt)?.label || 'None';

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
                {b.subtitle && <div style={{ fontSize: '0.8rem', color: 'var(--gray-500)', marginBottom: 4 }}>{b.subtitle}</div>}
                <div style={{ fontSize: '0.75rem', color: 'var(--gray-400)', marginBottom: 8 }}>
                  {linkTypeLabel(b.linkType)}
                  {b.productIds && b.productIds.length > 0 ? ` · ${b.productIds.length} products` : ''}
                  {b.startDate || b.endDate ? ` · ${b.startDate?.slice(0, 10) || '∞'} → ${b.endDate?.slice(0, 10) || '∞'}` : ''}
                </div>
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

      <Modal isOpen={modalOpen} onClose={closeModal} title={editing ? 'Edit Banner' : 'Add Banner'} width={600}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <Input label="Title *" value={form.title} onChange={(e) => set('title', e.target.value)} />
          <Input label="Subtitle" value={form.subtitle} onChange={(e) => set('subtitle', e.target.value)} />
          <Input label="Image URL *" value={form.imageUrl} onChange={(e) => set('imageUrl', e.target.value)} />

          <div>
            <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: 4 }}>Link Type</label>
            <select
              value={form.linkType}
              onChange={(e) => set('linkType', e.target.value)}
              style={{ width: '100%', padding: '8px 10px', borderRadius: 'var(--radius)', border: '1px solid var(--gray-200)', fontSize: '0.85rem' }}
            >
              {LINK_TYPES.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
            </select>
          </div>

          {(form.linkType === 'PRODUCT' || form.linkType === 'CATEGORY' || form.linkType === 'EXTERNAL') && (
            <Input
              label={form.linkType === 'PRODUCT' ? 'Product Slug' : form.linkType === 'CATEGORY' ? 'Category ID' : 'External URL'}
              value={form.linkUrl}
              onChange={(e) => set('linkUrl', e.target.value)}
              placeholder={form.linkType === 'PRODUCT' ? 'e.g. coca-cola-330ml' : form.linkType === 'CATEGORY' ? 'e.g. 5' : 'https://...'}
            />
          )}

          {form.linkType === 'BANNER_PAGE' && (
            <>
              <div>
                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: 4 }}>Page Content (Markdown)</label>
                <textarea
                  value={form.contentBody}
                  onChange={(e) => set('contentBody', e.target.value)}
                  rows={6}
                  style={{ width: '100%', padding: '8px 10px', borderRadius: 'var(--radius)', border: '1px solid var(--gray-200)', fontSize: '0.85rem', fontFamily: 'monospace', resize: 'vertical' }}
                  placeholder={'# Promotion Title\n\nDescribe your promotion here...\n\n- Item 1\n- Item 2'}
                />
              </div>
              <ProductPicker
                selectedIds={form.productIds}
                onChange={(ids) => set('productIds', ids)}
              />
            </>
          )}

          <Input label="Display Order" type="number" value={form.displayOrder} onChange={(e) => set('displayOrder', Number(e.target.value))} />

          <div style={{ display: 'flex', gap: 10 }}>
            <div style={{ flex: 1 }}>
              <Input label="Start Date" type="datetime-local" value={form.startDate} onChange={(e) => set('startDate', e.target.value)} />
            </div>
            <div style={{ flex: 1 }}>
              <Input label="End Date" type="datetime-local" value={form.endDate} onChange={(e) => set('endDate', e.target.value)} />
            </div>
          </div>

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

/* ── Product picker (search + tag chips) ───────────────────────────── */

function ProductPicker({ selectedIds, onChange }: { selectedIds: number[]; onChange: (ids: number[]) => void }) {
  const [search, setSearch] = useState('');
  const [results, setResults] = useState<Product[]>([]);
  const [selectedProducts, setSelectedProducts] = useState<Map<number, string>>(new Map());
  const [loading, setLoading] = useState(false);
  const [showDropdown, setShowDropdown] = useState(false);
  const wrapperRef = useRef<HTMLDivElement>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout>>(undefined);

  // Load product names for already-selected IDs on mount
  useEffect(() => {
    if (selectedIds.length === 0) return;
    getProducts({ page: 0, size: 200 }).then((res) => {
      const all = res.data.data.content;
      const map = new Map<number, string>();
      for (const p of all) {
        if (selectedIds.includes(p.id)) map.set(p.id, p.name);
      }
      setSelectedProducts(map);
    }).catch(() => {});
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Close dropdown on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) setShowDropdown(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const doSearch = (q: string) => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    if (q.length < 2) { setResults([]); setShowDropdown(false); return; }
    debounceRef.current = setTimeout(() => {
      setLoading(true);
      getProducts({ search: q, page: 0, size: 20 }).then((res) => {
        setResults(res.data.data.content);
        setShowDropdown(true);
      }).finally(() => setLoading(false));
    }, 300);
  };

  const addProduct = (p: Product) => {
    if (selectedIds.includes(p.id)) return;
    const newIds = [...selectedIds, p.id];
    const newMap = new Map(selectedProducts);
    newMap.set(p.id, p.name);
    setSelectedProducts(newMap);
    onChange(newIds);
    setSearch('');
    setResults([]);
    setShowDropdown(false);
  };

  const removeProduct = (id: number) => {
    onChange(selectedIds.filter((x) => x !== id));
    const newMap = new Map(selectedProducts);
    newMap.delete(id);
    setSelectedProducts(newMap);
  };

  return (
    <div ref={wrapperRef}>
      <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 500, marginBottom: 4 }}>Products</label>

      {/* Selected tags */}
      {selectedIds.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 8 }}>
          {selectedIds.map((id) => (
            <span key={id} style={{
              display: 'inline-flex', alignItems: 'center', gap: 4,
              background: 'var(--primary-light, #e8f5e9)', color: 'var(--primary, #2e7d32)',
              padding: '3px 8px', borderRadius: 6, fontSize: '0.78rem', fontWeight: 500,
            }}>
              {selectedProducts.get(id) || `#${id}`}
              <X size={12} style={{ cursor: 'pointer' }} onClick={() => removeProduct(id)} />
            </span>
          ))}
        </div>
      )}

      {/* Search input */}
      <div style={{ position: 'relative' }}>
        <div style={{ display: 'flex', alignItems: 'center', border: '1px solid var(--gray-200)', borderRadius: 'var(--radius)', padding: '6px 10px', gap: 6 }}>
          <Search size={14} style={{ color: 'var(--gray-400)', flexShrink: 0 }} />
          <input
            value={search}
            onChange={(e) => { setSearch(e.target.value); doSearch(e.target.value); }}
            onFocus={() => { if (results.length > 0) setShowDropdown(true); }}
            placeholder="Search products to add…"
            style={{ border: 'none', outline: 'none', flex: 1, fontSize: '0.85rem' }}
          />
          {loading && <Spinner />}
        </div>

        {/* Dropdown */}
        {showDropdown && results.length > 0 && (
          <div style={{
            position: 'absolute', top: '100%', left: 0, right: 0, zIndex: 50,
            background: '#fff', border: '1px solid var(--gray-200)', borderRadius: 'var(--radius)',
            boxShadow: '0 4px 12px rgba(0,0,0,.1)', maxHeight: 200, overflowY: 'auto', marginTop: 4,
          }}>
            {results.filter((p) => !selectedIds.includes(p.id)).map((p) => (
              <div key={p.id} onClick={() => addProduct(p)} style={{
                padding: '8px 12px', cursor: 'pointer', fontSize: '0.83rem',
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                borderBottom: '1px solid var(--gray-50)',
              }}
                onMouseEnter={(e) => (e.currentTarget.style.background = 'var(--gray-50)')}
                onMouseLeave={(e) => (e.currentTarget.style.background = '')}
              >
                <span>{p.name}</span>
                <span style={{ fontSize: '0.75rem', color: 'var(--gray-400)' }}>€{p.price}</span>
              </div>
            ))}
            {results.every((p) => selectedIds.includes(p.id)) && (
              <div style={{ padding: '8px 12px', fontSize: '0.8rem', color: 'var(--gray-400)', textAlign: 'center' }}>All results already added</div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}



