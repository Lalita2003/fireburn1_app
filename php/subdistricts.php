<?php
require 'connect.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

$amphure_id = $_POST['amphure_id'] ?? $_GET['amphure_id'] ?? null;
if ($amphure_id === null) {
    echo json_encode(['status' => 'error', 'message' => 'Missing amphure_id']);
    exit();
}

$amphure_id = intval($amphure_id);

$sql = "SELECT id, name_th FROM thai_tambons WHERE amphure_id = ? ORDER BY name_th ASC";
$stmt = mysqli_prepare($con, $sql);
mysqli_stmt_bind_param($stmt, "i", $amphure_id);
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
