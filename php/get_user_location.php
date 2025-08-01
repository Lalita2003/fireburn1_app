<?php
// get_user_location.php
header("Content-Type: application/json");

require "connect.php";

$user_id = $_GET['user_id'] ?? 0;
$user_id = intval($user_id);

if ($user_id <= 0) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid user_id']);
    exit;
}

$sql = "SELECT u.id, u.username, u.email, 
        p.name_th AS province_name,
        d.name_th AS district_name,
        s.name_th AS subdistrict_name
        FROM users u
        LEFT JOIN thai_provinces p ON u.province_id = p.id
        LEFT JOIN thai_amphures d ON u.district_id = d.id
        LEFT JOIN thai_tambons s ON u.subdistrict_id = s.id
        WHERE u.id = ?";

$stmt = $con->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(['status' => 'error', 'message' => 'User not found']);
    exit;
}

$data = $result->fetch_assoc();
echo json_encode(['status' => 'success', 'data' => $data]);
