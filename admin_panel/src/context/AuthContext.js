// src/context/AuthContext.js - Context de autenticación
import React, { createContext, useContext, useState, useEffect } from 'react';
import { adminAPI } from '../services/api';

// Crear el contexto
const AuthContext = createContext();

// Hook personalizado para usar el contexto
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth debe ser usado dentro de un AuthProvider');
  }
  return context;
};

// Provider del contexto
export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  // 🔍 Verificar autenticación al cargar la app
  useEffect(() => {
    checkAuthStatus();
  }, []);

  const checkAuthStatus = () => {
    try {
      const token = localStorage.getItem('adminToken');
      const userData = localStorage.getItem('adminUser');

      if (token && userData) {
        const parsedUser = JSON.parse(userData);
        
        // Verificar que sea admin
        if (parsedUser.role === 'admin') {
          setUser(parsedUser);
          setIsAuthenticated(true);
          console.log('✅ Usuario admin autenticado:', parsedUser.name);
        } else {
          console.log('❌ Usuario no es admin:', parsedUser.role);
          logout();
        }
      }
    } catch (error) {
      console.error('❌ Error verificando autenticación:', error);
      logout();
    } finally {
      setIsLoading(false);
    }
  };

  // 🔐 Función de login
  const login = async (credentials) => {
    try {
      setIsLoading(true);
      console.log('🔐 Intentando login admin...');

      const response = await adminAPI.login(credentials);
      
      if (response.token && response.user) {
        // Verificar que sea admin
        if (response.user.role !== 'admin') {
          throw new Error('Acceso denegado: Solo administradores pueden acceder');
        }

        // Guardar en localStorage
        localStorage.setItem('adminToken', response.token);
        localStorage.setItem('adminUser', JSON.stringify(response.user));

        // Actualizar estado
        setUser(response.user);
        setIsAuthenticated(true);

        console.log('✅ Login exitoso:', response.user.name);
        return { success: true };
      } else {
        throw new Error('Respuesta de login inválida');
      }
    } catch (error) {
      console.error('❌ Error en login:', error);
      return { 
        success: false, 
        error: error.message || 'Error de autenticación' 
      };
    } finally {
      setIsLoading(false);
    }
  };

  // 🚪 Función de logout
  const logout = () => {
    console.log('🚪 Cerrando sesión admin...');
    
    // Limpiar localStorage
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminUser');
    
    // Limpiar estado
    setUser(null);
    setIsAuthenticated(false);
    
    console.log('✅ Sesión cerrada');
  };

  // 🔄 Función para actualizar datos del usuario
  const updateUser = (userData) => {
    try {
      const updatedUser = { ...user, ...userData };
      setUser(updatedUser);
      localStorage.setItem('adminUser', JSON.stringify(updatedUser));
      console.log('✅ Usuario actualizado:', updatedUser.name);
    } catch (error) {
      console.error('❌ Error actualizando usuario:', error);
    }
  };

  // 🔍 Verificar si el usuario tiene permisos específicos
  const hasPermission = (permission) => {
    if (!isAuthenticated || !user) return false;
    
    // Por ahora, todos los admin tienen todos los permisos
    // Puedes expandir esto para roles más granulares
    return user.role === 'admin';
  };

  // Valor del contexto
  const value = {
    // Estado
    user,
    isAuthenticated,
    isLoading,
    
    // Funciones
    login,
    logout,
    updateUser,
    hasPermission,
    checkAuthStatus,
    
    // Datos del usuario
    userName: user?.name || '',
    userEmail: user?.email || '',
    userRole: user?.role || '',
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};