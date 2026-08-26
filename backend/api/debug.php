<?php
require_once '../config/db.php';

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

$correoSimulado = $_GET['correo'] ?? null;
$passSimulada = $_GET['pass'] ?? null;

if (!$correoSimulado || !$passSimulada) {
    echo json_encode([
        "error" => "Por favor provee los parametros GET 'correo' y 'pass' en la URL.",
        "ejemplo" => "debug.php?correo=jcornelios@gmail.com&pass=mi_contraseña"
    ]);
    exit();
}

try {
    // 1. Buscar usuario
    $stmt = $pdo->prepare("SELECT * FROM cliente WHERE Correo = :correo");
    $stmt->execute([':correo' => $correoSimulado]);
    
    if ($stmt->rowCount() === 0) {
        echo json_encode([
            "paso_1_buscar_usuario" => "Fallo",
            "error" => "No se encontro ningun cliente con el correo: $correoSimulado"
        ]);
        exit();
    }

    $usuario = $stmt->fetch();
    $hashGuardado = $usuario['ContrasenaHash'];

    // 2. Verificar contraseña
    $verificacionDirecta = ($passSimulada === $hashGuardado);
    $verificacionBcrypt = password_verify($passSimulada, $hashGuardado);

    echo json_encode([
        "correo_buscado" => $correoSimulado,
        "pass_ingresada" => $passSimulada,
        "usuario_encontrado" => [
            "IdCliente" => $usuario['IdCliente'],
            "Nombres" => $usuario['Nombres'],
            "Correo" => $usuario['Correo']
        ],
        "hash_en_bd" => $hashGuardado,
        "longitud_hash_en_bd" => strlen($hashGuardado),
        "comparacion_directa" => $verificacionDirecta,
        "verificacion_password_verify" => $verificacionBcrypt,
        "resultado_final_esValido" => ($verificacionBcrypt || $verificacionDirecta)
    ], JSON_PRETTY_PRINT);

} catch (PDOException $e) {
    echo json_encode(["error" => $e->getMessage()], JSON_PRETTY_PRINT);
}
?>
