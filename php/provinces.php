<?php
require 'connect.php';

// เพิ่ม CORS header เพื่ออนุญาตให้เรียก API ข้ามโดเมนได้
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

header("Content-Type: application/json");

$sql = "SELECT id, name_th FROM thai_provinces ORDER BY name_th ASC";
$result = mysqli_query($con, $sql);

$data = [];
if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
    }
    echo json_encode(['status' => 'success', 'data' => $data]);
} else {
    echo json_encode(['status' => 'error', 'message' => mysqli_error($con)]);
}

mysqli_close($con);
?>
