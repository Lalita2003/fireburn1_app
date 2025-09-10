<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require "connect.php";

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['request_id'], $data['status'], $data['approved_by'])) {
    echo json_encode(["status" => "error", "message" => "Missing parameters"]);
    exit;
}

$request_id = intval($data['request_id']);
$status = $data['status'] === "approved" ? "approved" : "rejected";
$approved_by = intval($data['approved_by']);
$approval_note = $data['approval_note'] ?? null;

$sql = "UPDATE burn_requests 
        SET status = ?, 
            approved_by = ?, 
            approved_at = NOW(), 
            approval_note = ?
        WHERE id = ?";

$stmt = $con->prepare($sql);
$stmt->bind_param("sisi", $status, $approved_by, $approval_note, $request_id);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Updated successfully"]);
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}

$stmt->close();
$con->close();
