const express = require('express');
const router = express.Router();
const {
  registerCliente,
  loginCliente,
  loginTrabajador
} = require('../controllers/authController');

router.post('/register-cliente', registerCliente);
router.post('/login-cliente', loginCliente);
router.post('/login-trabajador', loginTrabajador);

module.exports = router;
