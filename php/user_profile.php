<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json; charset=utf-8');

include 'connect.php';

if (!isset($_GET['id'])) {
    echo json_encode(['status' => 'error', 'message' => 'ไม่มีการส่ง userId มา']);
    exit();
}

$userId = intval($_GET['id']);

// JOIN เพื่อดึงชื่อจังหวัด อำเภอ ตำบล
$sql = "
SELECT 
    u.id, u.username, u.email, u.phone, u.village, u.agency, u.role,
    p.name_th AS province,
    a.name_th AS district,
    t.name_th AS subdistrict
FROM users u
LEFT JOIN thai_provinces p ON u.province_id = p.id
LEFT JOIN thai_amphures a ON u.district_id = a.id
LEFT JOIN thai_tambons t ON u.subdistrict_id = t.id
WHERE u.id = ?
";

$stmt = mysqli_prepare($con, $sql);
mysqli_stmt_bind_param($stmt, "i", $userId);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

if (!$result) {
    echo json_encode(['status' => 'error', 'message' => 'เกิดข้อผิดพลาดในการดึงข้อมูล']);
    exit();
}

if (mysqli_num_rows($result) == 0) {
    echo json_encode(['status' => 'error', 'message' => 'ไม่พบข้อมูลผู้ใช้']);
    exit();
}

$user = mysqli_fetch_assoc($result);

echo json_encode(['status' => 'success', 'user' => $user], JSON_UNESCAPED_UNICODE);

mysqli_stmt_close($stmt);
mysqli_close($con);
?>
