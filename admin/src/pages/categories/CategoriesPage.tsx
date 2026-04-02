import { useState, useMemo, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getCategories, getCategoriesPaged, createCategory, updateCategory, deleteCategory } from '../../api/admin';
import type { Category } from '../../types';
import Button from '../../components/ui/Button';
import Input from '../../components/ui/Input';
import Select from '../../components/ui/Select';
import Modal from '../../components/ui/Modal';
import Pagination from '../../components/ui/Pagination';
import Spinner from '../../components/ui/Spinner';
import toast from 'react-hot-toast';
import { Plus, Pencil, Trash2, ChevronRight, FolderTree, Upload } from 'lucide-react';
import * as XLSX from 'xlsx';

/** Flatten category tree into indent-aware rows */
function flattenWithDepth(categories: Category[]): { cat: Category; depth: number }[] {
  const result: { cat: Category; depth: number }[] = [];

  const byId = new Map<number, Category>();
  categories.forEach((c) => byId.set(c.id, c));

  const roots = categories.filter((c) => !c.parentId);
  const childMap = new Map<number, Category[]>();
  categories.forEach((c) => {
    if (c.parentId) {
      const arr = childMap.get(c.parentId) || [];
      arr.push(c);
      childMap.set(c.parentId, arr);
    }
  });

  function walk(id: number, depth: number) {
    const cat = byId.get(id);
    if (!cat) return;
    result.push({ cat, depth });
    const kids = childMap.get(id) || [];
    kids.sort((a, b) => a.displayOrder - b.displayOrder);
    kids.forEach((k) => walk(k.id, depth + 1));
  }

  roots.sort((a, b) => a.displayOrder - b.displayOrder);
  roots.forEach((r) => walk(r.id, 0));

  categories.forEach((c) => {
    if (!result.some((r) => r.cat.id === c.id)) {
      result.push({ cat: c, depth: 0 });
    }
  });

  return result;
}

/** Build select options with indented labels, excluding a given id (and its descendants) */
function buildParentOptions(categories: Category[], excludeId?: number): { value: string; label: string }[] {
  const rows = flattenWithDepth(categories);
  const excludeIds = new Set<number>();

  if (excludeId != null) {
    excludeIds.add(excludeId);
    let changed = true;
    while (changed) {
      changed = false;
      categories.forEach((c) => {
        if (c.parentId && excludeIds.has(c.parentId) && !excludeIds.has(c.id)) {
          excludeIds.add(c.id);
          changed = true;
        }
      });
    }
  }

  const options: { value: string; label: string }[] = [{ value: '', label: '— None (Root) —' }];
  rows.forEach(({ cat, depth }) => {
    if (!excludeIds.has(cat.id)) {
      const indent = '\u00A0\u00A0\u00A0\u00A0'.repeat(depth);
      options.push({ value: String(cat.id), label: `${indent}${depth > 0 ? '└ ' : ''}${cat.name}` });
    }
  });
  return options;
}

