
import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getOrders, getOrderById, updateOrderStatus } from '../../api/admin';
import type { Order, OrderStatus } from '../../types';
import Button from '../../components/ui/Button';
import Input from '../../components/ui/Input';
import Badge from '../../components/ui/Badge';
import Modal from '../../components/ui/Modal';
import Pagination from '../../components/ui/Pagination';
import Spinner from '../../components/ui/Spinner';
import toast from 'react-hot-toast';
import { Eye } from 'lucide-react';

const statuses: OrderStatus[] = ['PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'COMPLETED', 'CANCELLED', 'REFUNDED'];

const deliveryMethodLabel = (m?: string) => {
  switch (m) {
    case 'EXPRESS': return { label: '⚡ Express', color: '#f59e0b', bg: '#fef3c7' };
    case 'PICKUP': return { label: '🏪 Pickup', color: '#8b5cf6', bg: '#ede9fe' };
    default: return { label: '🚚 Standard', color: '#2563eb', bg: '#dbeafe' };
  }
};

export default function OrdersPage() {
  const qc = useQueryClient();
  const [page, setPage] = useState(0);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('PENDING');
  const [detailOpen, setDetailOpen] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [newStatus, setNewStatus] = useState<OrderStatus>('PENDING');

  const { data, isLoading } = useQuery({
    queryKey: ['orders', page, search, statusFilter],
    queryFn: () => getOrders({
      page, size: 20,
      search: search || undefined,
      status: statusFilter || undefined,
    }).then((r) => r.data.data),
  });

  const statusMut = useMutation({
    mutationFn: ({ id, status }: { id: number; status: OrderStatus }) => updateOrderStatus(id, status),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['orders'] });
      toast.success('Order status updated');
      setDetailOpen(false);
    },
  });

  const openDetail = async (id: number) => {
    try {
      const res = await getOrderById(id);
      setSelectedOrder(res.data.data);
      setNewStatus(res.data.data.status);
      setDetailOpen(true);
    } catch { toast.error('Failed to load order'); }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, flexWrap: 'wrap', gap: 10 }}>
        <h1 style={{ fontSize: '1.4rem', fontWeight: 700 }}>Orders</h1>
        <div style={{ display: 'flex', gap: 10 }}>
          <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }} style={sel}>
            <option value="">All Statuses</option>
            {statuses.map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
          <Input placeholder="Search order #..." value={search} onChange={(e) => { setSearch(e.target.value); setPage(0); }} style={{ width: 220 }} />
        </div>
      </div>

      {isLoading ? <Spinner /> : (
        <div style={{ background: '#fff', borderRadius: 'var(--radius)', boxShadow: 'var(--shadow)', overflow: 'hidden' }}>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
              <thead>
                <tr style={{ background: 'var(--gray-50)', textAlign: 'left' }}>
                  <th style={th}>Order #</th><th style={th}>Customer</th><th style={th}>Amount</th>
                  <th style={th}>Status</th><th style={th}>Delivery</th><th style={th}>Notes</th><th style={th}>Date</th><th style={th}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {data?.content.map((o) => (
                  <tr key={o.id} style={{ borderBottom: '1px solid var(--gray-100)' }}>
                    <td style={td}>{o.orderNumber}</td>
                    <td style={td}><div>{o.customerName}</div><div style={{ fontSize: '0.75rem', color: 'var(--gray-400)' }}>{o.customerEmail}</div></td>
                    <td style={td}>
                      €{o.totalAmount.toFixed(2)}
                      {o.promotionCode && <span style={{ display: 'inline-block', marginLeft: 6, padding: '1px 6px', background: 'var(--green-light, #dcfce7)', color: 'var(--green, #16a34a)', borderRadius: 4, fontSize: '0.7rem', fontWeight: 600 }}>🏷 {o.promotionCode}</span>}
                    </td>
                    <td style={td}><Badge status={o.status} /></td>
                    <td style={td}>
                      {(() => { const dm = deliveryMethodLabel(o.deliveryMethod); return (
                        <span style={{ display: 'inline-block', padding: '2px 8px', background: dm.bg, color: dm.color, borderRadius: 6, fontSize: '0.72rem', fontWeight: 600 }}>{dm.label}</span>
                      ); })()}
                      {o.deliveryTimeSlot && <div style={{ fontSize: '0.72rem', color: 'var(--gray-500)', marginTop: 2 }}>{o.deliveryTimeSlot}</div>}
                    </td>
                    <td style={td}>{o.notes ? <span style={{ fontWeight: 700 }}>{o.notes}</span> : <span style={{ color: 'var(--gray-300)' }}>—</span>}</td>
                    <td style={td}>{new Date(o.createdAt).toLocaleString()}</td>
                    <td style={td}>
                      <Button size="sm" variant="outline" onClick={() => openDetail(o.id)}><Eye size={14} /> View</Button>
                    </td>
                  </tr>
                ))}
                {data?.content.length === 0 && (
                  <tr><td colSpan={8} style={{ ...td, textAlign: 'center', color: 'var(--gray-400)' }}>No orders found</td></tr>
                )}
              </tbody>
            </table>
          </div>
          {data && <Pagination page={page} totalPages={data.totalPages} onPageChange={setPage} />}
        </div>
      )}

      <Modal isOpen={detailOpen} onClose={() => setDetailOpen(false)} title={`Order ${selectedOrder?.orderNumber || ''}`} width={640}>
        {selectedOrder && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, fontSize: '0.85rem' }}>
              <div><strong>Customer:</strong> {selectedOrder.customerName}</div>
              <div><strong>Email:</strong> {selectedOrder.customerEmail}</div>
              <div><strong>Phone:</strong> {selectedOrder.contactPhone || '—'}</div>
              <div><strong>Date:</strong> {new Date(selectedOrder.createdAt).toLocaleString()}</div>
              <div>
                <strong>Delivery:</strong>{' '}
                {(() => { const dm = deliveryMethodLabel(selectedOrder.deliveryMethod); return (
                  <span style={{ display: 'inline-block', padding: '2px 8px', background: dm.bg, color: dm.color, borderRadius: 6, fontSize: '0.78rem', fontWeight: 600 }}>{dm.label}</span>
                ); })()}
                {selectedOrder.deliveryTimeSlot && <span style={{ marginLeft: 6, fontSize: '0.82rem' }}>({selectedOrder.deliveryTimeSlot})</span>}
              </div>
              <div style={{ gridColumn: '1 / -1' }}><strong>Address:</strong> {selectedOrder.shippingAddress}{selectedOrder.shippingCity ? `, ${selectedOrder.shippingCity}` : ''}</div>
              {selectedOrder.notes && <div style={{ gridColumn: '1 / -1' }}><strong>Notes:</strong> {selectedOrder.notes}</div>}
              {selectedOrder.promotionCode && (
                <div style={{ gridColumn: '1 / -1' }}>
                  <strong>Promo Code:</strong>{' '}
                  <code style={{ background: 'var(--gray-100)', padding: '2px 8px', borderRadius: 4, fontSize: '0.82rem', fontWeight: 600 }}>{selectedOrder.promotionCode}</code>
                  {selectedOrder.discountAmount != null && selectedOrder.discountAmount > 0 && (
                    <span style={{ marginLeft: 8, color: 'var(--green, #16a34a)', fontWeight: 600 }}>
                      -€{selectedOrder.discountAmount.toFixed(2)} discount
                    </span>
                  )}
                </div>
              )}
            </div>

            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
              <thead>
                <tr style={{ background: 'var(--gray-50)' }}>
                  <th style={th}>Product</th><th style={th}>Price</th><th style={th}>Qty</th><th style={th}>Subtotal</th>
                </tr>
              </thead>
              <tbody>
                {selectedOrder.items.map((item) => (
                  <tr key={item.id} style={{ borderBottom: '1px solid var(--gray-100)' }}>
                    <td style={td}>
                      {item.productName}
                      {item.freeQuantity > 0 && (
                        <span style={{ marginLeft: 6, padding: '1px 6px', background: 'var(--primary, #2563eb)', color: '#fff', borderRadius: 4, fontSize: '0.7rem', fontWeight: 600 }}>
                          {`${item.paidQuantity}+${item.freeQuantity} FREE`}
                        </span>
                      )}
                    </td>
                    <td style={td}>€{item.unitPrice.toFixed(2)}</td>
                    <td style={td}>
                      {item.freeQuantity > 0 ? (
                        <span title={`${item.paidQuantity} paid + ${item.freeQuantity} free`}>
                          {item.quantity} <span style={{ fontSize: '0.7rem', color: 'var(--gray-400)' }}>({item.paidQuantity} paid)</span>
                        </span>
                      ) : item.quantity}
                    </td>
                    <td style={td}>
                      {item.freeQuantity > 0 ? (
                        <>
                          <span style={{ textDecoration: 'line-through', color: 'var(--gray-400)', marginRight: 4, fontSize: '0.78rem' }}>€{(item.unitPrice * item.quantity).toFixed(2)}</span>
                          <span style={{ color: 'var(--green, #16a34a)', fontWeight: 600 }}>€{item.subtotal.toFixed(2)}</span>
                        </>
                      ) : (
                        <>€{item.subtotal.toFixed(2)}</>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                {(() => {
                  const hasDiscount = selectedOrder.discountAmount != null && selectedOrder.discountAmount > 0;
                  const hasDelivery = selectedOrder.deliveryFee != null && selectedOrder.deliveryFee > 0;
                  const hasExpress = selectedOrder.expressDeliveryFee != null && selectedOrder.expressDeliveryFee > 0;
                  const hasBagFee = selectedOrder.plasticBagFee != null && selectedOrder.plasticBagFee > 0;
                  const itemsSubtotal = selectedOrder.totalAmount
                    + (selectedOrder.discountAmount ?? 0)
                    - (selectedOrder.deliveryFee ?? 0)
                    - (selectedOrder.expressDeliveryFee ?? 0)
                    - (selectedOrder.plasticBagFee ?? 0);
                  if (hasDiscount || hasDelivery || hasExpress || hasBagFee) {
                    return (
                      <>
                        <tr><td colSpan={3} style={{ ...td, textAlign: 'right', color: 'var(--gray-500)' }}>Subtotal:</td>
                          <td style={{ ...td, color: 'var(--gray-500)' }}>€{itemsSubtotal.toFixed(2)}</td></tr>
                        {hasDiscount && (
                          <tr><td colSpan={3} style={{ ...td, textAlign: 'right', color: 'var(--green, #16a34a)', fontWeight: 600 }}>Discount ({selectedOrder.promotionCode}):</td>
                            <td style={{ ...td, color: 'var(--green, #16a34a)', fontWeight: 600 }}>-€{selectedOrder.discountAmount!.toFixed(2)}</td></tr>
                        )}
                        {hasBagFee && (
                          <tr><td colSpan={3} style={{ ...td, textAlign: 'right', color: 'var(--gray-500)' }}>Plastic Bags:</td>
                            <td style={{ ...td, color: 'var(--gray-500)' }}>€{selectedOrder.plasticBagFee!.toFixed(2)}</td></tr>
                        )}
                        {hasDelivery && (
                          <tr><td colSpan={3} style={{ ...td, textAlign: 'right', color: 'var(--gray-500)' }}>Delivery Fee:</td>
                            <td style={{ ...td, color: 'var(--gray-500)' }}>€{selectedOrder.deliveryFee!.toFixed(2)}</td></tr>
                        )}
                        {hasExpress && (
                          <tr><td colSpan={3} style={{ ...td, textAlign: 'right', color: '#f59e0b' }}>Express Surcharge:</td>
                            <td style={{ ...td, color: '#f59e0b' }}>€{selectedOrder.expressDeliveryFee!.toFixed(2)}</td></tr>
                        )}
                      </>
                    );
                  }
                  return null;
                })()}
                <tr><td colSpan={3} style={{ ...td, fontWeight: 700, textAlign: 'right' }}>Total:</td>
                  <td style={{ ...td, fontWeight: 700 }}>€{selectedOrder.totalAmount.toFixed(2)}</td></tr>
              </tfoot>
            </table>

            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <label style={{ fontWeight: 600, fontSize: '0.85rem' }}>Update Status:</label>
              <select value={newStatus} onChange={(e) => setNewStatus(e.target.value as OrderStatus)} style={sel}>
                {statuses.map((s) => <option key={s} value={s}>{s}</option>)}
              </select>
              <Button size="sm" variant="accent"
                loading={statusMut.isPending}
                onClick={() => statusMut.mutate({ id: selectedOrder.id, status: newStatus })}>
                Update
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}

const th: React.CSSProperties = { padding: '10px 16px', fontWeight: 600, fontSize: '0.78rem', color: 'var(--gray-500)', textAlign: 'left' };
const td: React.CSSProperties = { padding: '12px 16px' };
const sel: React.CSSProperties = { padding: '8px 12px', borderRadius: 'var(--radius)', border: '1px solid var(--gray-300)', fontSize: '0.85rem', outline: 'none', background: '#fff' };

