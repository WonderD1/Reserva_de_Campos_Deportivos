<?php
header('Content-Type: application/json');
require_once '../config/db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["error" => "Método no permitido"]);
    exit();
}

$data = json_decode(file_get_contents('php://input'));

if (
    !empty($data->DNI) &&
    !empty($data->Nombres) &&
    !empty($data->Apellidos) &&
    !empty($data->Correo) &&
    !empty($data->Telefono) &&
    !empty($data->ContrasenaHash)
) {
    try {
        $checkQuery = "SELECT IdCliente FROM cliente WHERE Correo = :correo OR DNI = :dni";
        $checkStmt = $pdo->prepare($checkQuery);
        $checkStmt->execute([
            ':correo' => $data->Correo,
            ':dni' => $data->DNI
        ]);

        if ($checkStmt->rowCount() > 0) {
            http_response_code(409);
            echo json_encode(["error" => "El cliente con este DNI o Correo ya se encuentra registrado."]);
            exit();
        }

        $passwordHash = password_hash($data->ContrasenaHash, PASSWORD_BCRYPT);

        $query = "INSERT INTO cliente (DNI, Nombres, Apellidos, Correo, Telefono, ContrasenaHash, PuntosFidelidad) VALUES (:dni, :nombres, :apellidos, :correo, :telefono, :pass, 0)";
        $stmt = $pdo->prepare($query);

        $stmt->execute([
            ':dni' => $data->DNI,
            ':nombres' => $data->Nombres,
            ':apellidos' => $data->Apellidos,
            ':correo' => $data->Correo,
            ':telefono' => $data->Telefono,
            ':pass' => $passwordHash
        ]);

        http_response_code(201);
        echo json_encode([
            "message" => "Cliente registrado correctamente",
            "idCliente" => $pdo->lastInsertId()
        ]);

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["error" => $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["error" => "Todos los campos (DNI, Nombres, Apellidos, Correo, Telefono y ContrasenaHash) son obligatorios."]);
}
?>
