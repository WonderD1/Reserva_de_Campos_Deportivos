<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["error" => "Método no permitido"]);
    exit();
}

require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../controllers/ClienteController.php';

$database = new Database();
$db = $database->getConnection();

$clienteController = new ClienteController($db);

$idCliente = $_GET['idCliente'] ?? null;

$clienteController->obtenerPerfil($idCliente);
?>