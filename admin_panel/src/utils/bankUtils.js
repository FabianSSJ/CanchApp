// src/utils/bankUtils.js - Versión actualizada con validación flexible

export const BANKS = [
  {
    value: 'Banco de Loja',
    label: 'Banco de Loja',
    icon: '🏛️',
    color: '#388E3C'
  },
  {
    value: 'CoopMego',
    label: 'CoopMego',
    icon: '🤝',
    color: '#FF9800'
  },
  {
    value: 'Banco Pichincha',
    label: 'Banco Pichincha',
    icon: '🏦',
    color: '#1976D2'
  },
  {
    value: 'Banco Guayaquil',
    label: 'Banco Guayaquil',
    icon: '🏪',
    color: '#D32F2F'
  },
  {
    value: 'Cacpe Loja',
    label: 'Cacpe Loja',
    icon: '💼',
    color: '#7B1FA2'
  }
];

export const ACCOUNT_TYPES = [
  {
    value: 'Ahorros',
    label: 'Ahorros',
    icon: '💰'
  },
  {
    value: 'Corriente',
    label: 'Corriente',
    icon: '💳'
  }
];

/**
 * Obtener información del banco por nombre
 */
export const getBankInfo = (bankName) => {
  return BANKS.find(bank => bank.value === bankName) || {
    value: bankName,
    label: bankName,
    icon: '🏦',
    color: '#616161'
  };
};

/**
 * Obtener información del tipo de cuenta
 */
export const getAccountTypeInfo = (accountType) => {
  return ACCOUNT_TYPES.find(type => type.value === accountType) || {
    value: accountType,
    label: accountType,
    icon: '💳'
  };
};

/**
 * Formatear número de cuenta para visualización
 */
export const formatAccountNumber = (accountNumber) => {
  if (!accountNumber) return '';
  
  const numStr = accountNumber.toString();
  
  // Si es muy corto, retornar tal como está
  if (numStr.length <= 4) return numStr;
  
  // Formatear con guiones cada 4 dígitos
  return numStr.replace(/(\d{4})(?=\d)/g, '$1-');
};

/**
 * Formatear número de cuenta para mostrar solo los últimos 4 dígitos
 */
export const formatAccountNumberMasked = (accountNumber) => {
  if (!accountNumber) return '';
  
  const numStr = accountNumber.toString();
  
  if (numStr.length <= 4) return numStr;
  
  const lastFour = numStr.slice(-4);
  const masked = '*'.repeat(numStr.length - 4);
  
  return `${masked}${lastFour}`;
};

/**
 * Validar número de cédula ecuatoriana (ALGORITMO ESTRICTO)
 */
export const validateEcuadorianCI = (ci) => {
  if (!ci || ci.length !== 10) return false;
  
  const digits = ci.split('').map(Number);
  const provinceCode = parseInt(ci.substring(0, 2));
  
  // Validar código de provincia (01-24)
  if (provinceCode < 1 || provinceCode > 24) return false;
  
  // Algoritmo de validación
  const coefficients = [2, 1, 2, 1, 2, 1, 2, 1, 2];
  let sum = 0;
  
  for (let i = 0; i < coefficients.length; i++) {
    let result = digits[i] * coefficients[i];
    if (result >= 10) {
      result = Math.floor(result / 10) + (result % 10);
    }
    sum += result;
  }
  
  const verifierDigit = sum % 10 === 0 ? 0 : 10 - (sum % 10);
  
  return verifierDigit === digits[9];
};

// 🆕 ===== FUNCIONES DE VALIDACIÓN FLEXIBLE =====

/**
 * Validación más flexible para desarrollo/testing
 * Solo verifica formato básico
 */
