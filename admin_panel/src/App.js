// src/App.js - Aplicación principal del admin panel
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';
import { AuthProvider } from './context/AuthContext';

// Componentes
import Layout from './components/Layout/Layout';
import ProtectedRoute from './components/ProtectedRoute/ProtectedRoute';

// Páginas
import Login from './pages/Login/Login';

// 📄 Páginas temporales (las crearemos después)
import Dashboard from './pages/Dashboard/Dashboard';
import Payments from './pages/Payments/Payments';
import Users from './pages/Users/Users';
import Fields from './pages/Fields/Fields';
import Companies from './pages/Companies/Companies';
import Bookings from './pages/Bookings/Bookings';
import BankAccounts from './pages/admin/BankAccounts';

// 🎨 Tema personalizado de Material-UI
const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
      light: '#42a5f5',
      dark: '#1565c0',
    },
    secondary: {
      main: '#ed6c02',
      light: '#ff9800',
      dark: '#e65100',
    },
    background: {
      default: '#f5f5f5',
      paper: '#ffffff',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
    h4: {
      fontWeight: 600,
    },
    h5: {
      fontWeight: 600,
    },
    h6: {
      fontWeight: 600,
    },
  },
  shape: {
    borderRadius: 8,
  },
  components: {
    // Customizar componentes globalmente
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          borderRadius: 8,
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 12,
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          boxShadow: '0 2px 10px rgba(0,0,0,0.1)',
        },
      },
    },
  },
});

// 📄 Componente temporal para páginas que no hemos creado
const TemporaryPage = ({ title }) => (
  <div style={{ padding: '20px', textAlign: 'center' }}>
    <h2>{title}</h2>
    <p>Esta página se creará en los próximos pasos.</p>
    <p style={{ color: '#666' }}>
      Panel de administración de CanchApp en desarrollo...
    </p>
  </div>
);

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <Router>
          <Routes>
            {/* 🔐 Ruta de login (pública) */}
            <Route path="/login" element={<Login />} />
            
            {/* 🏠 Ruta raíz - redirigir al dashboard */}
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            
            {/* 🔒 Rutas protegidas con Layout */}
            <Route path="/dashboard" element={
              <ProtectedRoute>
                <Layout>
                  <Dashboard />
                </Layout>
              </ProtectedRoute>
            } />
            
            <Route path="/payments" element={
              <ProtectedRoute>
                <Layout>
                  <Payments />
                </Layout>
              </ProtectedRoute>
            } />
            
            <Route path="/users" element={
              <ProtectedRoute>
                <Layout>
                  <Users />
                </Layout>
              </ProtectedRoute>
            } />
            
            <Route path="/fields" element={
              <ProtectedRoute>
                <Layout>
                  <Fields />
                </Layout>
              </ProtectedRoute>
            } />
            
            <Route path="/companies" element={
              <ProtectedRoute>
                <Layout>
                  <Companies />
                </Layout>
              </ProtectedRoute>
            } />

            <Route path="/bookings" element={
              <ProtectedRoute>
                <Layout>
                  <Bookings />
                </Layout>
              </ProtectedRoute>
            } />

            {/* 🆕 NUEVA RUTA: Cuentas Bancarias */}
            <Route path="/bank-accounts" element={
              <ProtectedRoute>
                <Layout>
                  <BankAccounts />
                </Layout>
              </ProtectedRoute>
            } />
            
            {/* 🚫 Ruta para páginas no encontradas */}
            <Route path="*" element={
              <ProtectedRoute>
                <Layout>
                  <TemporaryPage title="Página no encontrada" />
                </Layout>
              </ProtectedRoute>
            } />
          </Routes>
        </Router>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;