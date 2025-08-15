// src/services/api.js - CORREGIDO para usar rutas existentes del backend
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

  // PATCH request
  patch: async (url, data = {}) => {
    try {
      const response = await api.patch(url, data);
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
  
  // 🔧 ========== CUENTAS BANCARIAS (CORREGIDAS) ==========
  
  /**
   * Obtener todas las cuentas bancarias del admin
   */
  getBankAccounts: async () => {
    try {
      const response = await apiRequest.get('/bank_accounts/list'); // 🔧 Ruta corregida
      return {
        success: response.status || true,
        data: response.data || [],
        meta: {
          total: response.data?.length || 0,
          active: response.data?.filter(acc => !acc.b_account_delete).length || 0,
          inactive: response.data?.filter(acc => acc.b_account_delete).length || 0
        }
      };
    } catch (error) {
      console.error('Error obteniendo cuentas bancarias:', error);
      return {
        success: false,
        message: error.message || 'Error obteniendo cuentas bancarias',
        error
      };
    }
  },

  /**
   * Crear nueva cuenta bancaria
   */
  createBankAccount: async (accountData) => {
    try {
      const response = await apiRequest.post('/bank_accounts/create', { // 🔧 Ruta corregida
        b_account_bank: accountData.bank,
        b_account_number: accountData.accountNumber,
        b_account_ci: accountData.ownerCI,
        b_account_type: accountData.accountType,
        b_account_owner: accountData.ownerName,
        company_id: accountData.companyId || null
      });
      
      return {
        success: response.status || true,
        data: response.info || response.data,
        message: 'Cuenta bancaria creada exitosamente'
      };
    } catch (error) {
      console.error('Error creando cuenta bancaria:', error);
      return {
        success: false,
        message: error.message || 'Error creando cuenta bancaria',
        errors: error.errors || {},
        error
      };
    }
  },

  /**
   * Actualizar cuenta bancaria existente
   */
  updateBankAccount: async (accountId, accountData) => {
    try {
      const response = await apiRequest.patch('/bank_accounts/update', { // 🔧 Ruta corregida
        b_account_id: accountId, // 🔧 Agregar ID en el body
        b_account_bank: accountData.bank,
        b_account_number: accountData.accountNumber,
        b_account_ci: accountData.ownerCI,
        b_account_type: accountData.accountType,
        b_account_owner: accountData.ownerName
      });
      
      return {
        success: response.status || true,
        data: response.info || response.data,
        message: 'Cuenta bancaria actualizada exitosamente'
      };
    } catch (error) {
      console.error('Error actualizando cuenta bancaria:', error);
      return {
        success: false,
        message: error.message || 'Error actualizando cuenta bancaria',
        errors: error.errors || {},
        error
      };
    }
  },

  /**
   * Eliminar cuenta bancaria (temporal - sin implementar aún)
   */
  deleteBankAccount: async (accountId) => {
    try {
      // 🚨 FUNCIÓN TEMPORAL - El backend no tiene esta ruta aún
      console.log('⚠️ Eliminando cuenta (función temporal):', accountId);
      
      // Simular eliminación exitosa por ahora
      await new Promise(resolve => setTimeout(resolve, 500)); // Simular delay
      
      return {
        success: true,
        message: 'Cuenta bancaria eliminada exitosamente'
      };
    } catch (error) {
      console.error('Error eliminando cuenta bancaria:', error);
      return {
        success: false,
        message: error.message || 'Error eliminando cuenta bancaria',
        error
      };
    }
  },

  /**
   * Activar/Desactivar cuenta bancaria (temporal - sin implementar aún)
   */
  toggleBankAccountStatus: async (accountId, isActive) => {
    try {
      // 🚨 FUNCIÓN TEMPORAL - El backend no tiene esta ruta aún
      console.log(`⚠️ Cambiando estado cuenta ${accountId} a ${isActive ? 'activa' : 'inactiva'} (función temporal)`);
      
      // Simular cambio exitoso por ahora
      await new Promise(resolve => setTimeout(resolve, 500)); // Simular delay
      
      return {
        success: true,
        data: { 
          b_account_id: accountId, 
          b_account_delete: !isActive,
          is_active: isActive 
        },
        message: `Cuenta bancaria ${isActive ? 'activada' : 'desactivada'} exitosamente`
      };
    } catch (error) {
      console.error('Error cambiando estado de cuenta bancaria:', error);
      return {
        success: false,
        message: error.message || 'Error cambiando estado de cuenta bancaria',
        error
      };
    }
  },

  /**
   * Obtener detalles de una cuenta bancaria específica (usando lista)
   */
  getBankAccountById: async (accountId) => {
    try {
      // 🚨 FUNCIÓN TEMPORAL - Buscar en la lista por ahora
      const allAccounts = await adminAPI.getBankAccounts();
      if (allAccounts.success && allAccounts.data) {
        const account = allAccounts.data.find(acc => acc.b_account_id == accountId);
        if (account) {
          return {
            success: true,
            data: account
          };
        }
      }
      
      return {
        success: false,
        message: 'Cuenta bancaria no encontrada'
      };
    } catch (error) {
      console.error('Error obteniendo detalles de cuenta bancaria:', error);
      return {
        success: false,
        message: error.message || 'Error obteniendo detalles de cuenta bancaria',
        error
      };
    }
  },

  /**
   * Verificar si un número de cuenta ya existe (usando lista)
   */
  checkAccountNumberExists: async (accountNumber, excludeId = null) => {
    try {
      // 🚨 FUNCIÓN TEMPORAL - Verificar desde la lista por ahora
      const allAccounts = await adminAPI.getBankAccounts();
      if (allAccounts.success && allAccounts.data) {
        const exists = allAccounts.data.some(acc => 
          acc.b_account_number == accountNumber && 
          (excludeId ? acc.b_account_id != excludeId : true)
        );
        
        return {
          success: true,
          exists: exists
        };
      }
      
      return {
        success: false,
        message: 'Error verificando número de cuenta'
      };
    } catch (error) {
      console.error('Error verificando número de cuenta:', error);
      return {
        success: false,
        message: 'Error verificando número de cuenta',
        error
      };
    }
  },

  /**
   * Obtener estadísticas de cuentas bancarias (calculadas desde lista)
   */
  getBankAccountsStats: async () => {
    try {
      // 🚨 FUNCIÓN TEMPORAL - Calcular desde la lista por ahora
      const allAccounts = await adminAPI.getBankAccounts();
      if (allAccounts.success && allAccounts.data) {
        const total = allAccounts.data.length;
        const active = allAccounts.data.filter(acc => !acc.b_account_delete && acc.is_active !== false).length;
        const inactive = total - active;
        
        return {
          success: true,
          data: { total, active, inactive }
        };
      }
      
      return {
        success: false,
        message: 'Error calculando estadísticas'
      };
    } catch (error) {
      console.error('Error obteniendo estadísticas:', error);
      return {
        success: false,
        message: 'Error obteniendo estadísticas',
        error
      };
    }
  },
  
  // Archivos
  getFile: (category, filename) => `${API_BASE_URL}/upload/files/${category}/${filename}`,
};

// 🔧 Exportar la instancia por si se necesita acceso directo
export default api;