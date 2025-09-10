<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require "connect.php"; // ตัวแปรเชื่อมต่อฐานข้อมูลเป็น $con

// รับข้อมูลจาก POST
$id = $_POST['id'] ?? null;
$status = $_POST['status'] ?? null;

if (!$id || !$status) {
    http_response_code(400);
    echo json_encode(["success" => false, "error" => "ข้อมูลไม่ครบถ้วน"]);
    exit;
}

// ตรวจสอบว่ามี notification ที่จะอัปเดตหรือไม่
$stmtCheck = $con->prepare("SELECT id FROM notifications WHERE id = ?");
$stmtCheck->bind_param("i", $id);
$stmtCheck->execute();
$stmtCheck->store_result();

if ($stmtCheck->num_rows === 0) {
    echo json_encode(["success" => false, "error" => "ไม่พบ notification"]);
    $stmtCheck->close();
    exit;
}
$stmtCheck->close();

// อัปเดต status + รีเซ็ต is_read = 0
$stmt = $con->prepare("UPDATE notifications SET status = ?, is_read = 0 WHERE id = ?");
$stmt->bind_param("si", $status, $id);

if ($stmt->execute()) {
    echo json_encode([
        "success" => true,
        "message" => "อัปเดต status สำเร็จ และรีเซ็ตเป็นยังไม่อ่าน"
    ]);
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "error" => "อัปเดต status ล้มเหลว"]);
}

$stmt->close();
$con->close();
?>
