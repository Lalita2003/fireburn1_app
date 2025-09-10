<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");  // อนุญาตทุก origin
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
require "connect.php"; // ไฟล์เชื่อมต่อฐานข้อมูล

// ตรวจสอบการเชื่อมต่อ
if ($con->connect_error) {
    echo json_encode([
        "status" => "error",
        "message" => "Connection failed: " . $con->connect_error
    ]);
    exit;
}

// ดึงผู้ใช้ทั้งหมด
$sql = "SELECT id, village FROM users WHERE role='user'";
$result = $con->query($sql);

$users = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $users[] = $row;
    }
}

echo json_encode([
    "status" => "success",
    "users" => $users
]);

$con->close();
?>
