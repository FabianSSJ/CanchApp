// src/pages/Payments/Payments.js - Gestión completa de pagos
import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Tab,
  Tabs,
  Badge,
  Alert,
  CircularProgress,
  Grid,
  Card,
  CardContent,
  CardActions,
  Button,
  Chip,
  Avatar,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  IconButton,
  Tooltip,
  Divider,
} from '@mui/material';
import {
  Payment as PaymentIcon,
  CheckCircle as ApproveIcon,
  Cancel as RejectIcon,
  Visibility as ViewIcon,
  Person as PersonIcon,
  SportsFootball as FieldIcon,
  Business as CompanyIcon,
  AccessTime as TimeIcon,
  CalendarToday as DateIcon,
  AttachMoney as MoneyIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import { adminAPI } from '../../services/api';
import { useAuth } from '../../context/AuthContext';

const Payments = () => {
  const { user } = useAuth();
  
  // Estados
  const [activeTab, setActiveTab] = useState(0);
  const [pendingPayments, setPendingPayments] = useState([]);
  const [paymentHistory, setPaymentHistory] = useState([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Estados para modales
  const [selectedPayment, setSelectedPayment] = useState(null);
  const [viewModalOpen, setViewModalOpen] = useState(false);
  const [approveModalOpen, setApproveModalOpen] = useState(false);
  const [rejectModalOpen, setRejectModalOpen] = useState(false);

  // Estados para formularios
  const [approvalData, setApprovalData] = useState({
    payment_amount: '',
    notes: '',
  });
  const [rejectionData, setRejectionData] = useState({
    rejection_reason: '',
  });

  // 🔄 Cargar datos al montar el componente
  useEffect(() => {
    loadData();
  }, []);

  // 📊 Función para cargar todos los datos
  const loadData = async () => {
    try {
      setLoading(true);
      setError('');

      // Cargar pagos pendientes y historial en paralelo
      const [pendingResponse, historyResponse] = await Promise.all([
        adminAPI.getPendingPayments(),
        adminAPI.getPaymentHistory({ limit: 50 }),
      ]);

      setPendingPayments(pendingResponse.data || []);
      setPaymentHistory(historyResponse.data || []);

      console.log('✅ Datos cargados:', {
        pendientes: pendingResponse.data?.length || 0,
        historial: historyResponse.data?.length || 0,
      });

    } catch (err) {
      console.error('❌ Error cargando datos:', err);
      setError(`Error cargando datos: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  // 📋 Cambiar tab
  const handleTabChange = (event, newValue) => {
    setActiveTab(newValue);
  };

  // 👁️ Ver comprobante
  const handleViewPayment = (payment) => {
    setSelectedPayment(payment);
    setViewModalOpen(true);
  };

  // ✅ Abrir modal de aprobación
  const handleOpenApprove = (payment) => {
    setSelectedPayment(payment);
    setApprovalData({
      payment_amount: payment.field_hour_price || '',
      notes: '',
    });
    setApproveModalOpen(true);
  };

  // ❌ Abrir modal de rechazo
  const handleOpenReject = (payment) => {
    setSelectedPayment(payment);
    setRejectionData({ rejection_reason: '' });
    setRejectModalOpen(true);
  };

  // ✅ Aprobar pago
  // ✅ Aprobar pago - CORREGIDO
const handleApprovePayment = async () => {
  // 🔥 QUITAR VALIDACIÓN INCORRECTA - No necesita motivo para aprobar
  if (!selectedPayment) {
    setError('No se ha seleccionado ningún pago');
    return;
  }

  try {
    setActionLoading(true);
    setError('');

    await adminAPI.approvePayment(selectedPayment.calendar_id, {
      approved_by: user.id,
      adminName: user.name || user.email, // 🔥 AGREGAR NOMBRE DEL ADMIN
      payment_amount: approvalData.payment_amount || selectedPayment.field_hour_price,
      notes: approvalData.notes || null,
    });

    setSuccess(`Pago aprobado exitosamente para ${selectedPayment.user_name}`);
    setApproveModalOpen(false);
    
    // Limpiar formulario
    setApprovalData({
      payment_amount: '',
      notes: '',
    });
    
    // Recargar datos
    await loadData();

  } catch (err) {
    console.error('❌ Error aprobando pago:', err);
    setError(`Error aprobando pago: ${err.response?.data?.message || err.message}`);
  } finally {
    setActionLoading(false);
  }
};

// ❌ Rechazar pago - MANTENER VALIDACIÓN CORRECTA
const handleRejectPayment = async () => {
  if (!selectedPayment) {
    setError('No se ha seleccionado ningún pago');
    return;
  }

  if (!rejectionData.rejection_reason.trim()) {
    setError('El motivo del rechazo es requerido');
    return;
  }

  try {
    setActionLoading(true);
    setError('');

    await adminAPI.rejectPayment(selectedPayment.calendar_id, {
      rejected_by: user.id,
      adminName: user.name || user.email, // 🔥 AGREGAR NOMBRE DEL ADMIN
      rejection_reason: rejectionData.rejection_reason.trim(),
    });

    setSuccess(`Pago rechazado exitosamente para ${selectedPayment.user_name}`);
    setRejectModalOpen(false);
    
    // Limpiar formulario
    setRejectionData({ rejection_reason: '' });
    
    // Recargar datos
    await loadData();

  } catch (err) {
    console.error('❌ Error rechazando pago:', err);
    setError(`Error rechazando pago: ${err.response?.data?.message || err.message}`);
  } finally {
    setActionLoading(false);
  }
};

  // 🎨 Función para obtener color del estado
  const getStatusColor = (status) => {
    switch (status) {
      case 'pendiente':
        return 'warning';
      case 'aprobado':
        return 'success';
      case 'rechazado':
        return 'error';
      default:
        return 'default';
    }
  };

  // 🎨 Función para obtener texto del estado
  const getStatusText = (status) => {
    switch (status) {
      case 'pendiente':
        return 'Pendiente';
      case 'aprobado':
        return 'Aprobado';
      case 'rechazado':
        return 'Rechazado';
      default:
        return status;
    }
  };

  // 🃏 Componente de tarjeta de pago
  const PaymentCard = ({ payment, showActions = true }) => (
    <Card sx={{ mb: 2, border: '1px solid #e0e0e0' }}>
      <CardContent>
        {/* Header con usuario y estado */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', mb: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Avatar sx={{ bgcolor: 'primary.main' }}>
              <PersonIcon />
            </Avatar>
            <Box>
              <Typography variant="subtitle1" fontWeight="bold">
                {payment.user_name}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {payment.user_email}
              </Typography>
            </Box>
          </Box>
          <Chip
            label={getStatusText(payment.calendar_payment_status)}
            color={getStatusColor(payment.calendar_payment_status)}
            size="small"
          />
        </Box>

        {/* Información de la reserva */}
        <Grid container spacing={2}>
          <Grid item xs={12} sm={6}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
              <FieldIcon color="action" fontSize="small" />
              <Typography variant="body2">
                <strong>{payment.field_name}</strong> ({payment.field_type})
              </Typography>
            </Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
              <CompanyIcon color="action" fontSize="small" />
              <Typography variant="body2">
                {payment.company_name}
              </Typography>
            </Box>
          </Grid>
          <Grid item xs={12} sm={6}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
              <DateIcon color="action" fontSize="small" />
              <Typography variant="body2">
                {new Date(payment.calendar_date).toLocaleDateString()}
              </Typography>
            </Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
              <TimeIcon color="action" fontSize="small" />
              <Typography variant="body2">
                {payment.calendar_init_time} - {payment.calendar_end_time}
              </Typography>
            </Box>
          </Grid>
        </Grid>

        {/* Precio */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 2 }}>
          <MoneyIcon color="action" fontSize="small" />
          <Typography variant="body2">
            <strong>Precio: ${payment.field_hour_price}</strong>
          </Typography>
        </Box>

        {/* Fecha de subida del comprobante */}
        <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
          Comprobante subido: {new Date(payment.calendar_payment_receipt_date).toLocaleString()}
        </Typography>
      </CardContent>

      {showActions && (
        <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
          <Button
            startIcon={<ViewIcon />}
            onClick={() => handleViewPayment(payment)}
            size="small"
          >
            Ver Comprobante
          </Button>
          
          {payment.calendar_payment_status === 'pendiente' && (
            <Box>
              <Button
                startIcon={<RejectIcon />}
                color="error"
                onClick={() => handleOpenReject(payment)}
                size="small"
                sx={{ mr: 1 }}
              >
                Rechazar
              </Button>
              <Button
                startIcon={<ApproveIcon />}
                color="success"
                variant="contained"
                onClick={() => handleOpenApprove(payment)}
                size="small"
              >
                Aprobar
              </Button>
            </Box>
          )}
        </CardActions>
      )}
    </Card>
  );

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4" gutterBottom>
          Gestión de Pagos
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Administra los comprobantes de pago subidos por los usuarios
        </Typography>
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

      {/* Tabs */}
      <Paper sx={{ mb: 3 }}>
        <Tabs value={activeTab} onChange={handleTabChange}>
          <Tab
            label={
              <Badge badgeContent={pendingPayments.length} color="error">
                Pendientes
              </Badge>
            }
          />
          <Tab label="Historial" />
        </Tabs>
      </Paper>

      {/* Contenido de tabs */}
      {activeTab === 0 && (
        <Box>
          <Typography variant="h6" gutterBottom>
            Comprobantes Pendientes ({pendingPayments.length})
          </Typography>
          {pendingPayments.length === 0 ? (
            <Paper sx={{ p: 4, textAlign: 'center' }}>
              <PaymentIcon sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
              <Typography variant="h6" color="text.secondary">
                No hay comprobantes pendientes
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Todos los pagos están procesados
              </Typography>
            </Paper>
          ) : (
            pendingPayments.map((payment) => (
              <PaymentCard key={payment.calendar_id} payment={payment} />
            ))
          )}
        </Box>
      )}

      {activeTab === 1 && (
        <Box>
          <Typography variant="h6" gutterBottom>
            Historial de Pagos ({paymentHistory.length})
          </Typography>
          {paymentHistory.length === 0 ? (
            <Paper sx={{ p: 4, textAlign: 'center' }}>
              <Typography variant="body1" color="text.secondary">
                No hay historial disponible
              </Typography>
            </Paper>
          ) : (
            paymentHistory.map((payment) => (
              <PaymentCard key={payment.calendar_id} payment={payment} showActions={false} />
            ))
          )}
        </Box>
      )}

      {/* Modal para ver comprobante */}
      <Dialog
        open={viewModalOpen}
        onClose={() => setViewModalOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          Comprobante de Pago
          <IconButton
            onClick={() => setViewModalOpen(false)}
            sx={{ position: 'absolute', right: 8, top: 8 }}
          >
            <CloseIcon />
          </IconButton>
        </DialogTitle>
        <DialogContent>
          {selectedPayment && (
            <Box textAlign="center">
              <img
                src={`http://localhost:3000${selectedPayment.calendar_payment_receipt}`}
                alt="Comprobante"
                style={{
                  maxWidth: '100%',
                  maxHeight: '500px',
                  objectFit: 'contain',
                }}
                onError={(e) => {
                  e.target.style.display = 'none';
                  e.target.nextSibling.style.display = 'block';
                }}
              />
              <Typography
                variant="body1"
                color="error"
                sx={{ display: 'none', mt: 2 }}
              >
                Error cargando la imagen del comprobante
              </Typography>
            </Box>
          )}
        </DialogContent>
      </Dialog>

      {/* Modal para aprobar */}
      <Dialog
        open={approveModalOpen}
        onClose={() => setApproveModalOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Aprobar Pago</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Monto del pago"
            type="number"
            value={approvalData.payment_amount}
            onChange={(e) => setApprovalData({
              ...approvalData,
              payment_amount: e.target.value
            })}
            margin="normal"
          />
          <TextField
            fullWidth
            label="Notas (opcional)"
            multiline
            rows={3}
            value={approvalData.notes}
            onChange={(e) => setApprovalData({
              ...approvalData,
              notes: e.target.value
            })}
            margin="normal"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setApproveModalOpen(false)}>
            Cancelar
          </Button>
          <Button
            onClick={handleApprovePayment}
            variant="contained"
            color="success"
            disabled={actionLoading}
          >
            {actionLoading ? <CircularProgress size={20} /> : 'Aprobar'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Modal para rechazar */}
      <Dialog
        open={rejectModalOpen}
        onClose={() => setRejectModalOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Rechazar Pago</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Motivo del rechazo *"
            multiline
            rows={3}
            value={rejectionData.rejection_reason}
            onChange={(e) => setRejectionData({
              ...rejectionData,
              rejection_reason: e.target.value
            })}
            margin="normal"
            required
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRejectModalOpen(false)}>
            Cancelar
          </Button>
          <Button
            onClick={handleRejectPayment}
            variant="contained"
            color="error"
            disabled={actionLoading || !rejectionData.rejection_reason.trim()}
          >
            {actionLoading ? <CircularProgress size={20} /> : 'Rechazar'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Payments;