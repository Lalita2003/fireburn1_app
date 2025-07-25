<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// เช็ค method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

// เรียกใช้ไฟล์ connect.php เพื่อเชื่อมต่อฐานข้อมูล
require 'connect.php';

// รับข้อมูล POST
$input = $_POST;

// กำหนด fields ที่ต้องตรวจสอบว่าต้องไม่ว่าง (ไม่รวม agency)
$required = ['username', 'email', 'phone', 'village', 'province_id', 'district_id', 'subdistrict_id', 'password'];

// ตรวจสอบข้อมูลครบไหม
foreach ($required as $field) {
    if (empty($input[$field])) {
        echo json_encode(['status' => 'error', 'message' => "ข้อมูลไม่ครบถ้วน: $field"]);
        exit;
    }
}

// ตรวจสอบว่าถ้าไม่มี agency ให้ตั้งเป็นค่าว่าง
if (!isset($input['agency'])) {
    $input['agency'] = "";
}

// ตรวจสอบ email
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

// เพิ่มค่า created_at
$created_at = date('Y-m-d H:i:s');

// เพิ่มข้อมูลลงฐานข้อมูล
$stmt = $con->prepare("INSERT INTO users (username, email, phone, village, province_id, district_id, subdistrict_id, password, agency, role, created_at) 
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'user', ?)");
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

if ($stmt->execute()) {
    echo json_encode(['status' => 'success', 'message' => 'สมัครสมาชิกสำเร็จ']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'เกิดข้อผิดพลาดในการบันทึกข้อมูล']);
}

$stmt->close();
$con->close();
