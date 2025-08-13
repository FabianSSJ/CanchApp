// src/pages/Users/Users.js - CRUD completo de usuarios
import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  IconButton,
  Chip,
  Alert,
  CircularProgress,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  InputAdornment,
  Grid,
  Card,
  CardContent,
  Avatar,
  Tooltip,
  Switch,
  FormControlLabel,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Person as PersonIcon,
  Business as BusinessIcon,
  AdminPanelSettings as AdminIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  Refresh as RefreshIcon,
  Visibility as ViewIcon,
  VisibilityOff as HideIcon,
  VisibilityOff, // 🆕 AGREGAR ESTA LÍNEA
} from '@mui/icons-material';
import { adminAPI } from '../../services/api';

const Users = () => {
  // Estados principales
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Estados para tabla
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');

  // Estados para modales
  const [openDialog, setOpenDialog] = useState(false);
  const [dialogMode, setDialogMode] = useState('create'); // 'create', 'edit', 'view'
  const [selectedUser, setSelectedUser] = useState(null);

  // Estados para formulario
  const [formData, setFormData] = useState({
    user_name: '',
    user_email: '',
    user_phone: '',
    user_role: 'jugador', // Cambiado para coincidir con tu DB
    user_hashed_password: '',
    user_state: true,
  });
  const [showPassword, setShowPassword] = useState(false);
  const [formErrors, setFormErrors] = useState({});

  // 🔄 Cargar usuarios al montar
  useEffect(() => {
    loadUsers();
  }, []);

  // 📊 Cargar usuarios desde la API
  const loadUsers = async () => {
    try {
      setLoading(true);
      setError('');

      const response = await adminAPI.getUsers({
        limit: 1000, // Cargar muchos usuarios
        role: roleFilter !== 'all' ? roleFilter : undefined,
      });

      setUsers(response.data || []);
      console.log('✅ Usuarios cargados:', response.data?.length || 0);

    } catch (err) {
      console.error('❌ Error cargando usuarios:', err);
      setError(`Error cargando usuarios: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  // 🔍 Filtrar usuarios
  const filteredUsers = users.filter(user => {
    const matchesSearch = user.user_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.user_email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.user_phone?.includes(searchTerm);
    
    const matchesRole = roleFilter === 'all' || user.user_role === roleFilter;
    
    return matchesSearch && matchesRole;
  });

  // 📄 Paginación
  const paginatedUsers = filteredUsers.slice(
    page * rowsPerPage,
    page * rowsPerPage + rowsPerPage
  );

  // 🎨 Obtener color del rol
  const getRoleColor = (role) => {
    switch (role) {
      case 'admin':
        return 'error';
      case 'dueno': // Tu DB usa 'dueno'
        return 'warning';
      case 'jugador': // Tu DB usa 'jugador'
        return 'primary';
      default:
        return 'default';
    }
  };

  // 🎨 Obtener texto del rol
  const getRoleText = (role) => {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'dueno': // Tu DB usa 'dueno'
        return 'Dueño';
      case 'jugador': // Tu DB usa 'jugador'
        return 'Jugador';
      default:
        return role;
    }
  };

  // 🎨 Obtener icono del rol
  const getRoleIcon = (role) => {
    switch (role) {
      case 'admin':
        return <AdminIcon />;
      case 'dueno': // Tu DB usa 'dueno'
        return <BusinessIcon />;
      case 'jugador': // Tu DB usa 'jugador'
        return <PersonIcon />;
      default:
        return <PersonIcon />;
    }
  };

  // ➕ Abrir modal para crear usuario
  const handleCreateUser = () => {
    setDialogMode('create');
    setSelectedUser(null);
    setFormData({
      user_name: '',
      user_email: '',
      user_phone: '',
      user_role: 'player',
      user_hashed_password: '',
      user_state: true,
    });
    setFormErrors({});
    setOpenDialog(true);
  };

  // ✏️ Abrir modal para editar usuario
  const handleEditUser = (user) => {
    setDialogMode('edit');
    setSelectedUser(user);
    setFormData({
      user_name: user.user_name || '',
      user_email: user.user_email || '',
      user_phone: user.user_phone || '',
      user_role: user.user_role || 'player',
      user_hashed_password: '', // No mostrar contraseña actual
      user_state: user.user_state !== false,
    });
    setFormErrors({});
    setOpenDialog(true);
  };

  // 👁️ Ver detalles del usuario
  const handleViewUser = (user) => {
    setDialogMode('view');
    setSelectedUser(user);
    setOpenDialog(true);
  };

  // 📝 Manejar cambios en el formulario
  const handleFormChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Limpiar error del campo si existe
    if (formErrors[field]) {
      setFormErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  // ✅ Validar formulario
  const validateForm = () => {
    const errors = {};

    if (!formData.user_name?.trim()) {
      errors.user_name = 'Nombre es requerido';
    }

    if (!formData.user_email?.trim()) {
      errors.user_email = 'Email es requerido';
    } else if (!/\S+@\S+\.\S+/.test(formData.user_email)) {
      errors.user_email = 'Email no válido';
    }

    if (!formData.user_phone?.trim()) {
      errors.user_phone = 'Teléfono es requerido';
    }

    if (dialogMode === 'create' && !formData.user_hashed_password?.trim()) {
      errors.user_hashed_password = 'Contraseña es requerida para nuevos usuarios';
    }

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  // 💾 Guardar usuario (crear o actualizar)
  const handleSaveUser = async () => {
    if (!validateForm()) {
      setError('Por favor corrige los errores en el formulario');
      return;
    }

    try {
      setLoading(true);
      setError('');

      if (dialogMode === 'create') {
        await adminAPI.createUser(formData);
        setSuccess('Usuario creado exitosamente');
      } else {
        // Para edición, no enviar contraseña si está vacía
        const updateData = { ...formData };
        if (!updateData.user_hashed_password.trim()) {
          delete updateData.user_hashed_password;
        }
        
        await adminAPI.updateUser(selectedUser.user_id, updateData);
        setSuccess('Usuario actualizado exitosamente');
      }

      setOpenDialog(false);
      await loadUsers(); // Recargar lista

    } catch (err) {
      console.error('❌ Error guardando usuario:', err);
      setError(`Error guardando usuario: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  // 🗑️ Eliminar usuario
  const handleDeleteUser = async (user) => {
    if (!window.confirm(`¿Estás seguro de eliminar al usuario "${user.user_name}"?`)) {
      return;
    }

    try {
      setLoading(true);
      setError('');

      await adminAPI.deleteUser(user.user_id);
      setSuccess('Usuario eliminado exitosamente');
      await loadUsers(); // Recargar lista

    } catch (err) {
      console.error('❌ Error eliminando usuario:', err);
      setError(`Error eliminando usuario: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h4" gutterBottom>
            Gestión de Usuarios
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Administra usuarios del sistema: administradores, dueños y jugadores
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleCreateUser}
          disabled={loading}
        >
          Nuevo Usuario
        </Button>
      </Box>

      {/* Alertas */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError('')}>
          {error}
        </Alert>
      )}
      {success && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess('')}>
          {success}
        </Alert>
      )}

      {/* Filtros y búsqueda */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={4}>
            <TextField
              fullWidth
              placeholder="Buscar usuarios..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon />
                  </InputAdornment>
                ),
              }}
            />
          </Grid>
          <Grid item xs={12} sm={4} md={3}>
            <FormControl fullWidth>
              <InputLabel>Rol</InputLabel>
              <Select
                value={roleFilter}
                onChange={(e) => setRoleFilter(e.target.value)}
                label="Rol"
              >
                <MenuItem value="all">Todos los roles</MenuItem>
                <MenuItem value="admin">Administradores</MenuItem>
                <MenuItem value="dueno">Dueños</MenuItem>
                <MenuItem value="jugador">Jugadores</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={2} md={2}>
            <Button
              fullWidth
              variant="outlined"
              startIcon={<RefreshIcon />}
              onClick={loadUsers}
              disabled={loading}
            >
              Actualizar
            </Button>
          </Grid>
        </Grid>
      </Paper>

      {/* Estadísticas rápidas */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <Avatar sx={{ bgcolor: 'primary.main', mx: 'auto', mb: 1 }}>
                <PersonIcon />
              </Avatar>
              <Typography variant="h6">
                {users.filter(u => u.user_role === 'jugador').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Jugadores
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <Avatar sx={{ bgcolor: 'warning.main', mx: 'auto', mb: 1 }}>
                <BusinessIcon />
              </Avatar>
              <Typography variant="h6">
                {users.filter(u => u.user_role === 'dueno').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Dueños
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <Avatar sx={{ bgcolor: 'error.main', mx: 'auto', mb: 1 }}>
                <AdminIcon />
              </Avatar>
              <Typography variant="h6">
                {users.filter(u => u.user_role === 'admin').length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Administradores
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <Avatar sx={{ bgcolor: 'success.main', mx: 'auto', mb: 1 }}>
                <PersonIcon />
              </Avatar>
              <Typography variant="h6">
                {users.length}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Total
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Tabla de usuarios */}
      <Paper>
        {loading ? (
          <Box display="flex" justifyContent="center" p={4}>
            <CircularProgress />
          </Box>
        ) : (
          <>
            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Usuario</TableCell>
                    <TableCell>Contacto</TableCell>
                    <TableCell>Rol</TableCell>
                    <TableCell>Estado</TableCell>
                    <TableCell align="center">Acciones</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {paginatedUsers.map((user) => (
                    <TableRow key={user.user_id}>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                          <Avatar sx={{ bgcolor: getRoleColor(user.user_role) + '.main' }}>
                            {getRoleIcon(user.user_role)}
                          </Avatar>
                          <Box>
                            <Typography variant="subtitle2" fontWeight="bold">
                              {user.user_name}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              ID: {user.user_id}
                            </Typography>
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Box>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                            <EmailIcon fontSize="small" color="action" />
                            <Typography variant="body2">{user.user_email}</Typography>
                          </Box>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <PhoneIcon fontSize="small" color="action" />
                            <Typography variant="body2">{user.user_phone}</Typography>
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={getRoleText(user.user_role)}
                          color={getRoleColor(user.user_role)}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={user.user_state !== false ? 'Activo' : 'Inactivo'}
                          color={user.user_state !== false ? 'success' : 'default'}
                          size="small"
                        />
                      </TableCell>
                      <TableCell align="center">
                        <Tooltip title="Ver detalles">
                          <IconButton onClick={() => handleViewUser(user)} size="small">
                            <ViewIcon />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Editar">
                          <IconButton onClick={() => handleEditUser(user)} size="small">
                            <EditIcon />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Eliminar">
                          <IconButton 
                            onClick={() => handleDeleteUser(user)} 
                            size="small"
                            color="error"
                          >
                            <DeleteIcon />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>

            <TablePagination
              component="div"
              count={filteredUsers.length}
              page={page}
              onPageChange={(e, newPage) => setPage(newPage)}
              rowsPerPage={rowsPerPage}
              onRowsPerPageChange={(e) => {
                setRowsPerPage(parseInt(e.target.value, 10));
                setPage(0);
              }}
              labelRowsPerPage="Filas por página:"
            />
          </>
        )}
      </Paper>

      {/* Modal para crear/editar/ver usuario */}
      <Dialog
        open={openDialog}
        onClose={() => setOpenDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          {dialogMode === 'create' && 'Crear Nuevo Usuario'}
          {dialogMode === 'edit' && 'Editar Usuario'}
          {dialogMode === 'view' && 'Detalles del Usuario'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Nombre completo"
                value={formData.user_name}
                onChange={(e) => handleFormChange('user_name', e.target.value)}
                disabled={dialogMode === 'view'}
                error={!!formErrors.user_name}
                helperText={formErrors.user_name}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={formData.user_email}
                onChange={(e) => handleFormChange('user_email', e.target.value)}
                disabled={dialogMode === 'view'}
                error={!!formErrors.user_email}
                helperText={formErrors.user_email}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Teléfono"
                value={formData.user_phone}
                onChange={(e) => handleFormChange('user_phone', e.target.value)}
                disabled={dialogMode === 'view'}
                error={!!formErrors.user_phone}
                helperText={formErrors.user_phone}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth disabled={dialogMode === 'view'}>
                <InputLabel>Rol</InputLabel>
                <Select
                  value={formData.user_role}
                  onChange={(e) => handleFormChange('user_role', e.target.value)}
                  label="Rol"
                >
                  <MenuItem value="jugador">Jugador</MenuItem>
                  <MenuItem value="dueno">Dueño</MenuItem>
                  <MenuItem value="admin">Administrador</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            {dialogMode !== 'view' && (
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label={dialogMode === 'create' ? 'Contraseña' : 'Nueva contraseña (opcional)'}
                  type={showPassword ? 'text' : 'password'}
                  value={formData.user_hashed_password}
                  onChange={(e) => handleFormChange('user_hashed_password', e.target.value)}
                  error={!!formErrors.user_hashed_password}
                  helperText={formErrors.user_hashed_password}
                  InputProps={{
                    endAdornment: (
                      <InputAdornment position="end">
                        <IconButton onClick={() => setShowPassword(!showPassword)}>
                          {showPassword ? <VisibilityOff /> : <ViewIcon />}
                        </IconButton>
                      </InputAdornment>
                    ),
                  }}
                />
              </Grid>
            )}
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.user_state}
                    onChange={(e) => handleFormChange('user_state', e.target.checked)}
                    disabled={dialogMode === 'view'}
                  />
                }
                label="Usuario activo"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>
            {dialogMode === 'view' ? 'Cerrar' : 'Cancelar'}
          </Button>
          {dialogMode !== 'view' && (
            <Button
              onClick={handleSaveUser}
              variant="contained"
              disabled={loading}
            >
              {loading ? <CircularProgress size={20} /> : 'Guardar'}
            </Button>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Users;