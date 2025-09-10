import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'PendingRequestsPage.dart'; // ใช้ Dialog ของ RequestDetailContent

class VillageBurnHistoryPage extends StatefulWidget {
  final int userId;
  final String village;

  const VillageBurnHistoryPage(
      {super.key, required this.userId, required this.village});

  @override
  State<VillageBurnHistoryPage> createState() => _VillageBurnHistoryPageState();
}

class _VillageBurnHistoryPageState extends State<VillageBurnHistoryPage> {
  List<Map<String, dynamic>> historyRequests = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchHistoryRequests();
  }

  Future<Map<int, String>> fetchUsersMap() async {
    try {
      final url = Uri.parse('http://localhost/flutter_fire/users.php');
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

  Future<void> fetchHistoryRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final usersMap = await fetchUsersMap();
      final url = Uri.parse('http://localhost/flutter_fire/burn_request.php');
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

        // กรองตามหมู่บ้านและสถานะ approved/rejected
        final filtered = allRequests.where((req) {
          final userId = int.tryParse(req['user_id'].toString()) ?? 0;
          final userVillage = usersMap[userId]?.toLowerCase().trim() ?? '';
          final myVillage = widget.village.toLowerCase().trim();
          final status = req['status']?.toString().toLowerCase() ?? '';
          return userVillage == myVillage &&
              (status == 'approved' || status == 'rejected');
        }).toList();

        setState(() {
          historyRequests = filtered;
          isLoading = false;
          errorMessage = filtered.isEmpty ? 'ไม่มีประวัติคำขอ' : null;
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

  void showRequestDetail(Map<String, dynamic> req) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.85,
          child: RequestDetailContent(
            requestData: req,
            villageHeadId: widget.userId,
          ),
        ),
      ),
    );

    if (result == true) fetchHistoryRequests();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติคำขอเผา'),
        backgroundColor: const Color(0xFFDD6B00),
      ),
      body: RefreshIndicator(
        onRefresh: fetchHistoryRequests,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(errorMessage!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: historyRequests.length,
                    itemBuilder: (context, index) {
                      final req = historyRequests[index];
                      final status = req['status']?.toString() ?? 'pending';
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.fireplace,
                                      color: getStatusColor(status)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      req['area_name'] ?? 'พื้นที่ไม่ระบุ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text("ขนาด: ${req['area_size'] ?? '-'} ไร่"),
                              const SizedBox(height: 4),
                              Text("สถานะ: $status",
                                  style: TextStyle(
                                      color: getStatusColor(status),
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "หมายเหตุ: ${req['approval_note'] ?? '-'}",
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