export const validateEcuadorianCIFlexible = (ci) => {
  if (!ci) return false;
  
  // Limpiar espacios y caracteres especiales
  const cleanCI = ci.replace(/\D/g, '');
  
  // Solo verificar que tenga 10 dígitos
  if (cleanCI.length !== 10) return false;
  
  // Verificar que todos sean números
  if (!/^\d{10}$/.test(cleanCI)) return false;
  
  // Verificar código de provincia básico (01-30)
  const provinceCode = parseInt(cleanCI.substring(0, 2));
  if (provinceCode < 1 || provinceCode > 30) return false;
  
  return true;
};

/**
 * Formatear cédula para visualización
 */
export const formatEcuadorianCI = (ci) => {
  if (!ci) return '';
  
  const cleanCI = ci.replace(/\D/g, '');
  
  if (cleanCI.length === 10) {
    // Formato: 1234567890 -> 123456789-0
    return `${cleanCI.substring(0, 9)}-${cleanCI.substring(9)}`;
  }
  
  return cleanCI;
};

/**
 * Obtener información de la provincia por código de cédula
 */
export const getProvinceFromCI = (ci) => {
  if (!ci) return null;
  
  const cleanCI = ci.replace(/\D/g, '');
  if (cleanCI.length !== 10) return null;
  
  const provinceCode = parseInt(cleanCI.substring(0, 2));
  
  const provinces = {
    1: 'Azuay',
    2: 'Bolívar', 
    3: 'Cañar',
    4: 'Carchi',
    5: 'Cotopaxi',
    6: 'Chimborazo',
    7: 'El Oro',
    8: 'Esmeraldas',
    9: 'Guayas',
    10: 'Imbabura',
    11: 'Loja',
    12: 'Los Ríos',
    13: 'Manabí',
    14: 'Morona Santiago',
    15: 'Napo',
    16: 'Pastaza',
    17: 'Pichincha',
    18: 'Tungurahua',
    19: 'Zamora Chinchipe',
    20: 'Galápagos',
    21: 'Sucumbíos',
    22: 'Orellana',
    23: 'Santo Domingo de los Tsáchilas',
    24: 'Santa Elena',
    30: 'Extranjeros'
  };
  
  return provinces[provinceCode] || null;
};

// 🔧 EJEMPLOS DE CÉDULAS VÁLIDAS PARA TESTING:
export const validTestCIs = [
  '1717171717', // Pichincha
  '0917171717', // Guayas  
  '1117171717', // Loja
  '0717171717', // El Oro
  '1234567890', // Formato válido genérico
  '0123456789', // Azuay
  '2412345678', // Santa Elena
];

// 🔧 CONFIGURACIÓN PARA AMBIENTE DE DESARROLLO
export const CEDULA_VALIDATION_MODE = {
  STRICT: 'strict',     // Validación completa del algoritmo
  FLEXIBLE: 'flexible', // Solo formato básico
  DISABLED: 'disabled'  // Deshabilitada para testing
};

// 🎯 Cambiar este valor según el ambiente que necesites:
// - 'flexible' para desarrollo/testing (recomendado)
// - 'strict' para producción con validación completa
// - 'disabled' para testing sin validación
export const CURRENT_VALIDATION_MODE = CEDULA_VALIDATION_MODE.FLEXIBLE;

/**
 * 🎯 FUNCIÓN PRINCIPAL DE VALIDACIÓN
 * Esta es la función que debes usar en tus formularios
 */
export const validateCI = (ci) => {
  switch (CURRENT_VALIDATION_MODE) {
    case CEDULA_VALIDATION_MODE.STRICT:
      return validateEcuadorianCI(ci);
    case CEDULA_VALIDATION_MODE.FLEXIBLE:
      return validateEcuadorianCIFlexible(ci);
    case CEDULA_VALIDATION_MODE.DISABLED:
      return true; // Siempre válida para testing
    default:
      return validateEcuadorianCIFlexible(ci);
  }
};

// ===== FUNCIONES EXISTENTES (SIN CAMBIOS) =====

/**
 * Validar número de cuenta bancaria
 */
