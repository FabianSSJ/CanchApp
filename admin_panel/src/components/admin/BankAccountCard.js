// src/components/admin/BankAccountCard.js
import React, { useState } from 'react';
import {
  Card,
  CardContent,
  CardActions,
  Typography,
  Box,
  IconButton,
  Chip,
  Button,
  Menu,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  CircularProgress,
  Tooltip,
  Divider
} from '@mui/material';
import {
  MoreVert as MoreIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  ToggleOff as DeactivateIcon,
  ToggleOn as ActivateIcon,
  ContentCopy as CopyIcon,
  Visibility as ViewIcon,
  Person as PersonIcon,
  CreditCard as CardIcon
} from '@mui/icons-material';

import {adminAPI} from '../../services/api';
import { 
  getBankInfo, 
  getAccountTypeInfo, 
  formatAccountNumber,
  formatAccountNumberMasked,
  getAccountStatusText,
  getAccountStatusColor,
  getBankCardBackground
} from '../../utils/bankUtils';

const BankAccountCard = ({ account, onEdit, onSuccess, onError }) => {
  // Estados del menú y diálogos
  const [anchorEl, setAnchorEl] = useState(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [toggleDialogOpen, setToggleDialogOpen] = useState(false);
  const [detailsDialogOpen, setDetailsDialogOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const menuOpen = Boolean(anchorEl);
  const isActive = !account.b_account_delete;
  const bankInfo = getBankInfo(account.b_account_bank);
  const accountTypeInfo = getAccountTypeInfo(account.b_account_type);

  /**
   * Abrir menú
   */
  const handleMenuOpen = (event) => {
    setAnchorEl(event.currentTarget);
  };

  /**
   * Cerrar menú
   */
  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  /**
   * Copiar número de cuenta
   */
  const handleCopyNumber = async () => {
    try {
      await navigator.clipboard.writeText(account.b_account_number.toString());
      onSuccess('Número de cuenta copiado al portapapeles');
    } catch (error) {
      onError('Error copiando número de cuenta');
    }
    handleMenuClose();
  };

  /**
   * Editar cuenta
   */
  const handleEdit = () => {
    onEdit(account);
    handleMenuClose();
  };

  /**
   * Cambiar estado de la cuenta
   */
  const handleToggleStatus = async () => {
    setLoading(true);
    try {
      const result = await adminAPI.toggleBankAccountStatus(
        account.b_account_id,
        !isActive
      );

      if (result.success) {
        onSuccess(result.message);
      } else {
        onError(result.message);
      }
    } catch (error) {
      console.error('Error cambiando estado:', error);
      onError('Error cambiando estado de la cuenta');
    } finally {
      setLoading(false);
      setToggleDialogOpen(false);
      handleMenuClose();
    }
  };

  /**
   * Eliminar cuenta
   */
  const handleDelete = async () => {
    setLoading(true);
    try {
      const result = await adminAPI.deleteBankAccount(account.b_account_id);

      if (result.success) {
        onSuccess('Cuenta bancaria eliminada exitosamente');
      } else {
        onError(result.message);
      }
    } catch (error) {
      console.error('Error eliminando cuenta:', error);
      onError('Error eliminando la cuenta');
    } finally {
      setLoading(false);
      setDeleteDialogOpen(false);
      handleMenuClose();
    }
  };

  return (
    <>
      <Card 
        sx={{ 
          height: '100%',
          background: getBankCardBackground(account.b_account_bank),
          border: `2px solid ${bankInfo.color}20`,
          position: 'relative',
          opacity: isActive ? 1 : 0.7,
          transition: 'all 0.3s ease',
          '&:hover': {
            transform: 'translateY(-4px)',
            boxShadow: 4
          }
        }}
      >
        {/* Estado de la cuenta */}
        <Box position="absolute" top={16} right={16}>
          <Chip
            label={getAccountStatusText(account.b_account_delete)}
            size="small"
            sx={{
              bgcolor: getAccountStatusColor(account.b_account_delete),
              color: 'white',
              fontWeight: 'bold'
            }}
          />
        </Box>

        <CardContent sx={{ pb: 1 }}>
          {/* Header con banco */}
          <Box display="flex" alignItems="center" mb={2}>
            <Box
              sx={{
                width: 48,
                height: 48,
                borderRadius: '12px',
                bgcolor: `${bankInfo.color}20`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                mr: 2
              }}
            >
              <Typography variant="h4">{bankInfo.icon}</Typography>
            </Box>
            <Box flex={1}>
              <Typography variant="h6" component="div" noWrap>
                {bankInfo.label}
              </Typography>
              <Box display="flex" alignItems="center">
                <Typography sx={{ mr: 1 }}>{accountTypeInfo.icon}</Typography>
                <Typography variant="body2" color="text.secondary">
                  Cuenta {account.b_account_type}
                </Typography>
              </Box>
            </Box>
          </Box>

          {/* Número de cuenta */}
          <Box mb={2}>
            <Typography variant="caption" color="text.secondary" gutterBottom display="block">
              Número de cuenta
            </Typography>
            <Typography 
              variant="h6" 
              component="div"
              sx={{ 
                fontFamily: 'monospace',
                letterSpacing: 1,
                wordBreak: 'break-all'
              }}
            >
              {formatAccountNumberMasked(account.b_account_number)}
            </Typography>
          </Box>

          <Divider sx={{ my: 2 }} />

          {/* Información del titular */}
          <Box>
            <Box display="flex" alignItems="center" mb={1}>
              <PersonIcon sx={{ fontSize: 16, mr: 1, color: 'text.secondary' }} />
              <Typography variant="body2" color="text.secondary">
                Titular
              </Typography>
            </Box>
            <Typography variant="body1" fontWeight="medium" noWrap>
              {account.b_account_owner}
            </Typography>
            
            <Box display="flex" alignItems="center" mt={1}>
              <CardIcon sx={{ fontSize: 16, mr: 1, color: 'text.secondary' }} />
              <Typography variant="body2" color="text.secondary">
                CI: {account.b_account_ci}
              </Typography>
            </Box>
          </Box>
        </CardContent>

        <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
          <Button
            size="small"
            startIcon={<ViewIcon />}
            onClick={() => setDetailsDialogOpen(true)}
          >
            Ver detalles
          </Button>

          <IconButton onClick={handleMenuOpen} size="small">
            <MoreIcon />
          </IconButton>
        </CardActions>
      </Card>

      {/* Menú de acciones */}
      <Menu
        anchorEl={anchorEl}
        open={menuOpen}
        onClose={handleMenuClose}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >
        <MenuItem onClick={handleCopyNumber}>
          <CopyIcon sx={{ mr: 1 }} />
          Copiar número
        </MenuItem>
        
        <MenuItem onClick={handleEdit}>
          <EditIcon sx={{ mr: 1 }} />
          Editar
        </MenuItem>
        
        <MenuItem onClick={() => setToggleDialogOpen(true)}>
          {isActive ? (
            <>
              <DeactivateIcon sx={{ mr: 1 }} />
              Desactivar
            </>
          ) : (
            <>
              <ActivateIcon sx={{ mr: 1 }} />
              Activar
            </>
          )}
        </MenuItem>
        
        <MenuItem 
          onClick={() => setDeleteDialogOpen(true)}
          sx={{ color: 'error.main' }}
        >
          <DeleteIcon sx={{ mr: 1 }} />
          Eliminar
        </MenuItem>
      </Menu>

      {/* Diálogo de detalles */}
      <Dialog
        open={detailsDialogOpen}
        onClose={() => setDetailsDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          <Box display="flex" alignItems="center">
            <Typography sx={{ mr: 1 }}>{bankInfo.icon}</Typography>
            Detalles de la Cuenta
          </Box>
        </DialogTitle>
        
        <DialogContent dividers>
          <Box spacing={2}>
            <Box mb={3}>
              <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                Banco
              </Typography>
              <Typography variant="body1">{bankInfo.label}</Typography>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                Tipo de cuenta
              </Typography>
              <Typography variant="body1">{account.b_account_type}</Typography>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                Número completo
              </Typography>
              <Typography variant="body1" sx={{ fontFamily: 'monospace' }}>
                {formatAccountNumber(account.b_account_number)}
              </Typography>
              <Button
                size="small"
                startIcon={<CopyIcon />}
                onClick={handleCopyNumber}
                sx={{ mt: 1 }}
              >
                Copiar
              </Button>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                Titular
              </Typography>
              <Typography variant="body1">{account.b_account_owner}</Typography>
            </Box>

            <Box mb={3}>
              <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                Cédula
              </Typography>
              <Typography variant="body1">{account.b_account_ci}</Typography>
            </Box>

            <Box>
              <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                Estado
              </Typography>
              <Chip
                label={getAccountStatusText(account.b_account_delete)}
                color={isActive ? 'success' : 'error'}
                size="small"
              />
            </Box>
          </Box>
        </DialogContent>
        
        <DialogActions>
          <Button onClick={() => setDetailsDialogOpen(false)}>
            Cerrar
          </Button>
          <Button variant="contained" onClick={handleEdit}>
            Editar
          </Button>
        </DialogActions>
      </Dialog>

      {/* Diálogo de confirmación de cambio de estado */}
      <Dialog
        open={toggleDialogOpen}
        onClose={() => setToggleDialogOpen(false)}
      >
        <DialogTitle>
          {isActive ? 'Desactivar' : 'Activar'} Cuenta Bancaria
        </DialogTitle>
        
        <DialogContent>
          <Typography>
            ¿Estás seguro de que quieres {isActive ? 'desactivar' : 'activar'} esta cuenta bancaria?
            <br />
            <strong>{bankInfo.label} - {formatAccountNumberMasked(account.b_account_number)}</strong>
          </Typography>
          
          {isActive && (
            <Typography color="warning.main" sx={{ mt: 2 }}>
              Al desactivar la cuenta, los usuarios ya no podrán verla para realizar pagos.
            </Typography>
          )}
        </DialogContent>
        
        <DialogActions>
          <Button onClick={() => setToggleDialogOpen(false)}>
            Cancelar
          </Button>
          <Button
            variant="contained"
            color={isActive ? 'warning' : 'success'}
            onClick={handleToggleStatus}
            disabled={loading}
            startIcon={loading ? <CircularProgress size={16} /> : null}
          >
            {loading ? 'Procesando...' : (isActive ? 'Desactivar' : 'Activar')}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Diálogo de confirmación de eliminación */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
      >
        <DialogTitle color="error.main">
          Eliminar Cuenta Bancaria
        </DialogTitle>
        
        <DialogContent>
          <Typography>
            ¿Estás seguro de que quieres eliminar permanentemente esta cuenta bancaria?
            <br />
            <strong>{bankInfo.label} - {formatAccountNumberMasked(account.b_account_number)}</strong>
          </Typography>
          
          <Typography color="error.main" sx={{ mt: 2 }}>
            <strong>Esta acción no se puede deshacer.</strong> La cuenta será eliminada permanentemente del sistema.
          </Typography>
        </DialogContent>
        
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>
            Cancelar
          </Button>
          <Button
            variant="contained"
            color="error"
            onClick={handleDelete}
            disabled={loading}
            startIcon={loading ? <CircularProgress size={16} /> : null}
          >
            {loading ? 'Eliminando...' : 'Eliminar'}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default BankAccountCard;