<?php

class AuthController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    public function registerCliente($data) {
        $dni = $data['DNI'] ?? null;
        $nombres = $data['Nombres'] ?? null;
        $apellidos = $data['Apellidos'] ?? null;
        $correo = $data['Correo'] ?? null;
        $telefono = $data['Telefono'] ?? null;
        $password = $data['ContrasenaHash'] ?? ($data['Contrasena'] ?? null);

        if (!$dni || !$nombres || !$apellidos || !$correo || !$telefono || !$password) {
            http_response_code(400);
            echo json_encode(["error" => "Todos los campos son obligatorios (DNI, Nombres, Apellidos, Correo, Telefono, ContrasenaHash)."]);
            return;
        }

        if (strlen($dni) !== 8) {
            http_response_code(400);
            echo json_encode(["error" => "El DNI debe tener exactamente 8 caracteres."]);
            return;
        }

        if (strlen($telefono) !== 9) {
            http_response_code(400);
            echo json_encode(["error" => "El Teléfono debe tener exactamente 9 dígitos."]);
            return;
        }

        try {
            $stmt = $this->db->prepare("SELECT IdCliente FROM cliente WHERE DNI = ? OR Correo = ?");
            $stmt->execute([$dni, $correo]);
            if ($stmt->rowCount() > 0) {
                http_response_code(409);
                echo json_encode(["error" => "El cliente con este DNI o Correo ya se encuentra registrado."]);
                return;
            }

            $contrasenaHash = password_hash($password, PASSWORD_BCRYPT);

            $insert = $this->db->prepare("INSERT INTO cliente (DNI, Nombres, Apellidos, Correo, Telefono, ContrasenaHash, PuntosFidelidad) VALUES (?, ?, ?, ?, ?, ?, 0)");
            $insert->execute([$dni, $nombres, $apellidos, $correo, $telefono, $contrasenaHash]);

            $idCliente = $this->db->lastInsertId();

            http_response_code(201);
            echo json_encode([
                "message" => "Cliente registrado exitosamente.",
                "idCliente" => $idCliente,
                "cliente" => [
                    "dni" => $dni,
                    "nombres" => $nombres,
                    "apellidos" => $apellidos,
                    "correo" => $correo,
                    "telefono" => $telefono
                ]
            ]);

        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(["error" => "Error interno del servidor al registrar el cliente: " . $e->getMessage()]);
        }
    }

    public function loginCliente($data) {
        $correo = $data['Correo'] ?? null;
        $password = $data['ContrasenaHash'] ?? ($data['Contrasena'] ?? null);

        if (!$correo || !$password) {
            http_response_code(400);
            echo json_encode(["error" => "Correo y contraseña son obligatorios."]);
            return;
        }

        try {
            $stmt = $this->db->prepare("SELECT * FROM cliente WHERE Correo = ?");
            $stmt->execute([$correo]);
            
            if ($stmt->rowCount() === 0) {
                http_response_code(401);
                echo json_encode(["error" => "Credenciales inválidas"]);
                return;
            }

            $cliente = $stmt->fetch();
            $hashGuardado = $cliente['ContrasenaHash'];

            $esValido = password_verify($password, $hashGuardado) || ($password === $hashGuardado);

            if (!$esValido) {
                http_response_code(401);
                echo json_encode(["error" => "Credenciales inválidas"]);
                return;
            }

            http_response_code(200);
            echo json_encode([
                "message" => "Inicio de sesión exitoso",
                "cliente" => [
                    "idCliente" => $cliente['IdCliente'],
                    "dni" => $cliente['DNI'],
                    "nombres" => $cliente['Nombres'],
                    "apellidos" => $cliente['Apellidos'],
                    "correo" => $cliente['Correo'],
                    "telefono" => $cliente['Telefono'],
                    "puntosFidelidad" => $cliente['PuntosFidelidad']
                ]
            ]);

        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(["error" => "Error en el servidor al iniciar sesión: " . $e->getMessage()]);
        }
    }
}
?>
