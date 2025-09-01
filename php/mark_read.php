<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
require "connect.php"; // ตัวแปรเชื่อมต่อเป็น $con

// รับค่า POST
$notification_id = isset($_POST['id']) ? (int)$_POST['id'] : 0;

// ตรวจสอบการเชื่อมต่อ
if (!$con) {
    echo json_encode([
        "success" => false,
        "error" => "Database connection failed"
    ]);
    exit;
}

// ตรวจสอบค่า
if ($notification_id <= 0) {
    echo json_encode([
        "success" => false,
        "error" => "Invalid notification ID"
    ]);
    exit;
}

// ตรวจสอบว่า notification มีอยู่จริง
$stmtCheck = $con->prepare("SELECT id, is_read FROM notifications WHERE id = ?");
$stmtCheck->bind_param("i", $notification_id);
$stmtCheck->execute();
$resultCheck = $stmtCheck->get_result();

if ($resultCheck->num_rows === 0) {
    echo json_encode([
        "success" => false,
        "error" => "Notification not found"
    ]);
    exit;
}

// อัปเดต is_read เป็น 1
$stmtUpdate = $con->prepare("UPDATE notifications SET is_read = 1 WHERE id = ?");
$stmtUpdate->bind_param("i", $notification_id);

if ($stmtUpdate->execute()) {
    echo json_encode([
        "success" => true,
        "message" => "Notification marked as read",
        "notification_id" => $notification_id
    ]);
} else {
    echo json_encode([
        "success" => false,
        "error" => $stmtUpdate->error
    ]);
}
?>
