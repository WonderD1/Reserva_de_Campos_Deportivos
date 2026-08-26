<?php

class CajaController {
    private $db;

    public function __construct($db) {
        $this->db = $db;
    }

    // 1. REGISTRAR MOVIMIENTO (Apertura, Cierre, Ingreso o Gasto)
    public function registrarMovimiento($data) {
        $idTrabajador = $data['IdTrabajador'] ?? null;
        $tipoMovimiento = $data['TipoMovimiento'] ?? null; // 'Apertura', 'Cierre', 'Ingreso', 'Gasto'
        $importe = $data['Importe'] ?? null;
        $concepto = $data['Concepto'] ?? null;
        $idReserva = !empty($data['IdReserva']) ? $data['IdReserva'] : null;
        $idVenta = !empty($data['IdVenta']) ? $data['IdVenta'] : null;

        // Validaciones básicas
        if (!$idTrabajador || !$tipoMovimiento || !is_numeric($importe) || !$concepto) {
            http_response_code(400);
            echo json_encode(["error" => "Faltan datos obligatorios (IdTrabajador, TipoMovimiento, Importe, Concepto)."]);
            return;
        }

        // Validar que el tipo de movimiento sea correcto según la base de datos
        $tiposValidos = ['Apertura', 'Cierre', 'Ingreso', 'Gasto'];
        if (!in_array($tipoMovimiento, $tiposValidos)) {
            http_response_code(400);
            echo json_encode(["error" => "Tipo de movimiento no válido. Debe ser Apertura, Cierre, Ingreso o Gasto."]);
            return;
        }

        if ($importe < 0) {
            http_response_code(400);
            echo json_encode(["error" => "El importe no puede ser negativo."]);
            return;
        }

        try {
            // Insertar el movimiento en la base de datos
            $sql = "INSERT INTO MovimientoCaja (IdTrabajador, IdReserva, IdVenta, TipoMovimiento, Importe, Concepto) 
                    VALUES (?, ?, ?, ?, ?, ?)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$idTrabajador, $idReserva, $idVenta, $tipoMovimiento, $importe, $concepto]);

            $idMovimientoCaja = $this->db->lastInsertId();

            http_response_code(201);
            echo json_encode([
                "message" => "Movimiento de caja registrado exitosamente.",
                "idMovimientoCaja" => $idMovimientoCaja,
                "detalle" => [
                    "idTrabajador" => $idTrabajador,
                    "tipoMovimiento" => $tipoMovimiento,
                    "importe" => $importe,
                    "concepto" => $concepto
                ]
            ]);

        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(["error" => "Error interno del servidor al registrar el movimiento: " . $e->getMessage()]);
        }
    }

    // 2. CALCULAR EL CIERRE DE CAJA (Del turno / día actual)
    public function calcularCierreCaja($idTrabajador) {
        if (!$idTrabajador) {
            http_response_code(400);
            echo json_encode(["error" => "El IdTrabajador es obligatorio para calcular el cierre."]);
            return;
        }

        try {
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
                    WHERE IdTrabajador = ? 
                      AND DATE(FechaMovimiento) = CURDATE()";

            $stmt = $this->db->prepare($sql);
            $stmt->execute([$idTrabajador]);
            $resultado = $stmt->fetch();

            http_response_code(200);
            echo json_encode([
                "message" => "Cálculo de cierre de caja obtenido exitosamente.",
                "cierre" => $resultado
            ]);

        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(["error" => "Error en el servidor al calcular el cierre de caja: " . $e->getMessage()]);
        }
    }
}
?>