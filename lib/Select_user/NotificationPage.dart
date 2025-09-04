import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'BurnHistoryPage.dart'; // ตรวจสอบ path ให้ถูกต้อง

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

  final String baseUrl = "http://localhost/flutter_fire/";

  @override
  void initState() {
    super.initState();
    fetchBurnRequestsAndNotify();
  }

  // ดึง burn requests และสร้าง/อัปเดต notification
  Future<void> fetchBurnRequestsAndNotify() async {
    try {
      final burnResp = await http.get(Uri.parse("${baseUrl}burn_request.php"));
      if (burnResp.statusCode == 200) {
        final dynamic burnJson = json.decode(burnResp.body);
        List<dynamic> burnData = [];

        if (burnJson is List) {
          burnData = burnJson;
        } else if (burnJson is Map) {
          if (burnJson['data'] is List) {
            burnData = burnJson['data'];
          } else {
            burnData = [burnJson];
          }
        }

        final filteredBurnData = burnData.where((item) {
          if (item is Map<String, dynamic> && item.containsKey('user_id')) {
            return item['user_id'].toString() == widget.userId.toString();
          }
          return false;
        }).toList();

        for (var requestRaw in filteredBurnData) {
          final Map<String, dynamic> request =
              Map<String, dynamic>.from(requestRaw);
          String title = "คำขอเผาในพื้นที่ ${request['area_name']}";
          String message =
              "คำขอเผาขนาด ${request['area_size']} ไร่ | พืช: ${request['crop_type']}";

          final checkResp = await http.get(Uri.parse(
              "${baseUrl}check_notification.php?user_id=${widget.userId}&title=${Uri.encodeComponent(title)}&message=${Uri.encodeComponent(message)}"));

          bool exists = false;
          if (checkResp.statusCode == 200) {
            final checkData = json.decode(checkResp.body);
            if (checkData is Map) exists = checkData['exists'] ?? false;
          }

          if (!exists) {
            await http.post(
              Uri.parse("${baseUrl}notifications.php"),
              body: {
                'user_id': widget.userId.toString(),
                'title': title,
                'message': message,
                'is_read': '0',
              },
            );
          }
        }

        await fetchNotifications();
      } else {
        setState(() {
          errorMessage =
              "โหลดข้อมูลคำขอไม่สำเร็จ (code ${burnResp.statusCode})";
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

  // ดึง notifications ของผู้ใช้
  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse("${baseUrl}get_notifications.php?user_id=${widget.userId}"),
      );

      if (response.statusCode == 200) {
        final dynamic jsonResp = json.decode(response.body);
        List<dynamic> data = [];

        if (jsonResp is List) {
          data = jsonResp;
        } else if (jsonResp is Map) {
          if (jsonResp['data'] is List)
            data = jsonResp['data'];
          else if (jsonResp['notifications'] is List)
            data = jsonResp['notifications'];
          else
            data = [jsonResp];
        }

        final filteredData = data.where((item) {
          if (item is Map<String, dynamic> && item.containsKey('user_id')) {
            return item['user_id'].toString() == widget.userId.toString();
          }
          return false;
        }).toList();

        notifications = filteredData.map<Map<String, dynamic>>((itemRaw) {
          final Map<String, dynamic> item = Map<String, dynamic>.from(itemRaw);
          return {
            'id': item['id'],
            'title': item['title'],
            'message': item['message'],
            'is_read': item['is_read'] ?? 0,
            'status': item['status']?.toString() ?? 'pending',
            'user_id': item['user_id'],
          };
        }).toList();

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              "โหลดการแจ้งเตือนไม่สำเร็จ (code ${response.statusCode})";
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

  // mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse("${baseUrl}mark_read.php"),
        body: {'id': notificationId.toString()},
      );
      if (response.statusCode == 200) {
        setState(() {
          final index =
              notifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) notifications[index]['is_read'] = 1;
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("การแจ้งเตือน"),
        centerTitle: true,
        backgroundColor: const Color(0xFFEF6C00),
        automaticallyImplyLeading: false, // ลบไอคอน Back
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
                        final n = notifications[index];
                        final isRead = n['is_read'] == 1;

                        return InkWell(
                          onTap: () async {
                            await markAsRead(n['id']);
                            // push แบบสามารถย้อนกลับมา NotificationPage ได้
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BurnHistoryPage(userId: widget.userId),
                              ),
                            );
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
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n['title'] ?? '-',
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
                                  n['message'] ?? '-',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isRead ? Colors.grey : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "สถานะ: ${_statusText(n['status'])}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor(n['status']),
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