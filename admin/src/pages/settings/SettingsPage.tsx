import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getSettings, upsertSetting, deleteSetting } from '../../api/admin';
import Button from '../../components/ui/Button';
import Input from '../../components/ui/Input';
import Spinner from '../../components/ui/Spinner';
import toast from 'react-hot-toast';
import { Plus, Trash2, Save } from 'lucide-react';

export default function SettingsPage() {
  const qc = useQueryClient();
  const [newKey, setNewKey] = useState('');
  const [newValue, setNewValue] = useState('');

  const { data: settings, isLoading } = useQuery({
    queryKey: ['settings'],
    queryFn: () => getSettings().then((r) => r.data.data),
  });

  const saveMut = useMutation({
    mutationFn: (data: { key: string; value: string }) => upsertSetting(data),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['settings'] }); toast.success('Setting saved'); },
  });

  const delMut = useMutation({
    mutationFn: (key: string) => deleteSetting(key),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['settings'] }); toast.success('Setting deleted'); },
  });

  const handleAdd = () => {
    if (!newKey.trim()) { toast.error('Key is required'); return; }
    saveMut.mutate({ key: newKey, value: newValue });
    setNewKey('');
    setNewValue('');
  };

  return (
    <div>
      <h1 style={{ fontSize: '1.4rem', fontWeight: 700, marginBottom: 20 }}>Store Settings</h1>

      {isLoading ? <Spinner /> : (
        <div style={{ background: '#fff', borderRadius: 'var(--radius)', boxShadow: 'var(--shadow)', overflow: 'hidden' }}>
          <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--gray-200)', display: 'flex', gap: 10, alignItems: 'end', flexWrap: 'wrap' }}>
            <Input label="Key" value={newKey} onChange={(e) => setNewKey(e.target.value)} placeholder="setting_key" style={{ width: 200 }} />
            <Input label="Value" value={newValue} onChange={(e) => setNewValue(e.target.value)} placeholder="value" style={{ width: 300 }} />
            <Button onClick={handleAdd} loading={saveMut.isPending}><Plus size={16} /> Add</Button>
          </div>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
            <thead>
              <tr style={{ background: 'var(--gray-50)', textAlign: 'left' }}>
                <th style={th}>Key</th><th style={th}>Value</th><th style={th}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {settings && Object.entries(settings).map(([key, value]) => (
                <SettingRow key={key} settingKey={key} value={value}
                  onSave={(v) => saveMut.mutate({ key, value: v })}
                  onDelete={() => { if (confirm('Delete?')) delMut.mutate(key); }}
                />
              ))}
              {settings && Object.keys(settings).length === 0 && (
                <tr><td colSpan={3} style={{ ...td, textAlign: 'center', color: 'var(--gray-400)' }}>No settings configured</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function SettingRow({ settingKey, value, onSave, onDelete }: { settingKey: string; value: string; onSave: (v: string) => void; onDelete: () => void }) {
  const [val, setVal] = useState(value);
  return (
    <tr style={{ borderBottom: '1px solid var(--gray-100)' }}>
      <td style={td}><code style={{ fontSize: '0.8rem' }}>{settingKey}</code></td>
      <td style={td}><input value={val} onChange={(e) => setVal(e.target.value)} style={{ padding: '6px 10px', border: '1px solid var(--gray-300)', borderRadius: 'var(--radius)', fontSize: '0.85rem', width: '100%' }} /></td>
      <td style={{ ...td, display: 'flex', gap: 6 }}>
        <Button size="sm" variant="outline" onClick={() => onSave(val)}><Save size={14} /></Button>
        <Button size="sm" variant="danger" onClick={onDelete}><Trash2 size={14} /></Button>
      </td>
    </tr>
  );
}

const th: React.CSSProperties = { padding: '10px 16px', fontWeight: 600, fontSize: '0.78rem', color: 'var(--gray-500)' };
const td: React.CSSProperties = { padding: '12px 16px' };

