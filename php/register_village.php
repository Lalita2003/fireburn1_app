<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// ตรวจสอบว่า method ต้องเป็น POST เท่านั้น
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

// เชื่อมต่อฐานข้อมูล
require 'connect.php';

// รับข้อมูลจาก POST
$input = $_POST;

// กำหนด fields ที่ต้องมี
$required = ['username', 'email', 'phone', 'village', 'province_id', 'district_id', 'subdistrict_id', 'password'];

// ตรวจสอบความครบถ้วนของข้อมูล
foreach ($required as $field) {
    if (empty($input[$field])) {
        echo json_encode(['status' => 'error', 'message' => "ข้อมูลไม่ครบถ้วน: $field"]);
        exit;
    }
}

// ถ้าไม่มี agency ให้กำหนดเป็นค่าว่าง
if (!isset($input['agency'])) {
    $input['agency'] = "";
}

// ตรวจสอบรูปแบบอีเมล
if (!filter_var($input['email'], FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['status' => 'error', 'message' => 'รูปแบบอีเมลไม่ถูกต้อง']);
    exit;
}

// ตรวจสอบ username หรือ email ซ้ำ
$stmt = $con->prepare("SELECT COUNT(*) FROM users WHERE username = ? OR email = ?");
$stmt->bind_param("ss", $input['username'], $input['email']);
$stmt->execute();
$stmt->bind_result($count);
$stmt->fetch();
$stmt->close();

if ($count > 0) {
    echo json_encode(['status' => 'error', 'message' => 'ชื่อผู้ใช้งานหรืออีเมลนี้ถูกใช้งานแล้ว']);
    exit;
}

// เข้ารหัสรหัสผ่าน
$hashedPassword = password_hash($input['password'], PASSWORD_BCRYPT);

// วันเวลาที่สมัคร
$created_at = date('Y-m-d H:i:s');

// สร้างคำสั่ง INSERT
$stmt = $con->prepare("INSERT INTO users (username, email, phone, village, province_id, district_id, subdistrict_id, password, agency, role, created_at)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'village_head', ?)");

$stmt->bind_param(
    "ssssiiisss",
    $input['username'],
    $input['email'],
    $input['phone'],
    $input['village'],
    $input['province_id'],
    $input['district_id'],
    $input['subdistrict_id'],
    $hashedPassword,
    $input['agency'],
    $created_at
);

// รันคำสั่ง SQL
if ($stmt->execute()) {
    echo json_encode(['status' => 'success', 'message' => 'สมัครผู้ใหญ่บ้านสำเร็จ']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'เกิดข้อผิดพลาดในการบันทึกข้อมูล']);
}

$stmt->close();
$con->close();
?>
