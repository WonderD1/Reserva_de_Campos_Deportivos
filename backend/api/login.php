<?php
header("Content-Type: application/json");
require_once '../config/db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["error" => "Método no permitido"]);
    exit();
}

$data = json_decode(file_get_contents('php://input'));

$correo = $data->Correo ?? null;
$contrasenaHash = $data->ContrasenaHash ?? null;

if (!empty($correo) && !empty($contrasenaHash)) {
    try {
        $stmt = $pdo->prepare("SELECT * FROM cliente WHERE Correo = :correo");
        $stmt->execute([':correo' => $correo]);

        if ($stmt->rowCount() === 0) {
            http_response_code(401);
            echo json_encode(["error" => "Credenciales inválidas"]);
            exit();
        }

        $row = $stmt->fetch();

        $esValido = password_verify($contrasenaHash, $row['ContrasenaHash']) || ($contrasenaHash === $row['ContrasenaHash']);

        if (!$esValido) {
            http_response_code(401);
            echo json_encode(["error" => "Credenciales inválidas"]);
            exit();
        }

        unset($row['ContrasenaHash']);

        http_response_code(200);
        echo json_encode([
            "message" => "Inicio de sesión exitoso",
            "cliente" => $row
        ]);

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["error" => "Error en la base de datos: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["error" => "Correo y ContrasenaHash son obligatorios."]);
}
?>
