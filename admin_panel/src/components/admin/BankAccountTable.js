// src/components/admin/BankAccountTable.js
import React, { useState } from 'react';
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  TableSortLabel,
  Paper,
  IconButton,
  Chip,
  Box,
  Typography,
  Menu,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  CircularProgress,
  Checkbox,
  Toolbar,
  Tooltip
} from '@mui/material';
import {
  MoreVert as MoreIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  ToggleOff as DeactivateIcon,
  ToggleOn as ActivateIcon,
  ContentCopy as CopyIcon,
  Visibility as ViewIcon
} from '@mui/icons-material';

import {adminAPI} from '../../services/api';
import { 
  getBankInfo, 
  formatAccountNumberMasked,
  formatAccountNumber,
  getAccountStatusText,
  getAccountStatusColor
} from '../../utils/bankUtils';

const BankAccountTable = ({ accounts, onEdit, onSuccess, onError }) => {
  // Estados de la tabla
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [orderBy, setOrderBy] = useState('b_account_bank');
  const [order, setOrder] = useState('asc');
  const [selected, setSelected] = useState([]);

  // Estados de menús y diálogos
  const [anchorEl, setAnchorEl] = useState(null);
  const [currentAccount, setCurrentAccount] = useState(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [toggleDialogOpen, setToggleDialogOpen] = useState(false);
  const [bulkActionDialogOpen, setBulkActionDialogOpen] = useState(false);
  const [bulkAction, setBulkAction] = useState('');
  const [loading, setLoading] = useState(false);

  /**
   * Encabezados de la tabla
   */
  const headCells = [
    { id: 'b_account_bank', label: 'Banco', sortable: true },
    { id: 'b_account_number', label: 'Número de Cuenta', sortable: true },
    { id: 'b_account_type', label: 'Tipo', sortable: true },
    { id: 'b_account_owner', label: 'Titular', sortable: true },
    { id: 'b_account_ci', label: 'Cédula', sortable: false },
    { id: 'status', label: 'Estado', sortable: true },
    { id: 'actions', label: 'Acciones', sortable: false }
  ];

  /**
   * Manejar ordenamiento
   */
  const handleRequestSort = (property) => {
    const isAsc = orderBy === property && order === 'asc';
    setOrder(isAsc ? 'desc' : 'asc');
    setOrderBy(property);
  };

  /**
   * Ordenar datos
   */
  const getSortedData = () => {
    return accounts.slice().sort((a, b) => {
      let aValue, bValue;

      switch (orderBy) {
        case 'b_account_bank':
          aValue = a.b_account_bank;
          bValue = b.b_account_bank;
          break;
        case 'b_account_number':
          aValue = parseInt(a.b_account_number);
          bValue = parseInt(b.b_account_number);
          break;
        case 'b_account_type':
          aValue = a.b_account_type;
          bValue = b.b_account_type;
          break;
        case 'b_account_owner':
          aValue = a.b_account_owner;
          bValue = b.b_account_owner;
          break;
        case 'status':
          aValue = a.b_account_delete ? 1 : 0;
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

      if (order === 'desc') {
        return bValue > aValue ? 1 : bValue < aValue ? -1 : 0;
      } else {
        return aValue > bValue ? 1 : aValue < bValue ? -1 : 0;
      }
    });
  };

  /**
   * Cambiar página
   */
  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  /**
   * Cambiar filas por página
   */
  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  /**
   * Seleccionar todas las filas
   */
  const handleSelectAllClick = (event) => {
    if (event.target.checked) {
      const newSelected = accounts.map((account) => account.b_account_id);
      setSelected(newSelected);
      return;
    }
    setSelected([]);
  };

  /**
   * Seleccionar fila individual
   */
  const handleClick = (id) => {
    const selectedIndex = selected.indexOf(id);
    let newSelected = [];

    if (selectedIndex === -1) {
      newSelected = newSelected.concat(selected, id);
    } else if (selectedIndex === 0) {
      newSelected = newSelected.concat(selected.slice(1));
    } else if (selectedIndex === selected.length - 1) {
      newSelected = newSelected.concat(selected.slice(0, -1));
    } else if (selectedIndex > 0) {
      newSelected = newSelected.concat(
        selected.slice(0, selectedIndex),
        selected.slice(selectedIndex + 1)
      );
    }

    setSelected(newSelected);
  };

  /**
   * Verificar si una fila está seleccionada
   */
  const isSelected = (id) => selected.indexOf(id) !== -1;

  /**
   * Abrir menú de acciones
   */
  const handleMenuOpen = (event, account) => {
    setAnchorEl(event.currentTarget);
    setCurrentAccount(account);
  };

  /**
   * Cerrar menú
   */
  const handleMenuClose = () => {
    setAnchorEl(null);
    setCurrentAccount(null);
  };

  /**
   * Copiar número de cuenta
   */
  const handleCopyNumber = async (accountNumber) => {
    try {
      await navigator.clipboard.writeText(accountNumber.toString());
      onSuccess('Número de cuenta copiado al portapapeles');
    } catch (error) {
      onError('Error copiando número de cuenta');
    }
    handleMenuClose();
  };

  /**
   * Editar cuenta
   */
  const handleEdit = (account) => {
    onEdit(account);
    handleMenuClose();
  };

  /**
   * Cambiar estado de cuenta individual
   */
  const handleToggleStatus = async () => {
    if (!currentAccount) return;

    setLoading(true);
    try {
      const result = await adminAPI.toggleBankAccountStatus(
        currentAccount.b_account_id,
        currentAccount.b_account_delete // Si está eliminada, activar
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
   * Eliminar cuenta individual
   */
  const handleDelete = async () => {
    if (!currentAccount) return;

    setLoading(true);
    try {
      const result = await adminAPI.deleteBankAccount(currentAccount.b_account_id);

      if (result.success) {
        onSuccess('Cuenta bancaria eliminada exitosamente');
        setSelected(selected.filter(id => id !== currentAccount.b_account_id));
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

  /**
   * Ejecutar acción masiva
   */
  const handleBulkAction = async () => {
    if (selected.length === 0) return;

    setLoading(true);
    try {
      const promises = selected.map(async (accountId) => {
        const account = accounts.find(a => a.b_account_id === accountId);
        if (!account) return;

        if (bulkAction === 'activate') {
          return adminAPI.toggleBankAccountStatus(accountId, true);
        } else if (bulkAction === 'deactivate') {
          return adminAPI.toggleBankAccountStatus(accountId, false);
        } else if (bulkAction === 'delete') {
          return adminAPI.deleteBankAccount(accountId);
        }
      });

      await Promise.all(promises);
      
      onSuccess(`Acción aplicada a ${selected.length} cuenta(s)`);
      setSelected([]);
    } catch (error) {
      console.error('Error en acción masiva:', error);
      onError('Error ejecutando acción masiva');
    } finally {
      setLoading(false);
      setBulkActionDialogOpen(false);
    }
  };

  const sortedData = getSortedData();
  const paginatedData = sortedData.slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage);
  const numSelected = selected.length;
  const rowCount = accounts.length;

  return (
    <Paper sx={{ width: '100%', mb: 2 }}>
      {/* Toolbar con acciones masivas */}
      {numSelected > 0 && (
        <Toolbar
          sx={{
            pl: { sm: 2 },
            pr: { xs: 1, sm: 1 },
            bgcolor: 'primary.light',
            color: 'primary.contrastText'
          }}
        >
          <Typography
            sx={{ flex: '1 1 100%' }}
            color="inherit"
            variant="subtitle1"
            component="div"
          >
            {numSelected} seleccionada(s)
          </Typography>

          <Box display="flex" gap={1}>
            <Button
              size="small"
              variant="contained"
              color="success"
              onClick={() => {
                setBulkAction('activate');
                setBulkActionDialogOpen(true);
              }}
            >
              Activar
            </Button>
            <Button
              size="small"
              variant="contained"
              color="warning"
              onClick={() => {
                setBulkAction('deactivate');
                setBulkActionDialogOpen(true);
              }}
            >
              Desactivar
            </Button>
            <Button
              size="small"
              variant="contained"
              color="error"
              onClick={() => {
                setBulkAction('delete');
                setBulkActionDialogOpen(true);
              }}
            >
              Eliminar
            </Button>
          </Box>
        </Toolbar>
      )}

      {/* Tabla */}
      <TableContainer>
        <Table stickyHeader>
          <TableHead>
            <TableRow>
              <TableCell padding="checkbox">
                <Checkbox
                  color="primary"
                  indeterminate={numSelected > 0 && numSelected < rowCount}
                  checked={rowCount > 0 && numSelected === rowCount}
                  onChange={handleSelectAllClick}
                />
              </TableCell>
              {headCells.map((headCell) => (
                <TableCell
                  key={headCell.id}
                  sortDirection={orderBy === headCell.id ? order : false}
                >
                  {headCell.sortable ? (
                    <TableSortLabel
                      active={orderBy === headCell.id}
                      direction={orderBy === headCell.id ? order : 'asc'}
                      onClick={() => handleRequestSort(headCell.id)}
                    >
                      {headCell.label}
                    </TableSortLabel>
                  ) : (
                    headCell.label
                  )}
                </TableCell>
              ))}
            </TableRow>
          </TableHead>

          <TableBody>
            {paginatedData.map((account, index) => {
              const isItemSelected = isSelected(account.b_account_id);
              const labelId = `enhanced-table-checkbox-${index}`;
              const bankInfo = getBankInfo(account.b_account_bank);
              const isActive = !account.b_account_delete;

              return (
                <TableRow
                  hover
                  role="checkbox"
                  aria-checked={isItemSelected}
                  tabIndex={-1}
                  key={account.b_account_id}
                  selected={isItemSelected}
                  sx={{ opacity: isActive ? 1 : 0.6 }}
                >
                  <TableCell padding="checkbox">
                    <Checkbox
                      color="primary"
                      checked={isItemSelected}
                      onChange={() => handleClick(account.b_account_id)}
                      inputProps={{ 'aria-labelledby': labelId }}
                    />
                  </TableCell>

                  {/* Banco */}
                  <TableCell>
                    <Box display="flex" alignItems="center">
                      <Typography sx={{ mr: 1 }}>{bankInfo.icon}</Typography>
                      <Typography variant="body2" fontWeight="medium">
                        {bankInfo.label}
                      </Typography>
                    </Box>
                  </TableCell>

                  {/* Número de cuenta */}
                  <TableCell>
                    <Box>
                      <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                        {formatAccountNumberMasked(account.b_account_number)}
                      </Typography>
                      <Tooltip title="Copiar número completo">
                        <IconButton
                          size="small"
                          onClick={() => handleCopyNumber(account.b_account_number)}
                        >
                          <CopyIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </Box>
                  </TableCell>

                  {/* Tipo */}
                  <TableCell>
                    <Chip
                      label={account.b_account_type}
                      size="small"
                      variant="outlined"
                    />
                  </TableCell>

                  {/* Titular */}
                  <TableCell>
                    <Typography variant="body2" noWrap>
                      {account.b_account_owner}
                    </Typography>
                  </TableCell>

                  {/* Cédula */}
                  <TableCell>
                    <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                      {account.b_account_ci}
                    </Typography>
                  </TableCell>

                  {/* Estado */}
                  <TableCell>
                    <Chip
                      label={getAccountStatusText(account.b_account_delete)}
                      size="small"
                      sx={{
                        bgcolor: getAccountStatusColor(account.b_account_delete),
                        color: 'white',
                        fontWeight: 'bold'
                      }}
                    />
                  </TableCell>

                  {/* Acciones */}
                  <TableCell>
                    <IconButton
                      size="small"
                      onClick={(e) => handleMenuOpen(e, account)}
                    >
                      <MoreIcon />
                    </IconButton>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Paginación */}
      <TablePagination
        rowsPerPageOptions={[5, 10, 25, 50]}
        component="div"
        count={accounts.length}
        rowsPerPage={rowsPerPage}
        page={page}
        onPageChange={handleChangePage}
        onRowsPerPageChange={handleChangeRowsPerPage}
        labelRowsPerPage="Filas por página:"
        labelDisplayedRows={({ from, to, count }) => 
          `${from}-${to} de ${count !== -1 ? count : `más de ${to}`}`
        }
      />

      {/* Menú de acciones */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={() => handleEdit(currentAccount)}>
          <EditIcon sx={{ mr: 1 }} />
          Editar
        </MenuItem>

        <MenuItem onClick={() => handleCopyNumber(currentAccount?.b_account_number)}>
          <CopyIcon sx={{ mr: 1 }} />
          Copiar número
        </MenuItem>

        <MenuItem onClick={() => setToggleDialogOpen(true)}>
          {currentAccount?.b_account_delete ? (
            <>
              <ActivateIcon sx={{ mr: 1 }} />
              Activar
            </>
          ) : (
            <>
              <DeactivateIcon sx={{ mr: 1 }} />
              Desactivar
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

      {/* Diálogo de confirmación de cambio de estado */}
      <Dialog
        open={toggleDialogOpen}
        onClose={() => setToggleDialogOpen(false)}
      >
        <DialogTitle>
          {currentAccount?.b_account_delete ? 'Activar' : 'Desactivar'} Cuenta Bancaria
        </DialogTitle>
        
        <DialogContent>
          <Typography>
            ¿Estás seguro de que quieres {currentAccount?.b_account_delete ? 'activar' : 'desactivar'} esta cuenta bancaria?
          </Typography>
        </DialogContent>
        
        <DialogActions>
          <Button onClick={() => setToggleDialogOpen(false)}>
            Cancelar
          </Button>
          <Button
            variant="contained"
            onClick={handleToggleStatus}
            disabled={loading}
            startIcon={loading ? <CircularProgress size={16} /> : null}
          >
            {loading ? 'Procesando...' : 'Confirmar'}
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
          </Typography>
          <Typography color="error.main" sx={{ mt: 2 }}>
            Esta acción no se puede deshacer.
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

      {/* Diálogo de acciones masivas */}
      <Dialog
        open={bulkActionDialogOpen}
        onClose={() => setBulkActionDialogOpen(false)}
      >
        <DialogTitle>
          Acción Masiva
        </DialogTitle>
        
        <DialogContent>
          <Typography>
            ¿Estás seguro de que quieres {bulkAction === 'activate' ? 'activar' : bulkAction === 'deactivate' ? 'desactivar' : 'eliminar'} {selected.length} cuenta(s) seleccionada(s)?
          </Typography>
          {bulkAction === 'delete' && (
            <Typography color="error.main" sx={{ mt: 2 }}>
              Esta acción no se puede deshacer.
            </Typography>
          )}
        </DialogContent>
        
        <DialogActions>
          <Button onClick={() => setBulkActionDialogOpen(false)}>
            Cancelar
          </Button>
          <Button
            variant="contained"
            color={bulkAction === 'delete' ? 'error' : 'primary'}
            onClick={handleBulkAction}
            disabled={loading}
            startIcon={loading ? <CircularProgress size={16} /> : null}
          >
            {loading ? 'Procesando...' : 'Confirmar'}
          </Button>
        </DialogActions>
      </Dialog>
    </Paper>
  );
};

export default BankAccountTable;