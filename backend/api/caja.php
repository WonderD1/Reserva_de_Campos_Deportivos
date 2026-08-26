<?php
// Incluimos la conexión a la base de datos (asegúrate de que conexion.php esté en la misma carpeta)
require_once 'conexion.php';

// Verificamos qué acción está solicitando la interfaz de caja
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $accion = $_POST['accion'] ?? '';
    
    // Suponemos que el IdTrabajador viene de la sesión activa o del formulario
    $idTrabajador = $_POST['id_trabajador'] ?? null; 

    if (!$idTrabajador) {
        echo json_encode(["status" => "error", "mensaje" => "No se identificó al trabajador."]);
        exit();
    }

    try {
        switch ($accion) {
            
            // 1. REGISTRAR APERTURA DE CAJA
            case 'abrir':
                $montoInicial = $_POST['monto_inicial'] ?? 0;
                
                $sql = "INSERT INTO MovimientoCaja (IdTrabajador, TipoMovimiento, Importe, Concepto) 
                        VALUES (:idTrabajador, 'Apertura', :montoInicial, 'Fondo inicial de caja')";
                $stmt = $pdo->prepare($sql);
                $stmt->execute([
                    ':idTrabajador' => $idTrabajador,
                    ':montoInicial' => $montoInicial
                ]);
                
                echo json_encode(["status" => "success", "mensaje" => "Caja abierta correctamente."]);
                break;

            // 2. REGISTRAR INGRESO (por venta o reserva) o GASTO
            case 'registrar_movimiento':
                $tipoMovimiento = $_POST['tipo_movimiento']; // 'Ingreso' o 'Gasto'
                $importe = $_POST['importe'];
                $concepto = $_POST['concepto'];
                $idReserva = !empty($_POST['id_reserva']) ? $_POST['id_reserva'] : null;
                $idVenta = !empty($_POST['id_venta']) ? $_POST['id_venta'] : null;

                $sql = "INSERT INTO MovimientoCaja (IdTrabajador, IdReserva, IdVenta, TipoMovimiento, Importe, Concepto) 
                        VALUES (:idTrabajador, :idReserva, :idVenta, :tipoMovimiento, :importe, :concepto)";
                
                $stmt = $pdo->prepare($sql);
                $stmt->execute([
                    ':idTrabajador'   => $idTrabajador,
                    ':idReserva'      => $idReserva,
                    ':idVenta'        => $idVenta,
                    ':tipoMovimiento' => $tipoMovimiento,
                    ':importe'        => $importe,
                    ':concepto'       => $concepto
                ]);

                echo json_encode(["status" => "success", "mensaje" => "Movimiento de caja registrado con éxito."]);
                break;

            // 3. CALCULAR EL CIERRE DE CAJA (Cálculo matemático del turno)
            case 'calcular_cierre':
                $sql = "SELECT 
                            COALESCE(SUM(CASE WHEN TipoMovimiento = 'Apertura' THEN Importe ELSE 0 END), 0) AS MontoInicial,
                            COALESCE(SUM(CASE WHEN TipoMovimiento = 'Ingreso' THEN Importe ELSE 0 END), 0) AS TotalIngresos,
                            COALESCE(SUM(CASE WHEN TipoMovimiento = 'Gasto' THEN Importe ELSE 0 END), 0) AS TotalGastos,
                            (
                                COALESCE(SUM(CASE WHEN TipoMovimiento = 'Apertura' THEN Importe ELSE 0 END), 0) +
                                COALESCE(SUM(CASE WHEN TipoMovimiento = 'Ingreso' THEN Importe ELSE 0 END), 0) -
                                COALESCE(SUM(CASE WHEN TipoMovimiento = 'Gasto' THEN Importe ELSE 0 END), 0)
                            ) AS SaldoFinalEsperado
                        FROM MovimientoCaja
                        WHERE IdTrabajador = :idTrabajador 
                          AND DATE(FechaMovimiento) = CURDATE()";
                          
                $stmt = $pdo->prepare($sql);
                $stmt->execute([':idTrabajador' => $idTrabajador]);
                $resultado = $stmt->fetch(PDO::FETCH_ASSOC);

                echo json_encode(["status" => "success", "data" => $resultado]);
                break;

            // 4. REGISTRAR CIERRE DE CAJA (Guarda el movimiento de cierre definitivo)
            case 'cerrar_caja':
                $montoFinalReal = $_POST['monto_final_real'] ?? 0;
                
                $sql = "INSERT INTO MovimientoCaja (IdTrabajador, TipoMovimiento, Importe, Concepto) 
                        VALUES (:idTrabajador, 'Cierre', :montoFinalReal, 'Cierre de caja y turno')";
                $stmt = $pdo->prepare($sql);
                $stmt->execute([
                    ':idTrabajador'   => $idTrabajador,
                    ':montoFinalReal' => $montoFinalReal
                ]);

                echo json_encode(["status" => "success", "mensaje" => "Caja cerrada y registrada con éxito."]);
                break;

            default:
                echo json_encode(["status" => "error", "mensaje" => "Acción no válida."]);
                break;
        }

    } catch (PDOException $e) {
        echo json_encode(["status" => "error", "mensaje" => "Error en la base de datos: " . $e->getMessage()]);
    }
}
?>