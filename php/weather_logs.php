<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
require 'connect.php';

$burnRequestId = $_GET['burn_request_id'] ?? null;

if (!$burnRequestId) {
    echo json_encode([
        "status" => "error",
        "message" => "กรุณาระบุ burn_request_id"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

// Query เอาข้อมูล weather_logs ทั้งหมดของ burn_request_id
$sql = "
    SELECT id, burn_request_id, fetch_time, forecast_date, forecast_hour,
           temperature, humidity, wind_speed, boundary_height, pm25_model
    FROM weather_logs
    WHERE burn_request_id = ?
    ORDER BY forecast_hour ASC
";

$stmt = $con->prepare($sql);
$stmt->bind_param("i", $burnRequestId);
$stmt->execute();
$result = $stmt->get_result();

$weatherLogs = [];
while ($row = $result->fetch_assoc()) {
    $weatherLogs[] = $row;
}

if (!empty($weatherLogs)) {
    echo json_encode([
        "status" => "success",
        "weather_logs" => $weatherLogs
    ], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "ไม่พบข้อมูลสภาพอากาศ"
    ], JSON_UNESCAPED_UNICODE);
}
