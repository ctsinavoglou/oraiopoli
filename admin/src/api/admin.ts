import api from './client';
import type {
  ApiResponse, Page, DashboardStats,
  User, Category, Brand, Product, Order, Banner, Promotion, OrderStatus,
} from '../types';

// Dashboard
export const getDashboard = () =>
  api.get<ApiResponse<DashboardStats>>('/api/admin/dashboard');

// Users
export const getUsers = (params: Record<string, unknown>) =>
  api.get<ApiResponse<Page<User>>>('/api/admin/users', { params });

export const getUserById = (id: number) =>
  api.get<ApiResponse<User>>(`/api/admin/users/${id}`);

export const toggleUserStatus = (id: number) =>
  api.patch<ApiResponse<User>>(`/api/admin/users/${id}/toggle-status`);

// Categories
export const getCategories = () =>
  api.get<ApiResponse<Category[]>>('/api/admin/categories');

export const getCategoriesPaged = (params: Record<string, unknown>) =>
  api.get<ApiResponse<Page<Category>>>('/api/admin/categories/paged', { params });

export const getCategoryById = (id: number) =>
  api.get<ApiResponse<Category>>(`/api/admin/categories/${id}`);

export const createCategory = (data: Record<string, unknown>) =>
  api.post<ApiResponse<Category>>('/api/admin/categories', data);

export const updateCategory = (id: number, data: Record<string, unknown>) =>
  api.put<ApiResponse<Category>>(`/api/admin/categories/${id}`, data);

export const deleteCategory = (id: number) =>
  api.delete<ApiResponse<void>>(`/api/admin/categories/${id}`);

// Brands
export const getBrands = () =>
  api.get<ApiResponse<Brand[]>>('/api/admin/brands');

export const getBrandsPaged = (params: Record<string, unknown>) =>
  api.get<ApiResponse<Page<Brand>>>('/api/admin/brands/paged', { params });

export const getBrandById = (id: number) =>
  api.get<ApiResponse<Brand>>(`/api/admin/brands/${id}`);

export const createBrand = (data: Record<string, unknown>) =>
  api.post<ApiResponse<Brand>>('/api/admin/brands', data);

export const updateBrand = (id: number, data: Record<string, unknown>) =>
  api.put<ApiResponse<Brand>>(`/api/admin/brands/${id}`, data);

export const deleteBrand = (id: number) =>
  api.delete<ApiResponse<void>>(`/api/admin/brands/${id}`);

// Products
export const getProducts = (params: Record<string, unknown>) =>
  api.get<ApiResponse<Page<Product>>>('/api/admin/products', { params });

// File Upload
export const uploadImage = (file: File, type = 'products') => {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('type', type);
  return api.post<ApiResponse<{ url: string }>>('/api/admin/upload/image', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
};

export const getProductById = (id: number) =>
  api.get<ApiResponse<Product>>(`/api/admin/products/${id}`);

export const createProduct = (data: Record<string, unknown>) =>
  api.post<ApiResponse<Product>>('/api/admin/products', data);

export const updateProduct = (id: number, data: Record<string, unknown>) =>
  api.put<ApiResponse<Product>>(`/api/admin/products/${id}`, data);

export const deleteProduct = (id: number) =>
  api.delete<ApiResponse<void>>(`/api/admin/products/${id}`);

export const updateInventory = (id: number, data: { quantity: number; lowStockThreshold?: number }) =>
  api.patch<ApiResponse<Product>>(`/api/admin/products/${id}/inventory`, data);

export const getLowStockProducts = () =>
  api.get<ApiResponse<Product[]>>('/api/admin/products/low-stock');

// Orders
export const getOrders = (params: Record<string, unknown>) =>
  api.get<ApiResponse<Page<Order>>>('/api/admin/orders', { params });

export const getOrderById = (id: number) =>
  api.get<ApiResponse<Order>>(`/api/admin/orders/${id}`);

export const updateOrderStatus = (id: number, status: OrderStatus) =>
  api.patch<ApiResponse<Order>>(`/api/admin/orders/${id}/status`, { status });

// Banners
export const getBanners = () =>
  api.get<ApiResponse<Banner[]>>('/api/admin/banners');

export const getBannerById = (id: number) =>
  api.get<ApiResponse<Banner>>(`/api/admin/banners/${id}`);

export const createBanner = (data: Record<string, unknown>) =>
  api.post<ApiResponse<Banner>>('/api/admin/banners', data);

export const updateBanner = (id: number, data: Record<string, unknown>) =>
  api.put<ApiResponse<Banner>>(`/api/admin/banners/${id}`, data);

export const deleteBanner = (id: number) =>
  api.delete<ApiResponse<void>>(`/api/admin/banners/${id}`);

// Promotions
export const getPromotions = () =>
  api.get<ApiResponse<Promotion[]>>('/api/admin/promotions');

export const getPromotionById = (id: number) =>
  api.get<ApiResponse<Promotion>>(`/api/admin/promotions/${id}`);

export const createPromotion = (data: Record<string, unknown>) =>
  api.post<ApiResponse<Promotion>>('/api/admin/promotions', data);

export const updatePromotion = (id: number, data: Record<string, unknown>) =>
  api.put<ApiResponse<Promotion>>(`/api/admin/promotions/${id}`, data);

export const deletePromotion = (id: number) =>
  api.delete<ApiResponse<void>>(`/api/admin/promotions/${id}`);

// Settings
export const getSettings = () =>
  api.get<ApiResponse<Record<string, string>>>('/api/admin/settings');

export const upsertSetting = (data: { key: string; value: string; description?: string }) =>
  api.post('/api/admin/settings', data);

export const deleteSetting = (key: string) =>
  api.delete(`/api/admin/settings/${key}`);

