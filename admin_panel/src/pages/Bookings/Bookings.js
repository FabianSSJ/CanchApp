// src/pages/Bookings/Bookings.js - Gestión completa de reservas
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
  Divider,
  Tab,
  Tabs,
  Badge,
  Menu, // 🆕 AGREGADO
} from '@mui/material';
import {
  CalendarToday as BookingIcon,
  Edit as EditIcon,
  Visibility as ViewIcon,
  Search as SearchIcon,
  Person as PersonIcon,
  SportsFootball as FieldIcon,
  Business as CompanyIcon,
  AccessTime as TimeIcon,
  AttachMoney as MoneyIcon,
  Refresh as RefreshIcon,
  CheckCircle as ConfirmIcon,
  Cancel as RejectIcon,
  Pending as PendingIcon,
  Block as BlockIcon,
  EventAvailable as AvailableIcon,
  Cancel, // 🆕 AGREGAR ESTA LÍNEA
  CheckCircle, // 🆕 AGREGAR ESTA LÍNEA
  KeyboardArrowDown as KeyboardArrowDownIcon, // 🆕 AGREGADO
} from '@mui/icons-material';
import { adminAPI } from '../../services/api';

const Bookings = () => {
  // Estados principales
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Estados para filtros
  const [activeTab, setActiveTab] = useState(0);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [dateFilter, setDateFilter] = useState('all');

  // Estados para modales
  const [selectedBooking, setSelectedBooking] = useState(null);
  const [viewModalOpen, setViewModalOpen] = useState(false);
  const [statusModalOpen, setStatusModalOpen] = useState(false);
  const [newStatus, setNewStatus] = useState('');
  const [rejectionReason, setRejectionReason] = useState('');

  // 🔄 Cargar reservas al montar
  useEffect(() => {
    loadBookings();
  }, []);

  // 📊 Cargar reservas desde la API
  const loadBookings = async () => {
    try {
      setLoading(true);
      setError('');

      // Usar el endpoint de reservas que ya tienes
      const response = await adminAPI.getAllBookings({
        limit: 1000,
        status: statusFilter !== 'all' ? statusFilter : undefined,
      });

      setBookings(response.data || []);
      console.log('✅ Reservas cargadas:', response.data?.length || 0);

    } catch (err) {
      console.error('❌ Error cargando reservas:', err);
      setError(`Error cargando reservas: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  // 🎨 Obtener color del estado
  const getStatusColor = (status) => {
    switch (status) {
      case 'Disponible':
        return 'success';
      case 'Reservada':
        return 'primary';
      case 'Pendiente':
        return 'warning';
      case 'Confirmada':
        return 'info';
      case 'Rechazada':
        return 'error';
      case 'Cancelada':
        return 'default';
      case 'No Disponible':
        return 'error';
      case 'Completada':
        return 'success';
      default:
        return 'default';
    }
  };

  // 🎨 Obtener icono del estado
  const getStatusIcon = (status) => {
    switch (status) {
      case 'Disponible':
        return <AvailableIcon />;
      case 'Reservada':
        return <BookingIcon />;
      case 'Pendiente':
        return <PendingIcon />;
      case 'Confirmada':
        return <ConfirmIcon />;
      case 'Rechazada':
        return <RejectIcon />;
      case 'Cancelada':
        return <Cancel />;
      case 'No Disponible':
        return <BlockIcon />;
      case 'Completada':
        return <CheckCircle />;
      default:
        return <BookingIcon />;
    }
  };

  // 🔍 Filtrar reservas
  const filteredBookings = bookings.filter(booking => {
    const matchesSearch = 
      booking.user_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      booking.field_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      booking.company_name?.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = statusFilter === 'all' || booking.calendar_state === statusFilter;
    
    // Filtro por fecha
    let matchesDate = true;
    if (dateFilter === 'today') {
      const today = new Date().toISOString().split('T')[0];
      matchesDate = booking.calendar_date === today;
    } else if (dateFilter === 'upcoming') {
      const today = new Date().toISOString().split('T')[0];
      matchesDate = booking.calendar_date >= today;
    }
    
    return matchesSearch && matchesStatus && matchesDate;
  });

  // 📄 Filtrar por tabs
  const getBookingsByTab = (tabIndex) => {
    switch (tabIndex) {
      case 0: // Todas
        return filteredBookings;
      case 1: // Pendientes
        return filteredBookings.filter(b => b.calendar_state === 'Pendiente');
      case 2: // Hoy
        const today = new Date().toISOString().split('T')[0];
        return filteredBookings.filter(b => b.calendar_date === today);
      case 3: // Próximas
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        return filteredBookings.filter(b => b.calendar_date >= tomorrow.toISOString().split('T')[0]);
      default:
        return filteredBookings;
    }
  };

  const displayedBookings = getBookingsByTab(activeTab);
  const paginatedBookings = displayedBookings.slice(
    page * rowsPerPage,
    page * rowsPerPage + rowsPerPage
  );

  // 👁️ Ver detalles de la reserva
  const handleViewBooking = (booking) => {
    setSelectedBooking(booking);
    setViewModalOpen(true);
  };

  // 🔄 Cambiar estado de reserva - MODIFICADO para manejar cambios rápidos
  const handleChangeStatus = (booking, status) => {
    setSelectedBooking(booking);
    setNewStatus(status);
    setRejectionReason('');

    // Si es Confirmada, aprobar directamente
    if (status === 'Confirmada') {
      handleQuickStatusChange(booking, status);
    }
    // Si es Rechazada, abrir modal para motivo
    else if (status === 'Rechazada') {
      setStatusModalOpen(true);
    }
    // Otros estados, aprobar directamente
    else if (status) {
      handleQuickStatusChange(booking, status);
    }
    // Si no hay status, abrir modal de selección
    else {
      setStatusModalOpen(true);
    }
  };

  // 🆕 NUEVA FUNCIÓN para cambios rápidos (sin modal)
  const handleQuickStatusChange = async (booking, status) => {
    try {
      setLoading(true);
      setError('');

      await adminAPI.updateBookingStatus({
        calendar_id: booking.calendar_id,
        calendar_state: status,
      });

      setSuccess(`Reserva marcada como ${status}`);
      await loadBookings(); // Recargar

    } catch (err) {
      console.error('❌ Error actualizando estado:', err);
      setError(`Error actualizando estado: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  // 💾 Guardar cambio de estado
  const handleSaveStatusChange = async () => {
    if (!selectedBooking || !newStatus) return;

    try {
      setLoading(true);
      setError('');

      // Si es rechazo, necesita motivo
      if (newStatus === 'Rechazada' && !rejectionReason.trim()) {
        setError('El motivo del rechazo es requerido');
        return;
      }

      await adminAPI.updateBookingStatus({
        calendar_id: selectedBooking.calendar_id,
        calendar_state: newStatus,
        rejection_reason: newStatus === 'Rechazada' ? rejectionReason : null,
      });

      setSuccess(`Reserva marcada como ${newStatus}`);
      setStatusModalOpen(false);
      await loadBookings(); // Recargar

    } catch (err) {
      console.error('❌ Error actualizando estado:', err);
      setError(`Error actualizando estado: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  // 📊 Contar reservas por estado
  const getStatusCounts = () => {
    return {
      all: bookings.length,
      pendientes: bookings.filter(b => b.calendar_state === 'Pendiente').length,
      today: bookings.filter(b => b.calendar_date === new Date().toISOString().split('T')[0]).length,
      upcoming: bookings.filter(b => b.calendar_date >= new Date().toISOString().split('T')[0]).length,
    };
  };

  const statusCounts = getStatusCounts();

  // 🆕 COMPONENTE StatusDropdown
  const StatusDropdown = ({ booking, onStatusChange }) => {
    const [anchorEl, setAnchorEl] = useState(null);
    const open = Boolean(anchorEl);

    const handleClick = (event) => {
      setAnchorEl(event.currentTarget);
    };

    const handleClose = () => {
      setAnchorEl(null);
    };

    const handleStatusSelect = (newStatus) => {
      onStatusChange(booking, newStatus);
      handleClose();
    };

    // Estados disponibles según el estado actual
    const getAvailableStates = (currentState) => {
      switch (currentState) {
        case 'Pendiente':
          return [
            { value: 'Confirmada', label: 'Confirmar', color: 'success', icon: '✅' },
            { value: 'Rechazada', label: 'Rechazar', color: 'error', icon: '❌' },
            { value: 'Cancelada', label: 'Cancelar', color: 'default', icon: '🚫' },
          ];
        case 'Confirmada':
          return [
            { value: 'Completada', label: 'Marcar Completada', color: 'success', icon: '✅' },
            { value: 'Cancelada', label: 'Cancelar', color: 'default', icon: '🚫' },
          ];
        case 'Reservada':
          return [
            { value: 'Confirmada', label: 'Confirmar', color: 'success', icon: '✅' },
            { value: 'Cancelada', label: 'Cancelar', color: 'default', icon: '🚫' },
          ];
        default:
          return [];
      }
    };

    const availableStates = getAvailableStates(booking.calendar_state);

    return (
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        <Chip
          icon={getStatusIcon(booking.calendar_state)}
          label={booking.calendar_state}
          color={getStatusColor(booking.calendar_state)}
          size="small"
          onClick={availableStates.length > 0 ? handleClick : undefined}
          sx={{ 
            cursor: availableStates.length > 0 ? 'pointer' : 'default',
            '&:hover': availableStates.length > 0 ? {
              boxShadow: 2,
              transform: 'scale(1.05)',
            } : {},
            transition: 'all 0.2s ease-in-out'
          }}
        />
        
        {availableStates.length > 0 && (
          <IconButton 
            size="small" 
            onClick={handleClick}
            sx={{ 
              ml: 0.5,
              '&:hover': { 
                backgroundColor: 'action.hover',
                transform: 'rotate(180deg)',
              },
              transition: 'transform 0.2s ease-in-out'
            }}
          >
            <KeyboardArrowDownIcon fontSize="small" />
          </IconButton>
        )}

        <Menu
          anchorEl={anchorEl}
          open={open}
          onClose={handleClose}
          PaperProps={{
            sx: {
              mt: 1,
              boxShadow: 3,
              borderRadius: 2,
              minWidth: 180,
            }
          }}
          transformOrigin={{ horizontal: 'center', vertical: 'top' }}
          anchorOrigin={{ horizontal: 'center', vertical: 'bottom' }}
        >
          <Box sx={{ p: 1 }}>
            <Typography variant="caption" color="text.secondary" sx={{ px: 1, pb: 1, display: 'block' }}>
              Cambiar estado a:
            </Typography>
            {availableStates.map((state) => (
              <MenuItem
                key={state.value}
                onClick={() => handleStatusSelect(state.value)}
                sx={{
                  borderRadius: 1,
                  mb: 0.5,
                  '&:hover': {
                    backgroundColor: `${state.color}.light`,
                    color: `${state.color}.contrastText`,
                  },
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, width: '100%' }}>
                  <Typography component="span" sx={{ fontSize: '1.1em' }}>
                    {state.icon}
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {state.label}
                  </Typography>
                  <Chip
                    label={state.value}
                    color={state.color}
                    size="small"
                    sx={{ ml: 'auto', fontSize: '0.7em', height: 20 }}
                  />
                </Box>
              </MenuItem>
            ))}
          </Box>
        </Menu>
      </Box>
    );
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h4" gutterBottom>
            Gestión de Reservas
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Administra todas las reservas del sistema
          </Typography>
        </Box>
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={loadBookings}
          disabled={loading}
        >
          Actualizar
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

      {/* Tabs de filtrado rápido */}
      <Paper sx={{ mb: 3 }}>
        <Tabs value={activeTab} onChange={(e, v) => setActiveTab(v)}>
          <Tab label={`Todas (${statusCounts.all})`} />
          <Tab label={
            <Badge badgeContent={statusCounts.pendientes} color="error">
              Pendientes
            </Badge>
          } />
          <Tab label={`Hoy (${statusCounts.today})`} />
          <Tab label={`Próximas (${statusCounts.upcoming})`} />
        </Tabs>
      </Paper>

      {/* Filtros avanzados */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={4}>
            <TextField
              fullWidth
              placeholder="Buscar reservas..."
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
          <Grid item xs={12} sm={4}>
            <FormControl fullWidth>
              <InputLabel>Estado</InputLabel>
              <Select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                label="Estado"
              >
                <MenuItem value="all">Todos los estados</MenuItem>
                <MenuItem value="Reservada">Reservada</MenuItem>
                <MenuItem value="Pendiente">Pendiente</MenuItem>
                <MenuItem value="Confirmada">Confirmada</MenuItem>
                <MenuItem value="Rechazada">Rechazada</MenuItem>
                <MenuItem value="Cancelada">Cancelada</MenuItem>
                <MenuItem value="Completada">Completada</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} sm={4}>
            <FormControl fullWidth>
              <InputLabel>Fecha</InputLabel>
              <Select
                value={dateFilter}
                onChange={(e) => setDateFilter(e.target.value)}
                label="Fecha"
              >
                <MenuItem value="all">Todas las fechas</MenuItem>
                <MenuItem value="today">Solo hoy</MenuItem>
                <MenuItem value="upcoming">Próximas</MenuItem>
              </Select>
            </FormControl>
          </Grid>
        </Grid>
      </Paper>

      {/* Estadísticas rápidas */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {[
          { label: 'Pendientes', count: bookings.filter(b => b.calendar_state === 'Pendiente').length, color: 'warning.main', icon: <PendingIcon /> },
          { label: 'Confirmadas', count: bookings.filter(b => b.calendar_state === 'Confirmada').length, color: 'info.main', icon: <ConfirmIcon /> },
          { label: 'Rechazadas', count: bookings.filter(b => b.calendar_state === 'Rechazada').length, color: 'error.main', icon: <RejectIcon /> },
          { label: 'Total', count: bookings.length, color: 'primary.main', icon: <BookingIcon /> },
        ].map((stat, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card>
              <CardContent sx={{ textAlign: 'center' }}>
                <Avatar sx={{ bgcolor: stat.color, mx: 'auto', mb: 1 }}>
                  {stat.icon}
                </Avatar>
                <Typography variant="h6">{stat.count}</Typography>
                <Typography variant="body2" color="text.secondary">
                  {stat.label}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Tabla de reservas */}
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
                    <TableCell>Cancha</TableCell>
                    <TableCell>Fecha & Hora</TableCell>
                    <TableCell>Estado</TableCell>
                    <TableCell>Pago</TableCell>
                    <TableCell align="center">Acciones</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {paginatedBookings.map((booking) => (
                    <TableRow key={booking.calendar_id}>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                          <Avatar sx={{ bgcolor: 'primary.main' }}>
                            <PersonIcon />
                          </Avatar>
                          <Box>
                            <Typography variant="subtitle2" fontWeight="bold">
                              {booking.user_name}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {booking.user_email}
                            </Typography>
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Box>
                          <Typography variant="subtitle2" fontWeight="bold">
                            {booking.field_name}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {booking.company_name}
                          </Typography>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Box>
                          <Typography variant="body2" fontWeight="bold">
                            {new Date(booking.calendar_date).toLocaleDateString()}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {booking.calendar_init_time} - {booking.calendar_end_time}
                          </Typography>
                        </Box>
                      </TableCell>
                      <TableCell>
                        {/* 🆕 REEMPLAZADO: Usar StatusDropdown en lugar del Chip simple */}
                        <StatusDropdown 
                          booking={booking} 
                          onStatusChange={handleChangeStatus} 
                        />
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                          <MoneyIcon fontSize="small" color="action" />
                          <Typography variant="body2">
                            ${booking.field_hour_price || 'N/A'}
                          </Typography>
                        </Box>
                        {booking.calendar_payment_receipt && (
                          <Typography variant="caption" color="success.main">
                            ✓ Comprobante subido
                          </Typography>
                        )}
                      </TableCell>
                      <TableCell align="center">
                        <Tooltip title="Ver detalles">
                          <IconButton onClick={() => handleViewBooking(booking)} size="small">
                            <ViewIcon />
                          </IconButton>
                        </Tooltip>
                        
                        <Tooltip title="Editar estado">
                          <IconButton onClick={() => handleChangeStatus(booking, '')} size="small">
                            <EditIcon />
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
              count={displayedBookings.length}
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

      {/* Modal para ver detalles */}
      <Dialog
        open={viewModalOpen}
        onClose={() => setViewModalOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Detalles de la Reserva</DialogTitle>
        <DialogContent>
          {selectedBooking && (
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2" gutterBottom>
                  Usuario
                </Typography>
                <Typography variant="body2" sx={{ mb: 2 }}>
                  {selectedBooking.user_name} ({selectedBooking.user_email})
                </Typography>

                <Typography variant="subtitle2" gutterBottom>
                  Cancha
                </Typography>
                <Typography variant="body2" sx={{ mb: 2 }}>
                  {selectedBooking.field_name} - {selectedBooking.company_name}
                </Typography>

                <Typography variant="subtitle2" gutterBottom>
                  Fecha y Hora
                </Typography>
                <Typography variant="body2" sx={{ mb: 2 }}>
                  {new Date(selectedBooking.calendar_date).toLocaleDateString()} de {selectedBooking.calendar_init_time} a {selectedBooking.calendar_end_time}
                </Typography>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography variant="subtitle2" gutterBottom>
                  Estado
                </Typography>
                <Chip
                  label={selectedBooking.calendar_state}
                  color={getStatusColor(selectedBooking.calendar_state)}
                  sx={{ mb: 2 }}
                />

                <Typography variant="subtitle2" gutterBottom>
                  Precio
                </Typography>
                <Typography variant="body2" sx={{ mb: 2 }}>
                  ${selectedBooking.field_hour_price || 'No definido'}
                </Typography>

                {selectedBooking.calendar_payment_receipt && (
                  <>
                    <Typography variant="subtitle2" gutterBottom>
                      Comprobante de Pago
                    </Typography>
                    <img
                      src={`http://localhost:3000${selectedBooking.calendar_payment_receipt}`}
                      alt="Comprobante"
                      style={{ maxWidth: '100%', maxHeight: '200px', objectFit: 'contain' }}
                    />
                  </>
                )}
              </Grid>
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setViewModalOpen(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* Modal para cambiar estado */}
      <Dialog
        open={statusModalOpen}
        onClose={() => setStatusModalOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Cambiar Estado de Reserva</DialogTitle>
        <DialogContent>
          <FormControl fullWidth sx={{ mt: 2, mb: 2 }}>
            <InputLabel>Nuevo Estado</InputLabel>
            <Select
              value={newStatus}
              onChange={(e) => setNewStatus(e.target.value)}
              label="Nuevo Estado"
            >
              <MenuItem value="Pendiente">Pendiente</MenuItem>
              <MenuItem value="Confirmada">Confirmada</MenuItem>
              <MenuItem value="Rechazada">Rechazada</MenuItem>
              <MenuItem value="Cancelada">Cancelada</MenuItem>
              <MenuItem value="Completada">Completada</MenuItem>
              <MenuItem value="No Disponible">No Disponible</MenuItem>
            </Select>
          </FormControl>

          {newStatus === 'Rechazada' && (
            <TextField
              fullWidth
              label="Motivo del rechazo *"
              multiline
              rows={3}
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              required
            />
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setStatusModalOpen(false)}>Cancelar</Button>
          <Button
            onClick={handleSaveStatusChange}
            variant="contained"
            disabled={loading || (newStatus === 'Rechazada' && !rejectionReason.trim())}
          >
            {loading ? <CircularProgress size={20} /> : 'Guardar'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Bookings;