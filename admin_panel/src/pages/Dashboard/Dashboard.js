// src/pages/Dashboard/Dashboard.js
import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const Dashboard = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>
      <Paper sx={{ p: 3, textAlign: 'center' }}>
        <Typography variant="h6" gutterBottom>
          Bienvenido al Panel de Administración
        </Typography>
        <Typography color="text.secondary">
          Esta página mostrará estadísticas y resúmenes de la plataforma.
        </Typography>
        <Typography variant="body2" sx={{ mt: 2, color: 'success.main' }}>
          ✅ Configuración inicial completada
        </Typography>
      </Paper>
    </Box>
  );
};

export default Dashboard;



