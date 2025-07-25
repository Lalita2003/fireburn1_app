<?php
require 'connect.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

$province_id = $_POST['province_id'] ?? $_GET['province_id'] ?? null;
if ($province_id === null) {
    echo json_encode(['status' => 'error', 'message' => 'Missing province_id']);
    exit();
}

$province_id = intval($province_id);

$sql = "SELECT id, name_th FROM thai_amphures WHERE province_id = ? ORDER BY name_th ASC";
$stmt = mysqli_prepare($con, $sql);
mysqli_stmt_bind_param($stmt, "i", $province_id);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

$data = [];
if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
    }
    echo json_encode(['status' => 'success', 'data' => $data]);
} else {
    echo json_encode(['status' => 'error', 'message' => mysqli_error($con)]);
}

mysqli_stmt_close($stmt);
mysqli_close($con);
?>