export const validateAccountNumber = (accountNumber, bankName) => {
  if (!accountNumber) return { valid: false, message: 'Número de cuenta requerido' };
  
  const numStr = accountNumber.toString();
  
  // Validaciones generales
  if (!/^\d+$/.test(numStr)) {
    return { valid: false, message: 'El número de cuenta solo debe contener dígitos' };
  }
  
  if (numStr.length < 8 || numStr.length > 20) {
    return { valid: false, message: 'El número de cuenta debe tener entre 8 y 20 dígitos' };
  }
  
  // Validaciones específicas por banco
  switch (bankName) {
    case 'Banco Pichincha':
      if (numStr.length !== 10) {
        return { valid: false, message: 'Banco Pichincha requiere 10 dígitos' };
      }
      break;
      
    case 'Banco de Loja':
      if (numStr.length !== 9) {
        return { valid: false, message: 'Banco de Loja requiere 9 dígitos' };
      }
      break;
      
    case 'Banco Guayaquil':
      if (numStr.length !== 10) {
        return { valid: false, message: 'Banco Guayaquil requiere 10 dígitos' };
      }
      break;
      
    default:
      // Para otros bancos, longitud general
      if (numStr.length < 8 || numStr.length > 12) {
        return { valid: false, message: 'Debe tener entre 8 y 12 dígitos' };
      }
  }
  
  return { valid: true };
};

/**
 * Generar color de fondo para la tarjeta del banco
 */
export const getBankCardBackground = (bankName) => {
  const bankInfo = getBankInfo(bankName);
  return `linear-gradient(135deg, ${bankInfo.color}15, ${bankInfo.color}05)`;
};

/**
 * Obtener texto de estado de la cuenta
 */
export const getAccountStatusText = (isDeleted) => {
  return isDeleted ? 'Inactiva' : 'Activa';
};

/**
 * Obtener color del estado de la cuenta
 */
export const getAccountStatusColor = (isDeleted) => {
  return isDeleted ? '#f44336' : '#4caf50';
};

/**
 * Filtrar cuentas por texto de búsqueda
 */
export const filterAccountsBySearch = (accounts, searchText) => {
  if (!searchText) return accounts;
  
  const search = searchText.toLowerCase();
  
  return accounts.filter(account => 
    account.b_account_bank.toLowerCase().includes(search) ||
    account.b_account_number.toString().includes(search) ||
    account.b_account_owner.toLowerCase().includes(search) ||
    account.b_account_ci.toString().includes(search) ||
    account.b_account_type.toLowerCase().includes(search)
  );
};

/**
 * Ordenar cuentas por criterio
 */
export const sortAccountsBy = (accounts, sortBy, sortOrder = 'asc') => {
  return [...accounts].sort((a, b) => {
    let aValue, bValue;
    
    switch (sortBy) {
      case 'bank':
        aValue = a.b_account_bank;
        bValue = b.b_account_bank;
        break;
      case 'number':
        aValue = parseInt(a.b_account_number);
        bValue = parseInt(b.b_account_number);
        break;
      case 'owner':
        aValue = a.b_account_owner;
        bValue = b.b_account_owner;
        break;
      case 'type':
        aValue = a.b_account_type;
        bValue = b.b_account_type;
        break;
      case 'status':
        aValue = a.b_account_delete ? 1 : 0; // Inactiva = 1, Activa = 0
        bValue = b.b_account_delete ? 1 : 0;
        break;
      default:
        aValue = a.b_account_id;
        bValue = b.b_account_id;
    }
    
    if (typeof aValue === 'string') {
      aValue = aValue.toLowerCase();
      bValue = bValue.toLowerCase();
    }
    
    if (sortOrder === 'desc') {
      return bValue > aValue ? 1 : bValue < aValue ? -1 : 0;
    } else {
      return aValue > bValue ? 1 : aValue < bValue ? -1 : 0;
    }
  });
};