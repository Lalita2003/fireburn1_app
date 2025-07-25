<?php
require "connect.php";

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

if (!$con) {
    echo json_encode(['status' => 'error', 'message' => 'Connection failed']);
    exit();
}

// รับค่าจาก Flutter
$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

if (empty($email) || empty($password)) {
    echo json_encode(['status' => 'error', 'message' => 'Email and password required']);
    exit();
}

// ดึงข้อมูลผู้ใช้จากฐานข้อมูล
$sql = "SELECT * FROM users WHERE email = '$email'";
$result = mysqli_query($con, $sql);

if (mysqli_num_rows($result) == 1) {
    $user = mysqli_fetch_assoc($result);

    // ตรวจสอบรหัสผ่าน (ใช้ password_verify กับ password_hash ในฐานข้อมูล)
    if (password_verify($password, $user['password'])) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Login successful',
            'user' => [
                'id' => $user['id'],
                'username' => $user['username'],
                'email' => $user['email'],
                'role' => $user['role'],
            ]
        ]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Incorrect password']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'User not found']);
}
?>
