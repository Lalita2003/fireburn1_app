<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");  // อนุญาตทุก origin
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require "connect.php"; // ไฟล์เชื่อมต่อฐานข้อมูล (ต้องสร้าง $conn)

$request_id = $_POST['request_id'] ?? '';
$user_id   = $_POST['user_id'] ?? '';

if (empty($request_id) || empty($user_id)) {
    echo json_encode(["success" => false, "message" => "ข้อมูลไม่ครบ"]);
    exit;
}

$sql = "UPDATE burn_requests SET status='cancelled' WHERE id=? AND user_id=?";
$stmt = $con->prepare($sql);

if (!$stmt) {
    echo json_encode(["success" => false, "message" => "Prepare failed: " . $con->error]);
    exit;
}

$stmt->bind_param("ii", $request_id, $user_id);

if ($stmt->execute()) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "message" => $stmt->error]);
}

$stmt->close();
$con->close();
?>
