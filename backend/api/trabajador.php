<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["error" => "Método no permitido"]);
    exit();
}

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../controllers/TrabajadorController.php';

$database = new Database();
$db = $database->getConnection();

$trabajadorController = new TrabajadorController($db);

$inputData = json_decode(file_get_contents("php://input"), true);

if (!$inputData) {
    http_response_code(400);
    echo json_encode(["error" => "Datos JSON inválidos o vacíos"]);
    exit();
}

$trabajadorController->loginTrabajador($inputData);
?>