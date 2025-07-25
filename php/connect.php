<?php
$db_name = "flutter_fire";
$db_user = "root";
$db_pass = "1234567"; // เปลี่ยนเป็นรหัสผ่านจริงของคุณ
$db_host = "localhost";

$con = mysqli_connect($db_host, $db_user, $db_pass, $db_name);

// ตรวจสอบการเชื่อมต่อ
if (!$con) {
    // แจ้ง error เป็น JSON แล้วหยุดสคริปต์
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'Connection failed: ' . mysqli_connect_error()]);
    exit();
}

// ไม่ต้อง echo อะไรถ้าเชื่อมต่อสำเร็จ
?>
