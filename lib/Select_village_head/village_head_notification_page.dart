import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'PendingRequestsPage.dart';

class VillageHeadNotificationPage extends StatefulWidget {
  final int userId;
  final String village;

  const VillageHeadNotificationPage({
    super.key,
    required this.userId,
    required this.village,
  });

  @override
  State<VillageHeadNotificationPage> createState() =>
      _VillageHeadNotificationPageState();
}

class _VillageHeadNotificationPageState
    extends State<VillageHeadNotificationPage> {
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? errorMessage;
  final String baseUrl = 'http://localhost/flutter_fire/';

  @override
  void initState() {
    super.initState();
    fetchPendingRequests();
  }

  Future<Map<int, String>> fetchUsersMap() async {
    try {
      final url = Uri.parse('${baseUrl}users.php');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['status'] == 'success') {
          final usersList =
              List<Map<String, dynamic>>.from(data['users'] ?? []);
          final map = <int, String>{};
          for (var u in usersList) {
            final id = int.tryParse(u['id'].toString()) ?? 0;
            final village = u['village']?.toString() ?? '';
            map[id] = village;
          }
          return map;
        }
      }
    } catch (_) {}
    return {};
  }

  Future<void> fetchPendingRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final usersMap = await fetchUsersMap();
      final url = Uri.parse('${baseUrl}burn_request.php?status=pending');
      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> allRequests = [];

        if (data is List) {
          allRequests = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['status'] == 'success') {
          allRequests = List<Map<String, dynamic>>.from(data['requests'] ?? []);
        }

        final filteredRequests = allRequests.where((req) {
          final userId = int.tryParse(req['user_id'].toString()) ?? 0;
          final userVillage =
              usersMap[userId]?.toString().trim().toLowerCase() ?? '';
          final myVillage = widget.village.toString().trim().toLowerCase();
          final status = req['status']?.toString().trim().toLowerCase() ?? '';
          return userVillage == myVillage && status == 'pending';
        }).toList();

        // สร้าง notification สำหรับคำขอใหม่
        await sendNotifications(filteredRequests);

        setState(() {
          requests = filteredRequests;
          isLoading = false;
          errorMessage = filteredRequests.isEmpty ? 'ไม่มีคำขอรออนุมัติ' : null;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage =
              'เกิดข้อผิดพลาด: Server ตอบกลับ ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  Future<void> sendNotifications(
      List<Map<String, dynamic>> filteredBurnData) async {
    try {
      // ดึง existing notifications ของผู้ใช้
      await fetchNotifications();
      final existingKeys = notifications.map((n) {
        return "${n['message']}_${n['status']}";
      }).toSet();

      for (var requestRaw in filteredBurnData) {
        final Map<String, dynamic> request =
            Map<String, dynamic>.from(requestRaw);
        String title = "คำขอเผาในพื้นที่ ${request['area_name']}";
        String message =
            "ขนาด ${request['area_size']} ไร่ | พืช: ${request['crop_type']}";
        String status = request['status']?.toString() ?? 'pending';

        String key = "${message}_$status";
        if (!existingKeys.contains(key)) {
          await http.post(
            Uri.parse("${baseUrl}notifications.php"),
            body: {
              'user_id': widget.userId.toString(),
              'title': title,
              'message': message,
              'status': status,
              'is_read': '0',
            },
          );
        }
      }

      // ดึง notifications ใหม่อีกครั้งเพื่ออัปเดต UI
      await fetchNotifications();
    } catch (e) {
      setState(() {
        errorMessage = "เกิดข้อผิดพลาด: $e";
        isLoading = false;
      });
    }
  }

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

        notifications = data.map<Map<String, dynamic>>((itemRaw) {
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
        title: const Text('แจ้งเตือนคำขอเผา'),
        centerTitle: true,
        backgroundColor: const Color(0xFFDD6B00),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: fetchPendingRequests,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final bool isRead = (notif['is_read'] ?? 0) == 1;

                      return Card(
                        color: isRead ? Colors.grey[300] : Colors.white,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(
                            Icons.notifications,
                            color:
                                isRead ? Colors.grey : const Color(0xFFEF6C00),
                          ),
                          title: Text(
                            notif['title'] ?? '-',
                            style: TextStyle(
                                color: isRead ? Colors.grey[700] : Colors.black,
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold),
                          ),
                          subtitle: Text(
                            notif['message'] ?? '-',
                            style: TextStyle(
                                color:
                                    isRead ? Colors.grey[700] : Colors.black),
                          ),
                          onTap: () async {
                            if (!isRead) {
                              await markAsRead(notif['id']);
                            }
                            // Navigate ไป PendingRequestsPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PendingRequestsPage(
                                  userId: widget.userId,
                                  village: widget.village,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
