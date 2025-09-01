<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
require "connect.php"; // ตัวแปรเชื่อมต่อเป็น $con

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$title = isset($_GET['title']) ? trim($_GET['title']) : '';
$message = isset($_GET['message']) ? trim($_GET['message']) : '';

if (!$con) {
    echo json_encode(["success" => false, "error" => "Database connection failed"]);
    exit;
}

if ($user_id <= 0 || empty($title) || empty($message)) {
    echo json_encode(["success" => false, "error" => "Missing required fields"]);
    exit;
}

$stmt = $con->prepare("SELECT id FROM notifications WHERE user_id = ? AND title = ? AND message = ?");
$stmt->bind_param("iss", $user_id, $title, $message);
$stmt->execute();
$stmt->store_result();

echo json_encode(["exists" => $stmt->num_rows > 0]);
?>
