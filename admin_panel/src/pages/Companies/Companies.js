// src/pages/Companies/Companies.js
import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const Companies = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Gestión de Empresas
      </Typography>
      <Paper sx={{ p: 3, textAlign: 'center' }}>
        <Typography variant="h6" gutterBottom>
          Empresas Registradas
        </Typography>
        <Typography color="text.secondary">
          Administra las empresas dueñas de canchas.
        </Typography>
        <Typography variant="body2" sx={{ mt: 2, color: 'warning.main' }}>
          🚧 En desarrollo
        </Typography>
      </Paper>
    </Box>
  );
};

export default Companies;