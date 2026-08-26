const pool = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'tucanchape_secret_key_jwt_2026';

// 1. Register Cliente
const registerCliente = async (req, res) => {
  try {
    const { DNI, Nombres, Apellidos, Correo, Telefono, ContrasenaHash } = req.body;

    if (!DNI || !Nombres || !Apellidos || !Correo || !Telefono || !ContrasenaHash) {
      return res.status(400).json({ error: 'Todos los campos son obligatorios (DNI, Nombres, Apellidos, Correo, Telefono, ContrasenaHash).' });
    }

    if (DNI.length !== 8) {
      return res.status(400).json({ error: 'El DNI debe tener exactamente 8 caracteres.' });
    }

    if (Telefono.length !== 9) {
      return res.status(400).json({ error: 'El Teléfono debe tener exactamente 9 dígitos.' });
    }

    // Check if client already exists by DNI or Correo
    const [existing] = await pool.promise().query(
      'SELECT IdCliente FROM Cliente WHERE DNI = ? OR Correo = ?',
      [DNI, Correo]
    );

    if (existing.length > 0) {
      return res.status(409).json({ error: 'El cliente con este DNI o Correo ya se encuentra registrado.' });
    }

    // Hash password with bcrypt
    const saltRounds = 10;
    const encryptedContrasenaHash = await bcrypt.hash(ContrasenaHash, saltRounds);

    // Insert into Cliente
    const [result] = await pool.promise().query(
      `INSERT INTO Cliente (DNI, Nombres, Apellidos, Correo, Telefono, ContrasenaHash, PuntosFidelidad) 
       VALUES (?, ?, ?, ?, ?, ?, 0)`,
      [DNI, Nombres, Apellidos, Correo, Telefono, encryptedContrasenaHash]
    );

    return res.status(201).json({
      message: 'Cliente registrado exitosamente.',
      idCliente: result.insertId,
      cliente: {
        dni: DNI,
        nombres: Nombres,
        apellidos: Apellidos,
        correo: Correo,
        telefono: Telefono
      }
    });

  } catch (error) {
    console.error('Error in registerCliente:', error);
    return res.status(500).json({ error: 'Error interno del servidor al registrar el cliente.' });
  }
};

// 2. Login Cliente
const loginCliente = async (req, res) => {
  try {
    const { Correo, Contrasena, ContrasenaHash } = req.body;
    const passwordIngresada = ContrasenaHash || Contrasena;

    if (!Correo || !passwordIngresada) {
      return res.status(400).json({ error: "Correo y contraseña son obligatorios." });
    }

    // Find client by Correo
    const [rows] = await pool.promise().query(
      'SELECT * FROM Cliente WHERE Correo = ?',
      [Correo]
    );

    if (rows.length === 0) {
      return res.status(401).json({ error: 'Credenciales inválidas (Correo no encontrado).' });
    }

    const cliente = rows[0];

    // Compare password
    const isPasswordValid = await bcrypt.compare(passwordIngresada, cliente.ContrasenaHash);

    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Credenciales inválidas (Contraseña incorrecta).' });
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        id: cliente.IdCliente,
        dni: cliente.DNI,
        correo: cliente.Correo,
        role: 'cliente'
      },
      JWT_SECRET,
      { expiresIn: '8h' }
    );

    return res.status(200).json({
      message: 'Login de cliente exitoso.',
      token,
      cliente: {
        idCliente: cliente.IdCliente,
        dni: cliente.DNI,
        nombres: cliente.Nombres,
        apellidos: cliente.Apellidos,
        correo: cliente.Correo,
        telefono: cliente.Telefono,
        puntosFidelidad: cliente.PuntosFidelidad
      }
    });

  } catch (error) {
    console.error('Error in loginCliente:', error);
    return res.status(500).json({ error: 'Error interno del servidor en el login de cliente.' });
  }
};

// 3. Login Trabajador
const loginTrabajador = async (req, res) => {
  try {
    const { DNI, PinHash } = req.body;

    if (!DNI || !PinHash) {
      return res.status(400).json({ error: 'DNI y PinHash son obligatorios.' });
    }

    // Find worker by DNI
    const [rows] = await pool.promise().query(
      'SELECT * FROM Trabajador WHERE DNI = ?',
      [DNI]
    );

    if (rows.length === 0) {
      return res.status(401).json({ error: 'Personal no encontrado con este DNI.' });
    }

    const trabajador = rows[0];

    // Verify PIN (PinHash in DB is VARCHAR(4) as per schema)
    // We compare PinHash stored in DB directly with the provided pin (or if hashed, compare accordingly)
    // Supporting both direct match (schema standard for 4-char PIN) and bcrypt if stored hashed
    let isPinValid = false;
    if (trabajador.PinHash === PinHash) {
      isPinValid = true;
    } else if (trabajador.PinHash.startsWith('$2b$') || trabajador.PinHash.startsWith('$2a$')) {
      isPinValid = await bcrypt.compare(PinHash, trabajador.PinHash);
    }

    if (!isPinValid) {
      return res.status(401).json({ error: 'PIN incorrecto.' });
    }

    // Generate JWT token for trabajador
    const token = jwt.sign(
      {
        id: trabajador.IdTrabajador,
        dni: trabajador.DNI,
        rol: trabajador.Rol,
        role: 'trabajador'
      },
      JWT_SECRET,
      { expiresIn: '8h' }
    );

    return res.status(200).json({
      message: 'Login de trabajador exitoso.',
      token,
      trabajador: {
        idTrabajador: trabajador.IdTrabajador,
        dni: trabajador.DNI,
        nombres: trabajador.Nombres,
        apellidos: trabajador.Apellidos,
        rol: trabajador.Rol,
        correo: trabajador.Correo,
        telefono: trabajador.Telefono
      }
    });

  } catch (error) {
    console.error('Error in loginTrabajador:', error);
    return res.status(500).json({ error: 'Error interno del servidor en el login de trabajador.' });
  }
};

module.exports = {
  registerCliente,
  loginCliente,
  loginTrabajador
};
