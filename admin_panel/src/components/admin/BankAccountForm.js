// src/components/admin/BankAccountForm.js
import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Typography,
  Box,
  Alert,
  CircularProgress,
  InputAdornment,
  Chip
} from '@mui/material';
import {
  AccountBalance as BankIcon,
  Person as PersonIcon,
  CreditCard as CardIcon,
  Numbers as NumbersIcon
} from '@mui/icons-material';

import {adminAPI} from '../../services/api';
import { 
  BANKS, 
  ACCOUNT_TYPES, 
  validateCI, // 🔧 Cambiado de validateEcuadorianCI a validateCI
  validateAccountNumber,
  getBankInfo,
  formatEcuadorianCI,
  getProvinceFromCI,
  validTestCIs 
} from '../../utils/bankUtils';

const BankAccountForm = ({ open, account, onClose, onSuccess, onError }) => {
  // Estados del formulario
  const [formData, setFormData] = useState({
    bank: '',
    accountNumber: '',
    ownerCI: '',
    ownerName: '',
    accountType: '',
    companyId: 1 // Por ahora hardcodeado, luego obtener del contexto de usuario
  });

  // Estados de validación
  const [errors, setErrors] = useState({});
  const [touched, setTouched] = useState({});

  // Estados de UI
  const [loading, setLoading] = useState(false);
  const [checkingNumber, setCheckingNumber] = useState(false);
  const [showCedulaHelper, setShowCedulaHelper] = useState(false); // 🆕 Helper para testing

  // Efecto para cargar datos cuando se abre el formulario
  useEffect(() => {
    if (open) {
      if (account) {
        // Modo edición
        setFormData({
          bank: account.b_account_bank || '',
          accountNumber: account.b_account_number?.toString() || '',
          ownerCI: account.b_account_ci?.toString() || '',
          ownerName: account.b_account_owner || '',
          accountType: account.b_account_type || '',
          companyId: account.company_id || 1
        });
      } else {
        // Modo creación
        resetForm();
      }
      setErrors({});
      setTouched({});
    }
  }, [open, account]);

  /**
   * Resetear formulario
   */
  const resetForm = () => {
    setFormData({
      bank: '',
      accountNumber: '',
      ownerCI: '',
      ownerName: '',
      accountType: '',
      companyId: 1
    });
    setErrors({});
    setTouched({});
  };

  /**
   * Manejar cambios en los campos
   */
  const handleChange = (field) => (event) => {
    const value = event.target.value;
    
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));

    // Limpiar error del campo cuando se modifica
    if (errors[field]) {
      setErrors(prev => ({
        ...prev,
        [field]: ''
      }));
    }

    // Validaciones en tiempo real
    if (field === 'ownerCI' && value) {
      validateCIField(value); // 🔧 Función actualizada
    }
    
    if (field === 'accountNumber' && value && formData.bank) {
      validateAccountNumberField(value, formData.bank);
    }
  };

  /**
   * Manejar blur de campos
   */
  const handleBlur = (field) => () => {
    setTouched(prev => ({
      ...prev,
      [field]: true
    }));

    // Validaciones específicas en blur
    if (field === 'accountNumber' && formData.accountNumber) {
      checkAccountNumberExists();
    }
  };

  /**
   * Validar cédula con nueva función flexible
   */
  const validateCIField = (ci) => {
    if (!validateCI(ci)) { // 🔧 Usa validación flexible
      setErrors(prev => ({
        ...prev,
        ownerCI: 'Cédula inválida (debe tener 10 dígitos)'
      }));
    } else {
      setErrors(prev => ({
        ...prev,
        ownerCI: ''
      }));
    }
  };

  /**
   * Validar número de cuenta
   */
  const validateAccountNumberField = (accountNumber, bank) => {
    const validation = validateAccountNumber(accountNumber, bank);
    if (!validation.valid) {
      setErrors(prev => ({
        ...prev,
        accountNumber: validation.message
      }));
    } else {
      setErrors(prev => ({
        ...prev,
        accountNumber: ''
      }));
    }
  };

  /**
   * Verificar si el número de cuenta ya existe
   */
  const checkAccountNumberExists = async () => {
    if (!formData.accountNumber || errors.accountNumber) return;

    setCheckingNumber(true);
    try {
      const result = await adminAPI.checkAccountNumberExists(
        formData.accountNumber,
        account?.b_account_id
      );
      
      if (result.success && result.exists) {
        setErrors(prev => ({
          ...prev,
          accountNumber: 'Este número de cuenta ya está registrado'
        }));
      }
    } catch (error) {
      console.error('Error verificando número de cuenta:', error);
    } finally {
      setCheckingNumber(false);
    }
  };

  /**
   * Validar todo el formulario
   */
  const validateForm = () => {
    const newErrors = {};

    // Validaciones requeridas
    if (!formData.bank) newErrors.bank = 'Banco requerido';
    if (!formData.accountNumber) newErrors.accountNumber = 'Número de cuenta requerido';
    if (!formData.ownerCI) newErrors.ownerCI = 'Cédula requerida';
    if (!formData.ownerName) newErrors.ownerName = 'Nombre del titular requerido';
    if (!formData.accountType) newErrors.accountType = 'Tipo de cuenta requerido';

    // Validaciones específicas
    if (formData.ownerCI && !validateCI(formData.ownerCI)) { // 🔧 Función actualizada
      newErrors.ownerCI = 'Cédula inválida (debe tener 10 dígitos)';
    }

    if (formData.accountNumber && formData.bank) {
      const validation = validateAccountNumber(formData.accountNumber, formData.bank);
      if (!validation.valid) {
        newErrors.accountNumber = validation.message;
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  /**
   * Enviar formulario
   */
  const handleSubmit = async (event) => {
    event.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setLoading(true);
    try {
      let result;
      
      if (account) {
        // Actualizar cuenta existente
        result = await adminAPI.updateBankAccount(account.b_account_id, formData);
      } else {
        // Crear nueva cuenta
        result = await adminAPI.createBankAccount(formData);
      }

      if (result.success) {
        onSuccess(result.message);
      } else {
        if (result.errors) {
          setErrors(result.errors);
        }
        onError(result.message);
      }
    } catch (error) {
      console.error('Error en formulario:', error);
      onError('Error procesando la solicitud');
    } finally {
      setLoading(false);
    }
  };

  /**
   * Cerrar formulario
   */
  const handleClose = () => {
    if (!loading) {
      onClose();
    }
  };

  // 🆕 Componente de ayuda para cédulas de testing
  const CedulaHelper = () => (
    <Box sx={{ mt: 1 }}>
      <Button
        size="small"
        variant="text"
        onClick={() => setShowCedulaHelper(!showCedulaHelper)}
        sx={{ fontSize: '12px', textTransform: 'none' }}
      >
        {showCedulaHelper ? 'Ocultar' : 'Ver'} cédulas de ejemplo
      </Button>
      
      {showCedulaHelper && (
        <Box sx={{ mt: 1, p: 1, bgcolor: 'grey.100', borderRadius: 1 }}>
          <Typography variant="caption" display="block" gutterBottom>
            Cédulas válidas para testing:
          </Typography>
          {validTestCIs.map((ci, index) => (
            <Chip
              key={index}
              label={formatEcuadorianCI(ci)}
              size="small"
              variant="outlined"
              sx={{ mr: 1, mb: 0.5, fontSize: '11px', cursor: 'pointer' }}
              onClick={() => {
                setFormData(prev => ({ ...prev, ownerCI: ci }));
                setShowCedulaHelper(false);
                // Limpiar error si existe
                if (errors.ownerCI) {
                  setErrors(prev => ({ ...prev, ownerCI: '' }));
                }
              }}
            />
          ))}
        </Box>
      )}
    </Box>
  );

  const isEditing = !!account;
  const selectedBank = getBankInfo(formData.bank);

  return (
    <Dialog 
      open={open} 
      onClose={handleClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        component: 'form',
        onSubmit: handleSubmit
      }}
    >
      <DialogTitle>
        <Box display="flex" alignItems="center">
          <BankIcon sx={{ mr: 2 }} />
          {isEditing ? 'Editar Cuenta Bancaria' : 'Nueva Cuenta Bancaria'}
        </Box>
      </DialogTitle>

      <DialogContent dividers>
        <Grid container spacing={3}>
          {/* Selección de banco */}
          <Grid item xs={12} md={6}>
            <FormControl fullWidth error={!!errors.bank}>
              <InputLabel>Banco *</InputLabel>
              <Select
                value={formData.bank}
                label="Banco *"
                onChange={handleChange('bank')}
                onBlur={handleBlur('bank')}
              >
                {BANKS.map((bank) => (
                  <MenuItem key={bank.value} value={bank.value}>
                    <Box display="flex" alignItems="center">
                      <Typography sx={{ mr: 1 }}>{bank.icon}</Typography>
                      {bank.label}
                    </Box>
                  </MenuItem>
                ))}
              </Select>
              {errors.bank && (
                <Typography variant="caption" color="error" sx={{ mt: 1 }}>
                  {errors.bank}
                </Typography>
              )}
            </FormControl>
          </Grid>

          {/* Tipo de cuenta */}
          <Grid item xs={12} md={6}>
            <FormControl fullWidth error={!!errors.accountType}>
              <InputLabel>Tipo de Cuenta *</InputLabel>
              <Select
                value={formData.accountType}
                label="Tipo de Cuenta *"
                onChange={handleChange('accountType')}
                onBlur={handleBlur('accountType')}
              >
                {ACCOUNT_TYPES.map((type) => (
                  <MenuItem key={type.value} value={type.value}>
                    <Box display="flex" alignItems="center">
                      <Typography sx={{ mr: 1 }}>{type.icon}</Typography>
                      {type.label}
                    </Box>
                  </MenuItem>
                ))}
              </Select>
              {errors.accountType && (
                <Typography variant="caption" color="error" sx={{ mt: 1 }}>
                  {errors.accountType}
                </Typography>
              )}
            </FormControl>
          </Grid>

          {/* Número de cuenta */}
          <Grid item xs={12}>
            <TextField
              fullWidth
              label="Número de Cuenta"
              value={formData.accountNumber}
              onChange={handleChange('accountNumber')}
              onBlur={handleBlur('accountNumber')}
              error={!!errors.accountNumber}
              helperText={errors.accountNumber || 'Ingrese solo números, sin espacios ni guiones'}
              required
              type="tel"
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <NumbersIcon />
                  </InputAdornment>
                ),
                endAdornment: checkingNumber ? (
                  <InputAdornment position="end">
                    <CircularProgress size={20} />
                  </InputAdornment>
                ) : null
              }}
            />
            
            {/* Información específica del banco seleccionado */}
            {formData.bank && (
              <Box mt={1}>
                <Chip
                  icon={<span>{selectedBank.icon}</span>}
                  label={`${selectedBank.label} - ${getBankNumberFormat(formData.bank)}`}
                  size="small"
                  variant="outlined"
                />
              </Box>
            )}
          </Grid>

          {/* Nombre del titular */}
          <Grid item xs={12} md={8}>
            <TextField
              fullWidth
              label="Nombre del Titular"
              value={formData.ownerName}
              onChange={handleChange('ownerName')}
              onBlur={handleBlur('ownerName')}
              error={!!errors.ownerName}
              helperText={errors.ownerName}
              required
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <PersonIcon />
                  </InputAdornment>
                )
              }}
            />
          </Grid>

          {/* Cédula */}
          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              label="Cédula del Titular"
              value={formData.ownerCI}
              onChange={handleChange('ownerCI')}
              onBlur={handleBlur('ownerCI')}
              error={!!errors.ownerCI}
              helperText={errors.ownerCI || 'Formato: 1234567890'}
              required
              type="tel"
              inputProps={{ maxLength: 10 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <CardIcon />
                  </InputAdornment>
                )
              }}
            />
            
            {/* 🆕 Helper para testing - Solo en desarrollo */}
            {process.env.NODE_ENV === 'development' && <CedulaHelper />}
            
            {/* 🆕 Mostrar provincia si la cédula es válida */}
            {formData.ownerCI && validateCI(formData.ownerCI) && (
              <Typography variant="caption" color="success.main" sx={{ mt: 0.5, display: 'block' }}>
                ✓ Provincia: {getProvinceFromCI(formData.ownerCI) || 'Válida'}
              </Typography>
            )}
          </Grid>

          {/* Información adicional */}
          <Grid item xs={12}>
            <Alert severity="info">
              <Typography variant="body2">
                <strong>Información importante:</strong>
                <br />
                • Esta cuenta estará disponible para todos los usuarios para realizar pagos
                <br />
                • Asegúrate de que los datos sean correctos antes de guardar
                <br />
                • El número de cuenta debe ser único en el sistema
              </Typography>
            </Alert>
          </Grid>
        </Grid>
      </DialogContent>

      <DialogActions sx={{ p: 3 }}>
        <Button 
          onClick={handleClose}
          disabled={loading}
        >
          Cancelar
        </Button>
        <Button
          type="submit"
          variant="contained"
          disabled={loading || Object.keys(errors).some(key => errors[key])}
          startIcon={loading ? <CircularProgress size={20} /> : null}
        >
          {loading ? 'Guardando...' : (isEditing ? 'Actualizar' : 'Crear Cuenta')}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

/**
 * Obtener formato de número según el banco
 */
const getBankNumberFormat = (bank) => {
  switch (bank) {
    case 'Banco Pichincha':
      return '10 dígitos';
    case 'Banco de Loja':
      return '9 dígitos';
    case 'Banco Guayaquil':
      return '10 dígitos';
    default:
      return '8-12 dígitos';
  }
};

export default BankAccountForm;