<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require "connect.php";

if (!$con) {
    echo json_encode(["status" => "error", "message" => "ไม่สามารถเชื่อมต่อ DB ได้"]);
    exit;
}

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($user_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Invalid user_id"]);
    exit;
}

// ดึง notifications
$sql = "SELECT id, title, message, is_read, COALESCE(status,'pending') as status, created_at 
        FROM notifications 
        WHERE user_id = ? 
        ORDER BY created_at DESC";

$stmt = $con->prepare($sql);
if (!$stmt) {
    echo json_encode(["status" => "error", "message" => "Prepare failed"]);
    exit;
}

$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$notifications = [];
while ($row = $result->fetch_assoc()) {
    $notifications[] = [
        "id" => (int)$row['id'],
        "user_id" => $user_id,
        "title" => $row['title'],
        "message" => $row['message'],
        "is_read" => (int)$row['is_read'],
        "status" => $row['status'],
        "created_at" => $row['created_at']
    ];
}

// ปิด statement
$stmt->close();

// ส่ง JSON
echo json_encode($notifications);
?>
