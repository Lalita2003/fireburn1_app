<?php
header("Access-Control-Allow-Origin: *");
header('Content-Type: application/json; charset=utf-8');
require_once "connect.php";

$burn_request_id = isset($_GET['burn_request_id']) ? intval($_GET['burn_request_id']) : 0;

try {
    if ($burn_request_id > 0) {
        $sql = "
            SELECT w.forecast_date, w.forecast_hour
            FROM weather_logs w
            JOIN burn_requests b ON w.burn_request_id = b.id
            WHERE w.burn_request_id = $burn_request_id
              AND b.status != 'cancelled'
        ";
    } else {
        $sql = "
            SELECT w.forecast_date, w.forecast_hour
            FROM weather_logs w
            JOIN burn_requests b ON w.burn_request_id = b.id
            WHERE b.status != 'cancelled'
        ";
    }

    $result = mysqli_query($con, $sql);
    if (!$result) throw new Exception(mysqli_error($con));

    $hours = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $hours[] = [
            'forecast_date' => $row['forecast_date'],
            'forecast_hour' => $row['forecast_hour'],
        ];
    }

    echo json_encode(['status' => 'success', 'data' => $hours], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>
