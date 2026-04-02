import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import Input from '../../components/ui/Input';
import Button from '../../components/ui/Button';
import toast from 'react-hot-toast';

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await login(email, password);
      toast.success('Welcome back!');
      navigate('/');
    } catch {
      toast.error('Invalid email or password');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%)',
    }}>
      <form onSubmit={handleSubmit} style={{
        background: '#fff', borderRadius: 16, padding: 40, width: '100%', maxWidth: 400,
        boxShadow: '0 20px 60px rgba(0,0,0,.2)',
      }}>
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--primary)' }}>Oraiopoli</h1>
          <p style={{ color: 'var(--gray-500)', fontSize: '0.875rem', marginTop: 4 }}>Admin Dashboard</p>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <Input
            label="Email" type="email" placeholder="admin@oraiopoli.com"
            value={email} onChange={(e) => setEmail(e.target.value)} required
          />
          <Input
            label="Password" type="password" placeholder="••••••••"
            value={password} onChange={(e) => setPassword(e.target.value)} required
          />
          <Button type="submit" loading={loading} style={{ width: '100%', marginTop: 8 }}>
            Sign In
          </Button>
        </div>
      </form>
    </div>
  );
}

