import api from './client';
import type { ApiResponse, AuthResponse } from '../types';

export const authApi = {
  login: (email: string, password: string) =>
    api.post<ApiResponse<AuthResponse>>('/api/auth/admin/login', { email, password }),

  refresh: (refreshToken: string) =>
    api.post<ApiResponse<AuthResponse>>('/api/auth/refresh', { refreshToken }),
};

