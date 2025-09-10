<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");  // อนุญาตทุก origin
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
require "connect.php"; // ไฟล์เชื่อมต่อฐานข้อมูล

if (!isset($_GET['user_id'])) {
    echo json_encode(["status" => "error", "message" => "Missing user_id"]);
    exit;
}

$userId = intval($_GET['user_id']);

// 1. ตรวจสอบว่าผู้ใช้เป็นผู้ใหญ่บ้าน
$sql = "SELECT village, role FROM users WHERE id = ?";
$stmt = $con->prepare($sql);
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(["status" => "error", "message" => "User not found"]);
    exit;
}

$userData = $result->fetch_assoc();
if ($userData['role'] !== 'village_head') {
    echo json_encode(["status" => "error", "message" => "Not a village head"]);
    exit;
}

$village = $userData['village'];

// 2. ดึงจำนวนผู้ใช้ในหมู่บ้านเดียวกัน
$sql_users = "SELECT COUNT(*) AS total_users FROM users WHERE village = ? AND role = 'user'";
$stmt_users = $con->prepare($sql_users);
$stmt_users->bind_param("s", $village);
$stmt_users->execute();
$result_users = $stmt_users->get_result();
$total_users = $result_users->fetch_assoc()['total_users'] ?? 0;

// 3. ดึงสรุปคำขอเผา วันนี้ + ล่วงหน้า 7 วัน
$sql_today = "
    SELECT 
        SUM(CASE WHEN br.status = 'pending' THEN 1 ELSE 0 END) AS pending,
        SUM(CASE WHEN br.status = 'approved' THEN 1 ELSE 0 END) AS approved,
        SUM(CASE WHEN br.status = 'rejected' THEN 1 ELSE 0 END) AS rejected,
        SUM(CASE WHEN br.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled
    FROM burn_requests br
    JOIN users u ON br.user_id = u.id
    WHERE u.village = ? 
      AND DATE(br.request_date) BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
";
$stmt_today = $con->prepare($sql_today);
$stmt_today->bind_param("s", $village);
$stmt_today->execute();
$today_data = $stmt_today->get_result()->fetch_assoc();

// 4. ดึงสรุปคำขอเผา เดือนนี้
$sql_month = "
    SELECT 
        SUM(CASE WHEN br.status = 'pending' THEN 1 ELSE 0 END) AS pending,
        SUM(CASE WHEN br.status = 'approved' THEN 1 ELSE 0 END) AS approved,
        SUM(CASE WHEN br.status = 'rejected' THEN 1 ELSE 0 END) AS rejected,
        SUM(CASE WHEN br.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled
    FROM burn_requests br
    JOIN users u ON br.user_id = u.id
    WHERE u.village = ? 
      AND MONTH(br.request_date) = MONTH(CURDATE())
      AND YEAR(br.request_date) = YEAR(CURDATE())
";
$stmt_month = $con->prepare($sql_month);
$stmt_month->bind_param("s", $village);
$stmt_month->execute();
$month_data = $stmt_month->get_result()->fetch_assoc();

// 5. ส่งผลลัพธ์กลับเป็น JSON
echo json_encode([
    "status" => "success",
    "village" => $village,
    "total_users" => intval($total_users),
    "today" => [
        "pending"  => intval($today_data['pending'] ?? 0),
        "approved" => intval($today_data['approved'] ?? 0),
        "rejected" => intval($today_data['rejected'] ?? 0),
        "cancelled"=> intval($today_data['cancelled'] ?? 0),
    ],
    "month" => [
        "pending"  => intval($month_data['pending'] ?? 0),
        "approved" => intval($month_data['approved'] ?? 0),
        "rejected" => intval($month_data['rejected'] ?? 0),
        "cancelled"=> intval($month_data['cancelled'] ?? 0),
    ]
], JSON_UNESCAPED_UNICODE);

$con->close();
