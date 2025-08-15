// src/pages/admin/BankAccounts.js
import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Button,
  Box,
  TextField,
  InputAdornment,
  Grid,
  Card,
  CardContent,
  Chip,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  Snackbar,
  Fab,
  Tabs,
  Tab,
  CircularProgress
} from '@mui/material';
import {
  Add as AddIcon,
  Search as SearchIcon,
  AccountBalance as BankIcon,
  Refresh as RefreshIcon,
  ViewList as ListIcon,
  ViewModule as GridIcon
} from '@mui/icons-material';

import {adminAPI} from '../../services/api';
import { filterAccountsBySearch, sortAccountsBy, BANKS } from '../../utils/bankUtils';
import BankAccountForm from '../../components/admin/BankAccountForm';
import BankAccountCard from '../../components/admin/BankAccountCard';
import BankAccountTable from '../../components/admin/BankAccountTable';

const BankAccounts = () => {
  // Estados principales
  const [accounts, setAccounts] = useState([]);
  const [filteredAccounts, setFilteredAccounts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({ total: 0, active: 0, inactive: 0 });
  
  // Estados de UI
  const [viewMode, setViewMode] = useState('grid'); // 'grid' | 'table'
  const [activeTab, setActiveTab] = useState(0); // 0: Todas, 1: Activas, 2: Inactivas
  const [searchText, setSearchText] = useState('');
  const [bankFilter, setBankFilter] = useState('');
  const [sortBy, setSortBy] = useState('bank');
  const [sortOrder, setSortOrder] = useState('asc');
  
  // Estados del formulario
  const [formOpen, setFormOpen] = useState(false);
  const [editingAccount, setEditingAccount] = useState(null);
  
  // Estados de notificaciones
  const [snackbar, setSnackbar] = useState({
    open: false,
    message: '',
    severity: 'success'
  });

  // Cargar datos al montar el componente
  useEffect(() => {
    loadBankAccounts();
    loadStats();
  }, []);

  // Filtrar cuentas cuando cambian los filtros
  useEffect(() => {
    applyFilters();
  }, [accounts, searchText, bankFilter, activeTab, sortBy, sortOrder]);

  /**
   * Cargar todas las cuentas bancarias
   */
  const loadBankAccounts = async () => {
    setLoading(true);
    try {
      const result = await adminAPI.getBankAccounts();
      if (result.success) {
        setAccounts(result.data || []);
      } else {
        showSnackbar('Error cargando cuentas bancarias', 'error');
      }
    } catch (error) {
      console.error('Error:', error);
      showSnackbar('Error de conexión', 'error');
    } finally {
      setLoading(false);
    }
  };

  /**
   * Cargar estadísticas
   */
  const loadStats = async () => {
    try {
      const result = await adminAPI.getBankAccountsStats();
      if (result.success) {
        setStats(result.data);
      }
    } catch (error) {
      console.error('Error cargando estadísticas:', error);
    }
  };

  /**
   * Aplicar filtros y ordenamiento
   */
  const applyFilters = () => {
    let filtered = [...accounts];

    // Filtro por estado (tab activo)
    if (activeTab === 1) {
      filtered = filtered.filter(account => !account.b_account_delete);
    } else if (activeTab === 2) {
      filtered = filtered.filter(account => account.b_account_delete);
    }

    // Filtro por banco
    if (bankFilter) {
      filtered = filtered.filter(account => account.b_account_bank === bankFilter);
    }

    // Filtro por texto de búsqueda
    if (searchText) {
      filtered = filterAccountsBySearch(filtered, searchText);
    }

    // Ordenamiento
    filtered = sortAccountsBy(filtered, sortBy, sortOrder);

    setFilteredAccounts(filtered);
  };

  /**
   * Mostrar notificación
   */
  const showSnackbar = (message, severity = 'success') => {
    setSnackbar({
      open: true,
      message,
      severity
    });
  };

  /**
   * Cerrar notificación
   */
  const handleCloseSnackbar = () => {
    setSnackbar(prev => ({ ...prev, open: false }));
  };

  /**
   * Abrir formulario para nueva cuenta
   */
  const handleAddAccount = () => {
    setEditingAccount(null);
    setFormOpen(true);
  };

  /**
   * Abrir formulario para editar cuenta
   */
  const handleEditAccount = (account) => {
    setEditingAccount(account);
    setFormOpen(true);
  };

  /**
   * Cerrar formulario
   */
  const handleCloseForm = () => {
    setFormOpen(false);
    setEditingAccount(null);
  };

  /**
   * Manejar éxito en operaciones CRUD
   */
  const handleOperationSuccess = (message) => {
    showSnackbar(message, 'success');
    loadBankAccounts();
    loadStats();
    handleCloseForm();
  };

  /**
   * Manejar errores en operaciones
   */
  const handleOperationError = (message) => {
    showSnackbar(message, 'error');
  };

  /**
   * Cambiar modo de vista
   */
  const handleViewModeChange = (mode) => {
    setViewMode(mode);
  };

  /**
   * Cambiar tab activo
   */
  const handleTabChange = (event, newValue) => {
    setActiveTab(newValue);
  };

  /**
   * Limpiar todos los filtros
   */
  const clearFilters = () => {
    setSearchText('');
    setBankFilter('');
    setActiveTab(0);
    setSortBy('bank');
    setSortOrder('asc');
  };

  return (
    <Container maxWidth="xl" sx={{ py: 4 }}>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={4}>
        <Box>
          <Typography variant="h4" component="h1" gutterBottom>
            <BankIcon sx={{ mr: 2, verticalAlign: 'middle' }} />
            Cuentas Bancarias
          </Typography>
          <Typography variant="subtitle1" color="text.secondary">
            Gestiona las cuentas bancarias para recibir pagos
          </Typography>
        </Box>
        
        <Box display="flex" gap={2}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={() => {
              loadBankAccounts();
              loadStats();
            }}
            disabled={loading}
          >
            Actualizar
          </Button>
          
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={handleAddAccount}
            sx={{ minWidth: 180 }}
          >
            Nueva Cuenta
          </Button>
        </Box>
      </Box>

      {/* Estadísticas */}
      <Grid container spacing={3} mb={4}>
        <Grid item xs={12} sm={4}>
          <Card>
            <CardContent>
              <Typography color="text.secondary" gutterBottom>
                Total de Cuentas
              </Typography>
              <Typography variant="h4" component="div">
                {stats.total || accounts.length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={4}>
          <Card sx={{ bgcolor: 'success.light', color: 'success.contrastText' }}>
            <CardContent>
              <Typography gutterBottom>
                Cuentas Activas
              </Typography>
              <Typography variant="h4" component="div">
                {stats.active || accounts.filter(a => !a.b_account_delete).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={4}>
          <Card sx={{ bgcolor: 'error.light', color: 'error.contrastText' }}>
            <CardContent>
              <Typography gutterBottom>
                Cuentas Inactivas
              </Typography>
              <Typography variant="h4" component="div">
                {stats.inactive || accounts.filter(a => a.b_account_delete).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Filtros y controles */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={3} alignItems="center">
            {/* Búsqueda */}
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                placeholder="Buscar por banco, número, titular..."
                value={searchText}
                onChange={(e) => setSearchText(e.target.value)}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchIcon />
                    </InputAdornment>
                  ),
                }}
              />
            </Grid>

            {/* Filtro por banco */}
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Filtrar por banco</InputLabel>
                <Select
                  value={bankFilter}
                  label="Filtrar por banco"
                  onChange={(e) => setBankFilter(e.target.value)}
                >
                  <MenuItem value="">Todos los bancos</MenuItem>
                  {BANKS.map((bank) => (
                    <MenuItem key={bank.value} value={bank.value}>
                      {bank.icon} {bank.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            {/* Ordenamiento */}
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Ordenar por</InputLabel>
                <Select
                  value={`${sortBy}-${sortOrder}`}
                  label="Ordenar por"
                  onChange={(e) => {
                    const [field, order] = e.target.value.split('-');
                    setSortBy(field);
                    setSortOrder(order);
                  }}
                >
                  <MenuItem value="bank-asc">Banco (A-Z)</MenuItem>
                  <MenuItem value="bank-desc">Banco (Z-A)</MenuItem>
                  <MenuItem value="number-asc">Número (menor)</MenuItem>
                  <MenuItem value="number-desc">Número (mayor)</MenuItem>
                  <MenuItem value="owner-asc">Titular (A-Z)</MenuItem>
                  <MenuItem value="owner-desc">Titular (Z-A)</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            {/* Modo de vista */}
            <Grid item xs={12} md={2}>
              <Box display="flex" justifyContent="center">
                <Button
                  variant={viewMode === 'grid' ? 'contained' : 'outlined'}
                  onClick={() => handleViewModeChange('grid')}
                  sx={{ mr: 1 }}
                >
                  <GridIcon />
                </Button>
                <Button
                  variant={viewMode === 'table' ? 'contained' : 'outlined'}
                  onClick={() => handleViewModeChange('table')}
                >
                  <ListIcon />
                </Button>
              </Box>
            </Grid>
          </Grid>

          {/* Botón limpiar filtros */}
          {(searchText || bankFilter || activeTab !== 0) && (
            <Box mt={2}>
              <Button variant="text" onClick={clearFilters}>
                Limpiar filtros
              </Button>
            </Box>
          )}
        </CardContent>
      </Card>

      {/* Tabs de estado */}
      <Box mb={3}>
        <Tabs value={activeTab} onChange={handleTabChange}>
          <Tab 
            label={`Todas (${accounts.length})`}
            icon={<Chip label={accounts.length} size="small" />}
          />
          <Tab 
            label={`Activas (${accounts.filter(a => !a.b_account_delete).length})`}
            icon={<Chip label={accounts.filter(a => !a.b_account_delete).length} size="small" color="success" />}
          />
          <Tab 
            label={`Inactivas (${accounts.filter(a => a.b_account_delete).length})`}
            icon={<Chip label={accounts.filter(a => a.b_account_delete).length} size="small" color="error" />}
          />
        </Tabs>
      </Box>

      {/* Contenido principal */}
      {loading ? (
        <Box display="flex" justifyContent="center" py={8}>
          <CircularProgress />
        </Box>
      ) : filteredAccounts.length === 0 ? (
        <Alert severity="info" sx={{ mt: 2 }}>
          {accounts.length === 0 
            ? 'No hay cuentas bancarias registradas. ¡Crea la primera!'
            : 'No se encontraron cuentas con los filtros aplicados.'
          }
        </Alert>
      ) : viewMode === 'grid' ? (
        <Grid container spacing={3}>
          {filteredAccounts.map((account) => (
            <Grid item xs={12} sm={6} lg={4} key={account.b_account_id}>
              <BankAccountCard
                account={account}
                onEdit={handleEditAccount}
                onSuccess={handleOperationSuccess}
                onError={handleOperationError}
              />
            </Grid>
          ))}
        </Grid>
      ) : (
        <BankAccountTable
          accounts={filteredAccounts}
          onEdit={handleEditAccount}
          onSuccess={handleOperationSuccess}
          onError={handleOperationError}
        />
      )}

      {/* Botón flotante para agregar (solo en móvil) */}
      <Fab
        color="primary"
        aria-label="add"
        onClick={handleAddAccount}
        sx={{
          position: 'fixed',
          bottom: 16,
          right: 16,
          display: { xs: 'flex', md: 'none' }
        }}
      >
        <AddIcon />
      </Fab>

      {/* Formulario de cuenta bancaria */}
      <BankAccountForm
        open={formOpen}
        account={editingAccount}
        onClose={handleCloseForm}
        onSuccess={handleOperationSuccess}
        onError={handleOperationError}
      />

      {/* Snackbar para notificaciones */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={handleCloseSnackbar}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
      >
        <Alert 
          onClose={handleCloseSnackbar} 
          severity={snackbar.severity}
          sx={{ width: '100%' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Container>
  );
};

export default BankAccounts;