export default function CategoriesPage() {
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<Category | null>(null);
  const [form, setForm] = useState({ name: '', description: '', imageUrl: '', displayOrder: 0, active: true, parentId: '' });
  const [importing, setImporting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [page, setPage] = useState(0);
  const [search, setSearch] = useState('');

  // Paginated query for the table
  const { data: pagedData, isLoading } = useQuery({
    queryKey: ['categories-paged', page, search],
    queryFn: () => getCategoriesPaged({ page, size: 20, search: search || undefined }).then((r) => r.data.data),
  });

  // Full list for parent dropdown & Excel import
  const { data: allCategories } = useQuery({
    queryKey: ['categories'],
    queryFn: () => getCategories().then((r) => r.data.data),
  });

  const saveMut = useMutation({
    mutationFn: (data: Record<string, unknown>) =>
      editing ? updateCategory(editing.id, data) : createCategory(data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['categories'] });
      qc.invalidateQueries({ queryKey: ['categories-paged'] });
      toast.success(editing ? 'Category updated' : 'Category created');
      closeModal();
    },
    onError: () => toast.error('Failed to save category'),
  });

  const delMut = useMutation({
    mutationFn: deleteCategory,
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['categories'] }); qc.invalidateQueries({ queryKey: ['categories-paged'] }); toast.success('Category deleted'); },
  });

  const openCreate = () => {
    setEditing(null);
    setForm({ name: '', description: '', imageUrl: '', displayOrder: 0, active: true, parentId: '' });
    setModalOpen(true);
  };

  const openEdit = (c: Category) => {
    setEditing(c);
    setForm({
      name: c.name, description: c.description || '', imageUrl: c.imageUrl || '',
      displayOrder: c.displayOrder, active: c.active, parentId: c.parentId?.toString() || '',
    });
    setModalOpen(true);
  };

  const closeModal = () => { setModalOpen(false); setEditing(null); };

  const handleSave = () => {
    if (!form.name.trim()) { toast.error('Name is required'); return; }
    saveMut.mutate({
      name: form.name, description: form.description, imageUrl: form.imageUrl,
      displayOrder: form.displayOrder, active: form.active,
      parentId: form.parentId ? Number(form.parentId) : null,
    });
  };

  const handleExcelImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImporting(true);

    try {
      const data = await file.arrayBuffer();
      const workbook = XLSX.read(data);
      const worksheet = workbook.Sheets[workbook.SheetNames[0]];
      const range = XLSX.utils.decode_range(worksheet['!ref'] || 'A1');

      // Fetch current categories to match by name
      const existingRes = await getCategories();
      const existing: Category[] = existingRes.data.data;

      // Build lookup: root categories by name, children by parentId+name
      const rootByName = new Map<string, Category>();
      const childByParentAndName = new Map<string, Category>();
      for (const cat of existing) {
        if (!cat.parentId) {
          rootByName.set(cat.name, cat);
        } else {
          childByParentAndName.set(`${cat.parentId}::${cat.name}`, cat);
        }
      }

      let created = 0;
      let updated = 0;
      let skipped = 0;
      let failed = 0;

      for (let col = range.s.c; col <= range.e.c; col++) {
        const displayOrder = col + 1;

        // Row 1 = parent category
        const parentCell = worksheet[XLSX.utils.encode_cell({ r: 0, c: col })];
        if (!parentCell?.v) continue;

        const parentName = String(parentCell.v).trim();
        if (!parentName) continue;

        let parentId: number;
        const existingParent = rootByName.get(parentName);

        try {
          if (existingParent) {
            // Check if anything changed
            const needsUpdate =
              existingParent.displayOrder !== displayOrder ||
              existingParent.description !== parentName;

            if (needsUpdate) {
              await updateCategory(existingParent.id, {
                name: parentName,
                description: parentName,
                displayOrder,
                active: existingParent.active,
                parentId: null,
              });
              updated++;
            } else {
              skipped++;
            }
            parentId = existingParent.id;
          } else {
            const parentRes = await createCategory({
              name: parentName,
              description: parentName,
              displayOrder,
              active: true,
              parentId: null,
            });
            parentId = parentRes.data.data.id;
            created++;
          }

          // Rows 2+ = sub-categories
          for (let row = 1; row <= range.e.r; row++) {
            const cell = worksheet[XLSX.utils.encode_cell({ r: row, c: col })];
            if (!cell?.v) continue;

            const subName = String(cell.v).trim();
            if (!subName) continue;

            const existingChild = childByParentAndName.get(`${parentId}::${subName}`);

            try {
              if (existingChild) {
                const needsUpdate =
                  existingChild.displayOrder !== row ||
                  existingChild.description !== subName;

                if (needsUpdate) {
                  await updateCategory(existingChild.id, {
                    name: subName,
                    description: subName,
                    displayOrder: row,
                    active: existingChild.active,
                    parentId,
                  });
                  updated++;
                } else {
                  skipped++;
                }
              } else {
                await createCategory({
                  name: subName,
                  description: subName,
                  displayOrder: row,
                  active: true,
                  parentId,
                });
                created++;
              }
            } catch {
              failed++;
              console.error(`Failed to save subcategory: ${subName}`);
            }
          }
        } catch {
          failed++;
          console.error(`Failed to save parent category: ${parentName}`);
        }
      }

      qc.invalidateQueries({ queryKey: ['categories'] });
      qc.invalidateQueries({ queryKey: ['categories-paged'] });
      const parts = [
        created > 0 ? `${created} created` : '',
        updated > 0 ? `${updated} updated` : '',
        skipped > 0 ? `${skipped} unchanged` : '',
        failed > 0 ? `${failed} failed` : '',
      ].filter(Boolean).join(', ');
      toast.success(`Import complete! ${parts}.`);
    } catch (err) {
      console.error(err);
      toast.error('Failed to parse Excel file');
    } finally {
      setImporting(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const parentOptions = useMemo(() => buildParentOptions(allCategories || [], editing?.id), [allCategories, editing]);
  const parentNameMap = useMemo(() => {
    const map = new Map<number, string>();
    (allCategories || []).forEach((c) => map.set(c.id, c.name));
    return map;
  }, [allCategories]);

  const tableRows = pagedData?.content || [];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, flexWrap: 'wrap', gap: 10 }}>
        <h1 style={{ fontSize: '1.4rem', fontWeight: 700 }}>Categories</h1>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          <Input
            placeholder="Search categories..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(0); }}
            style={{ width: 220 }}
          />
          <input
            ref={fileInputRef}
            type="file"
            accept=".xlsx,.xls"
            style={{ display: 'none' }}
            onChange={handleExcelImport}
          />
          <Button
            variant="outline"
            onClick={() => fileInputRef.current?.click()}
            loading={importing}
            disabled={importing}
          >
            <Upload size={16} /> Import from Excel
          </Button>
          <Button onClick={openCreate}><Plus size={16} /> Add Category</Button>
        </div>
      </div>

      {isLoading ? <Spinner /> : (
        <div style={{ background: '#fff', borderRadius: 'var(--radius)', boxShadow: 'var(--shadow)', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
            <thead>
              <tr style={{ background: 'var(--gray-50)', textAlign: 'left' }}>
                <th style={th}>ID</th><th style={th}>Name</th><th style={th}>Parent</th><th style={th}>Slug</th>
                <th style={th}>Order</th><th style={th}>Status</th><th style={th}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {tableRows.map((c) => (
                <tr key={c.id} style={{ borderBottom: '1px solid var(--gray-100)' }}>
                  <td style={td}>{c.id}</td>
                  <td style={td}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 4, paddingLeft: c.parentId ? 24 : 0 }}>
                      {c.parentId ? (
                        <ChevronRight size={14} style={{ color: 'var(--gray-400)', flexShrink: 0 }} />
                      ) : (allCategories || []).some((x) => x.parentId === c.id) ? (
                        <FolderTree size={14} style={{ color: 'var(--primary)', flexShrink: 0 }} />
                      ) : null}
                      <span style={{ fontWeight: c.parentId ? 400 : 600 }}>{c.name}</span>
                    </div>
                  </td>
                  <td style={td}>
                    {c.parentId ? (
                      <span style={{ fontSize: '0.78rem', color: 'var(--gray-500)' }}>
                        {parentNameMap.get(c.parentId) || `#${c.parentId}`}
                      </span>
                    ) : (
                      <span style={{ fontSize: '0.78rem', color: 'var(--gray-300)' }}>—</span>
                    )}
                  </td>
                  <td style={td}><code style={{ fontSize: '0.78rem', color: 'var(--gray-500)' }}>{c.slug}</code></td>
                  <td style={td}>{c.displayOrder}</td>
                  <td style={td}><span style={{ color: c.active ? 'var(--green)' : 'var(--red)', fontWeight: 600, fontSize: '0.8rem' }}>{c.active ? 'Active' : 'Inactive'}</span></td>
                  <td style={{ ...td, display: 'flex', gap: 6 }}>
                    <Button size="sm" variant="outline" onClick={() => openEdit(c)}><Pencil size={14} /></Button>
                    <Button size="sm" variant="danger" onClick={() => { if (confirm('Delete?')) delMut.mutate(c.id); }}><Trash2 size={14} /></Button>
                  </td>
                </tr>
              ))}
              {tableRows.length === 0 && (
                <tr><td colSpan={7} style={{ ...td, textAlign: 'center', color: 'var(--gray-400)' }}>No categories</td></tr>
              )}
            </tbody>
          </table>
          {pagedData && <Pagination page={page} totalPages={pagedData.totalPages} onPageChange={setPage} />}
        </div>
      )}

      <Modal isOpen={modalOpen} onClose={closeModal} title={editing ? 'Edit Category' : 'Add Category'}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <Input label="Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
          <Input label="Description" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
          <Input label="Image URL" value={form.imageUrl} onChange={(e) => setForm({ ...form, imageUrl: e.target.value })} />
          <Input label="Display Order" type="number" value={form.displayOrder} onChange={(e) => setForm({ ...form, displayOrder: Number(e.target.value) })} />
          <Select
            label="Parent Category"
            value={form.parentId}
            onChange={(e) => setForm({ ...form, parentId: e.target.value })}
            options={parentOptions}
          />
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

