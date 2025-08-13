// src/services/api.js - Configuración base de la API
import axios from 'axios';

// 🔧 Configuración base
const API_BASE_URL = 'http://localhost:3000'; // Tu backend Node.js

// Crear instancia de axios
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000, // 10 segundos
});

// 🔒 Interceptor para agregar el token a todas las requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('adminToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    // Log para debugging
    console.log(`🔄 ${config.method?.toUpperCase()} ${config.url}`);
    
    return config;
  },
  (error) => {
    console.error('❌ Error en request:', error);
    return Promise.reject(error);
  }
);

// 🔒 Interceptor para manejar respuestas y errores
api.interceptors.response.use(
  (response) => {
    // Log para debugging
    console.log(`✅ ${response.config.method?.toUpperCase()} ${response.config.url} - ${response.status}`);
    return response;
  },
  (error) => {
    console.error(`❌ ${error.config?.method?.toUpperCase()} ${error.config?.url} - ${error.response?.status}`);
    
    // Si el token expiró o es inválido
    if (error.response?.status === 401 || error.response?.status === 403) {
      // Limpiar token inválido
      localStorage.removeItem('adminToken');
      localStorage.removeItem('adminUser');
      
      // Redirigir al login (solo si no estamos ya en login)
      if (!window.location.pathname.includes('/login')) {
        window.location.href = '/login';
      }
    }
    
    return Promise.reject(error);
  }
);

// 🔧 Funciones utilitarias para requests
export const apiRequest = {
  // GET request
  get: async (url, params = {}) => {
    try {
      const response = await api.get(url, { params });
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.message || error.message);
    }
  },

  // POST request
  post: async (url, data = {}) => {
    try {
      const response = await api.post(url, data);
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.message || error.message);
    }
  },

  // PUT request
  put: async (url, data = {}) => {
    try {
      const response = await api.put(url, data);
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.message || error.message);
    }
  },

  // DELETE request
  delete: async (url) => {
    try {
      const response = await api.delete(url);
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.message || error.message);
    }
  },

  // POST con FormData (para archivos)
  postFormData: async (url, formData) => {
    try {
      const response = await api.post(url, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.message || error.message);
    }
  }
};

// 🔧 Funciones específicas para el admin
export const adminAPI = {
  // Autenticación - RUTA CORREGIDA
  login: (credentials) => apiRequest.post('/api/login', credentials),
  
  // Dashboard
  getDashboard: () => apiRequest.get('/payments/dashboard'),
  
  // Pagos
  getPendingPayments: (params) => apiRequest.get('/payments/pending', params),
  approvePayment: (calendarId, data) => apiRequest.put(`/payments/${calendarId}/approve`, data),
  rejectPayment: (calendarId, data) => apiRequest.put(`/payments/${calendarId}/reject`, data),
  getPaymentHistory: (params) => apiRequest.get('/payments/history', params),
  
  // Usuarios
  getUsers: (params) => apiRequest.get('/users', params),
  getUser: (userId) => apiRequest.get(`/users/${userId}`),
  createUser: (data) => apiRequest.post('/users', data),
  updateUser: (userId, data) => apiRequest.put(`/users/${userId}`, data),
  deleteUser: (userId) => apiRequest.delete(`/users/${userId}`),
  getUserStats: () => apiRequest.get('/users/stats'),
  
  // Canchas
  getFields: (params) => apiRequest.get('/fields/list', params),
  getFieldsByCompany: (companyId) => apiRequest.get(`/fields/company/${companyId}`),
  
  // Empresas
  getCompanies: (params) => apiRequest.get('/companies', params),
  
  // Reservas
  getAllBookings: (params) => apiRequest.get('/calendars', params),
  getBookingDetail: (calendarId) => apiRequest.get(`/calendars/${calendarId}`),
  updateBookingStatus: (data) => apiRequest.put('/calendars/update-status', data),
  
  // Archivos
  getFile: (category, filename) => `${API_BASE_URL}/upload/files/${category}/${filename}`,
};

// 🔧 Exportar la instancia por si se necesita acceso directo
export default api;