<?php
header("Access-Control-Allow-Origin: *");
header('Content-Type: application/json; charset=utf-8');
require_once "connect.php"; // ตรวจสอบ path ให้ถูกต้อง

try {
    // ดึงชั่วโมงทั้งหมดที่ถูกเลือกแล้ว
    $sql = "SELECT forecast_date, forecast_hour FROM weather_logs";
    $result = mysqli_query($con, $sql);

    if (!$result) {
        throw new Exception("Query failed: " . mysqli_error($con));
    }

    $hours = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $hours[] = [
            'forecast_date' => $row['forecast_date'], // YYYY-MM-DD
            'forecast_hour' => $row['forecast_hour'], // HH:00:00
        ];
    }

    echo json_encode([
        'status' => 'success',
        'data' => $hours
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
