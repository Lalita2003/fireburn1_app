import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationPage extends StatefulWidget {
  final int userId;

  const NotificationPage({super.key, required this.userId});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  final String baseUrl =
      "http://localhost/flutter_fire/"; // เปลี่ยนเป็น IP เครื่อง Dev

  @override
  void initState() {
    super.initState();
    fetchRequestsAndNotify();
  }

  // Fetch คำขอเผาและสร้าง Notification
  Future<void> fetchRequestsAndNotify() async {
    try {
      final response = await http.get(Uri.parse("${baseUrl}burn_request.php"));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        notifications = data.map<Map<String, dynamic>>((request) {
          return {
            'id': 0, // จะอัปเดตเป็น id จริงหลังจากบันทึก Notification
            'area_name': request['area_name'] ?? '-',
            'area_size': request['area_size'] ?? '-',
            'crop_type': request['crop_type'] ?? '-',
            'request_date': request['request_date'] ?? '-',
            'status': request['status'] ?? 'pending',
            'is_read': 0,
          };
        }).toList();

        // ส่ง Notification สำหรับแต่ละรายการ และอัปเดต id จริง
        for (var i = 0; i < notifications.length; i++) {
          var request = notifications[i];
          int? notifId = await addNotification(
            userId: widget.userId,
            title: "คำขอเผาในพื้นที่ ${request['area_name']}",
            message:
                "คำขอเผาขนาด ${request['area_size']} ไร่ | พืช: ${request['crop_type']}",
          );

          if (notifId != null) {
            notifications[i]['id'] = notifId; // อัปเดต id จริงจาก DB
          }
        }

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "โหลดข้อมูลไม่สำเร็จ (code ${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "เกิดข้อผิดพลาด: $e";
        isLoading = false;
      });
    }
  }

  // ส่ง Notification พร้อมเช็กซ้ำ และรับ id ของ Notification จริง
  Future<int?> addNotification({
    required int userId,
    required String title,
    required String message,
  }) async {
    try {
      // เช็กว่ามี Notification ซ้ำหรือไม่
      final checkResponse = await http.get(Uri.parse(
          "${baseUrl}check_notification.php?user_id=$userId&title=${Uri.encodeComponent(title)}&message=${Uri.encodeComponent(message)}"));

      if (checkResponse.statusCode == 200) {
        final data = json.decode(checkResponse.body);
        bool exists = data['exists'] ?? false;
        if (exists) return null;
      }

      // เพิ่ม Notification ลงฐานข้อมูล
      final response = await http.post(
        Uri.parse("${baseUrl}notifications.php"),
        body: {
          'user_id': userId.toString(),
          'title': title,
          'message': message,
          'is_read': '0',
        },
      );

      if (response.statusCode == 200) {
        final respData = json.decode(response.body);
        return respData['notification_id']; // รับ id ของ Notification
      } else {
        print("บันทึก notification ไม่สำเร็จ: ${response.body}");
        return null;
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดตอนบันทึก notification: $e");
      return null;
    }
  }

  // ฟังก์ชันอัปเดต is_read
  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}mark_read.php"),
        body: {'id': notificationId.toString()},
      );
      if (response.statusCode == 200) {
        print("Marked as read: $notificationId");
      } else {
        print("Failed to mark as read: ${response.body}");
      }
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('การแจ้งเตือน'),
        centerTitle: true,
        backgroundColor: const Color(0xFFEF6C00),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : notifications.isEmpty
                  ? const Center(child: Text("ยังไม่มีการแจ้งเตือน"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final isRead = notification['is_read'] == 1;

                        return InkWell(
                          onTap: () async {
                            if (!isRead) {
                              await markAsRead(notification['id']);
                              setState(() {
                                notifications[index]['is_read'] = 1;
                              });
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin:
                                        const EdgeInsets.only(top: 6, right: 8),
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                else
                                  const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "คำขอเผาในพื้นที่ ${notification['area_name']}",
                                        style: TextStyle(
                                          fontWeight: isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                          fontSize: 16,
                                          color: isRead
                                              ? Colors.grey[700]
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "วันที่: ${notification['request_date']}\n"
                                        "ขนาด: ${notification['area_size']} ไร่ | "
                                        "พืช: ${notification['crop_type']}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isRead
                                              ? Colors.grey
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "สถานะ: ${_statusText(notification['status'])}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _statusColor(
                                              notification['status']),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  String _statusText(String? status) {
    switch (status) {
      case 'approved':
        return '✅ อนุมัติแล้ว';
      case 'pending':
        return '⏳ รอดำเนินการ';
      case 'rejected':
        return '❌ ถูกปฏิเสธ';
      case 'cancelled':
        return '🚫 ยกเลิก';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.grey;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }
}
