export interface User {
  id: number;
  fullName: string;
  email: string;
  phone: string;
  role: 'CUSTOMER' | 'ADMIN' | 'SUPER_ADMIN';
  enabled: boolean;
  createdAt: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  user: User;
}

export interface Category {
  id: number;
  name: string;
  slug: string;
  description?: string;
  imageUrl?: string;
  displayOrder: number;
  active: boolean;
  parentId?: number;
  children?: Category[];
}

export interface Brand {
  id: number;
  name: string;
  slug: string;
  logoUrl?: string;
  description?: string;
  active: boolean;
}

export interface ProductImage {
  id: number;
  imageUrl: string;
  altText?: string;
  displayOrder: number;
}

export interface Product {
  id: number;
  name: string;
  slug: string;
  sku: string;
  description?: string;
  price: number;
  discountPrice?: number;
  unit?: string;
  active: boolean;
  featured: boolean;
  thumbnailUrl?: string;
  categoryName?: string;
  categoryId?: number;
  brandName?: string;
  brandId?: number;
  stockQuantity: number;
  inStock: boolean;
  images?: ProductImage[];
}

export interface OrderItem {
  id: number;
  productId: number;
  productName: string;
  unitPrice: number;
  quantity: number;
  subtotal: number;
}

export interface Order {
  id: number;
  orderNumber: string;
  status: OrderStatus;
  totalAmount: number;
  discountAmount?: number;
  promotionCode?: string;
  deliveryFee?: number;
  shippingAddress: string;
  shippingCity?: string;
  shippingPostalCode?: string;
  contactPhone?: string;
  notes?: string;
  customerName: string;
  customerEmail: string;
  items: OrderItem[];
  createdAt: string;
  updatedAt: string;
}

export type OrderStatus =
  | 'PENDING'
  | 'CONFIRMED'
  | 'PROCESSING'
  | 'SHIPPED'
  | 'DELIVERED'
  | 'COMPLETED'
  | 'CANCELLED'
  | 'REFUNDED';

export interface Banner {
  id: number;
  title: string;
  subtitle?: string;
  imageUrl: string;
  linkUrl?: string;
  displayOrder: number;
  active: boolean;
  startDate?: string;
  endDate?: string;
}

export interface Promotion {
  id: number;
  title: string;
  description?: string;
  code?: string;
  discountPercentage?: number;
  discountAmount?: number;
  minOrderAmount?: number;
  imageUrl?: string;
  active: boolean;
  startDate?: string;
  endDate?: string;
}

export interface DashboardStats {
  totalUsers: number;
  totalProducts: number;
  lowStockProducts: number;
  pendingOrders: number;
  completedOrders: number;
  cancelledOrders: number;
  totalRevenue: number;
  latestOrders: Order[];
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  timestamp: string;
}

export interface Page<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first: boolean;
  last: boolean;
}

