// src/pages/Fields/Fields.js
import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const Fields = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Gestión de Canchas
      </Typography>
      <Paper sx={{ p: 3, textAlign: 'center' }}>
        <Typography variant="h6" gutterBottom>
          Canchas Registradas
        </Typography>
        <Typography color="text.secondary">
          Visualiza y administra todas las canchas de la plataforma.
        </Typography>
        <Typography variant="body2" sx={{ mt: 2, color: 'warning.main' }}>
          🚧 En desarrollo
        </Typography>
      </Paper>
    </Box>
  );
};

export default Fields;