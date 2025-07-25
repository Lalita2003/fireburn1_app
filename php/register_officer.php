<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// เช็ค method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

// เชื่อมต่อฐานข้อมูล
require "connect.php";

if (!$con) {
    echo json_encode(['status' => 'error', 'message' => 'Connection failed']);
    exit();
}

$input = $_POST;

// ฟิลด์ที่ต้องมี (สำหรับเจ้าหน้าที่)
$required_fields = ['username', 'email', 'phone', 'province_id', 'district_id', 'subdistrict_id', 'password'];

// ตรวจสอบข้อมูลครบถ้วน
foreach ($required_fields as $field) {
    if (empty($input[$field])) {
        echo json_encode(['status' => 'error', 'message' => "ข้อมูลไม่ครบถ้วน: $field"]);
        exit;
    }
}

// กำหนดค่า agency ถ้าไม่มี
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

// เวลาปัจจุบัน
$created_at = date('Y-m-d H:i:s');

$role = 'officer';

// เตรียม insert
$stmt = $con->prepare("INSERT INTO users (username, email, phone, village, province_id, district_id, subdistrict_id, password, agency, role, created_at) 
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

// กำหนดค่า village (ถ้าไม่มีตั้งว่าง)
$village = $input['village'] ?? "";

$stmt->bind_param(
    "sssiiisssss",
    $input['username'],
    $input['email'],
    $input['phone'],
    $village,
    $input['province_id'],
    $input['district_id'],
    $input['subdistrict_id'],
    $hashedPassword,
    $input['agency'],
    $role,
    $created_at
);

if ($stmt->execute()) {
    echo json_encode(['status' => 'success', 'message' => 'สมัครสมาชิกเจ้าหน้าที่สำเร็จ']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'เกิดข้อผิดพลาดในการบันทึกข้อมูล']);
}

$stmt->close();
$con->close();
?>
