<?php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *"); 
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require "connect.php"; // เชื่อมต่อฐานข้อมูล

$input = json_decode(file_get_contents("php://input"), true);

// เขียน log สำหรับ debug
file_put_contents('log.txt', date('Y-m-d H:i:s') . " - " . json_encode($input) . "\n", FILE_APPEND);

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    if (
        isset($input["user_id"]) &&
        isset($input["area_name"]) &&
        isset($input["area_size"]) &&
        isset($input["location_lat"]) &&
        isset($input["location_lng"]) &&
        isset($input["request_date"]) &&
        isset($input["time_slot_from"]) &&
        isset($input["time_slot_to"]) &&
        isset($input["purpose"]) &&
        isset($input["crop_type"])
    ) {
        // สร้างคำขอเผา
        $sql = "INSERT INTO burn_requests 
                (user_id, area_name, area_size, location_lat, location_lng, request_date, time_slot_from, time_slot_to, purpose, crop_type, status) 
                VALUES (?,?,?,?,?,?,?,?,?,?,?)";

        $stmt = $con->prepare($sql);
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => "Prepare failed: " . $con->error]);
            exit();
        }

        $status = "pending";
        $stmt->bind_param(
            "isdddssssss",
            $input["user_id"],      
            $input["area_name"],    
            $input["area_size"],    
            $input["location_lat"], 
            $input["location_lng"], 
            $input["request_date"], 
            $input["time_slot_from"], 
            $input["time_slot_to"],   
            $input["purpose"],        
            $input["crop_type"],      
            $status                   
        );

        if ($stmt->execute()) {
            $burnRequestId = $stmt->insert_id;

            // อัปเดต weather_logs ที่ burn_request_id ยัง NULL สำหรับ forecast_date นี้
            $updateSql = "UPDATE weather_logs 
                          SET burn_request_id = ? 
                          WHERE burn_request_id IS NULL 
                          AND forecast_date = ?";
            $updateStmt = $con->prepare($updateSql);
            if ($updateStmt) {
                $updateStmt->bind_param(
                    "is",
                    $burnRequestId,
                    $input["request_date"]
                );
                $updateStmt->execute();
                $updateStmt->close();
            }

            echo json_encode([
                "success" => true,
                "message" => "Burn request created successfully and weather_logs updated",
                "id" => $burnRequestId
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                "success" => false,
                "message" => "Database error: " . $stmt->error
            ]);
        }

        $stmt->close();
    } else {
        http_response_code(400);
        echo json_encode(["error" => "Missing required fields"]);
    }
}

// GET: ดึงข้อมูลทั้งหมด
if ($_SERVER["REQUEST_METHOD"] === "GET") {
    $result = $con->query("SELECT * FROM burn_requests ORDER BY id DESC");
    $requests = [];
    while ($row = $result->fetch_assoc()) {
        $requests[] = $row;
    }
    echo json_encode($requests);
}

$con->close();
?>
