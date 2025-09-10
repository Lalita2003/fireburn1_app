<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
require "connect.php"; // ตัวแปรเชื่อมต่อเป็น $con

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$title = isset($_GET['title']) ? trim($_GET['title']) : '';
$message = isset($_GET['message']) ? trim($_GET['message']) : '';
$status = isset($_GET['status']) ? trim($_GET['status']) : '';

if (!$con) {
    echo json_encode(["success" => false, "error" => "Database connection failed"]);
    exit;
}

if ($user_id <= 0 || empty($title) || empty($message) || empty($status)) {
    echo json_encode(["success" => false, "error" => "Missing required fields"]);
    exit;
}

// ตรวจสอบว่ามี notification อยู่แล้วสำหรับ status ปัจจุบัน
$stmt = $con->prepare("SELECT id FROM notifications WHERE user_id = ? AND title = ? AND message = ? AND status = ? LIMIT 1");
$stmt->bind_param("isss", $user_id, $title, $message, $status);
$stmt->execute();
$stmt->store_result();
$stmt->bind_result($notifId);

$exists = false;
if ($stmt->num_rows > 0) {
    $exists = true;
    $stmt->fetch();
}

echo json_encode(["exists" => $exists, "id" => $notifId ?? null]);
$stmt->close();
?>
