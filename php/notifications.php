<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
require "connect.php"; // ตัวแปรเชื่อมต่อเป็น $con

// รับค่า POST
$user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
$title = isset($_POST['title']) ? trim($_POST['title']) : '';
$message = isset($_POST['message']) ? trim($_POST['message']) : '';
$is_read = isset($_POST['is_read']) ? (int)$_POST['is_read'] : 0;

// ตรวจสอบการเชื่อมต่อ
if (!$con) {
    echo json_encode(["success" => false, "error" => "Database connection failed"]);
    exit;
}

// ตรวจสอบค่าที่จำเป็น
if ($user_id <= 0 || empty($title) || empty($message)) {
    echo json_encode(["success" => false, "error" => "Missing required fields"]);
    exit;
}

// ตรวจสอบว่าผู้ใช้มีอยู่จริง
$user_check = $con->prepare("SELECT id FROM users WHERE id = ?");
$user_check->bind_param("i", $user_id);
$user_check->execute();
$user_check->store_result();

if ($user_check->num_rows === 0) {
    echo json_encode(["success" => false, "error" => "User ID does not exist"]);
    exit;
}

// เตรียมคำสั่ง SQL
$stmt = $con->prepare("INSERT INTO notifications (user_id, title, message, is_read, created_at) VALUES (?, ?, ?, ?, NOW())");
if (!$stmt) {
    echo json_encode(["success" => false, "error" => $con->error]);
    exit;
}

// Bind parameter
$stmt->bind_param("issi", $user_id, $title, $message, $is_read);

// Execute
if ($stmt->execute()) {
    echo json_encode(["success" => true, "notification_id" => $stmt->insert_id]);
} else {
    echo json_encode(["success" => false, "error" => $stmt->error]);
}
?>
