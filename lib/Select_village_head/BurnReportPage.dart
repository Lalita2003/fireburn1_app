import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BurnReportPage extends StatefulWidget {
  final int userId;
  final String village;

  const BurnReportPage(
      {super.key, required this.userId, required this.village});

  @override
  State<BurnReportPage> createState() => _BurnReportPageState();
}

class _BurnReportPageState extends State<BurnReportPage> {
  List<Map<String, dynamic>> burnRequests = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedMonth; // เดือนที่เลือก

  @override
  void initState() {
    super.initState();
    fetchBurnRequests();
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

  Future<void> fetchBurnRequests() async {
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

        final filtered = allRequests.where((req) {
          final userId = int.tryParse(req['user_id'].toString()) ?? 0;
          final userVillage = usersMap[userId]?.toLowerCase().trim() ?? '';
          final myVillage = widget.village.toLowerCase().trim();
          return userVillage == myVillage;
        }).toList();

        setState(() {
          burnRequests = filtered;
          isLoading = false;
          errorMessage = filtered.isEmpty ? 'ไม่มีข้อมูลคำขอเผา' : null;
          selectedMonth ??= getAvailableMonths().firstOrNull;
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

  List<String> getAvailableMonths() {
    final months = burnRequests
        .map((req) {
          final dateStr = req['request_date']?.toString() ?? '';
          try {
            final date = DateTime.parse(dateStr);
            return DateFormat('yyyy-MM').format(date);
          } catch (_) {
            return null;
          }
        })
        .whereType<String>()
        .toSet()
        .toList();
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  List<Map<String, dynamic>> getRequestsByMonth(String month) {
    return burnRequests.where((req) {
      final dateStr = req['request_date']?.toString() ?? '';
      try {
        final date = DateTime.parse(dateStr);
        final monthKey = DateFormat('yyyy-MM').format(date);
        return monthKey == month;
      } catch (_) {
        return false;
      }
    }).toList();
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
    final availableMonths = getAvailableMonths();
    final monthRequests =
        selectedMonth != null ? getRequestsByMonth(selectedMonth!) : [];

    final approvedArea = monthRequests
        .where((r) => r['status']?.toString().toLowerCase() == 'approved')
        .fold(
            0.0,
            (prev, r) =>
                prev +
                (double.tryParse(r['area_size']?.toString() ?? '0') ?? 0.0));
    final rejectedArea = monthRequests
        .where((r) => r['status']?.toString().toLowerCase() == 'rejected')
        .fold(
            0.0,
            (prev, r) =>
                prev +
                (double.tryParse(r['area_size']?.toString() ?? '0') ?? 0.0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานพื้นที่เผา'),
        backgroundColor: const Color(0xFFDD6B00),
      ),
      body: RefreshIndicator(
        onRefresh: fetchBurnRequests,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(errorMessage!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 16)))
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      // ======= เลือกเดือน =======
                      Card(
                        color: Colors.orange.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('เลือกเดือน',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                isExpanded: true,
                                value: selectedMonth,
                                items: availableMonths
                                    .map((m) => DropdownMenuItem(
                                        value: m, child: Text(m)))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedMonth = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ======= สรุปพื้นที่ =======
                      Card(
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('สรุปเดือน: ${selectedMonth ?? "-"}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('อนุมัติ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text('พื้นที่รวม: $approvedArea ไร่'),
                                          Text(
                                              'จำนวนคำขอ: ${monthRequests.where((r) => r['status']?.toString().toLowerCase() == 'approved').length}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('ปฏิเสธ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text('พื้นที่รวม: $rejectedArea ไร่'),
                                          Text(
                                              'จำนวนคำขอ: ${monthRequests.where((r) => r['status']?.toString().toLowerCase() == 'rejected').length}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ======= รายละเอียดคำขอ =======
                      const Text('รายละเอียดคำขอ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ...monthRequests.map((req) {
                        final status = req['status']?.toString() ?? 'pending';
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
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
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.square_foot,
                                        size: 18, color: Colors.grey.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                        "ขนาด: ${req['area_size'] ?? '-'} ไร่"),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.info,
                                        size: 18,
                                        color: getStatusColor(status)),
                                    const SizedBox(width: 4),
                                    Text("สถานะ: $status",
                                        style: TextStyle(
                                            color: getStatusColor(status),
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.note,
                                        size: 18, color: Colors.grey.shade700),
                                    const SizedBox(width: 4),
                                    Expanded(
                                        child: Text(
                                            "หมายเหตุ: ${req['approval_note'] ?? '-'}",
                                            style: const TextStyle(
                                                fontStyle: FontStyle.italic))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
      ),
    );
  }
}

extension FirstOrNull<T> on List<T> {
  T? get firstOrNull => isNotEmpty ? first : null;
}
