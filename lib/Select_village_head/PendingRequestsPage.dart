import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 📌 หน้าแสดงคำขอทั้งหมด
class PendingRequestsPage extends StatefulWidget {
  final int userId;
  final String village;

  const PendingRequestsPage({
    super.key,
    required this.userId,
    required this.village,
  });

  @override
  State<PendingRequestsPage> createState() => _PendingRequestsPageState();
}

class _PendingRequestsPageState extends State<PendingRequestsPage> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPendingRequests();
  }

  // 🔹 ดึงข้อมูลผู้ใช้ทั้งหมด (user_id → village)
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

  // 🔹 ดึงคำขอรออนุมัติ และกรองตาม village และ status=pending
  Future<void> fetchPendingRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final usersMap = await fetchUsersMap();
      final url = Uri.parse(
          'http://localhost/flutter_fire/burn_request.php?status=pending');
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

  // 📌 แสดงหน้าต่างรายละเอียด
  void showRequestDetail(Map<String, dynamic> req) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.85,
            child: RequestDetailContent(
              requestData: req,
              villageHeadId: widget.userId,
            ),
          ),
        );
      },
    );

    // 🔄 Refresh list ใหม่จาก server หลังอนุมัติ/ปฏิเสธ
    if (result == true) {
      fetchPendingRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("คำขอรออนุมัติ"),
        backgroundColor: const Color(0xFFDD6B00),
        elevation: 0,
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
                    padding: const EdgeInsets.all(12),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: ListTile(
                          leading: const Icon(Icons.fireplace,
                              color: Colors.deepOrange),
                          title: Text(
                            req['area_name'] ?? 'พื้นที่ไม่ระบุ',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                              "ขนาดพื้นที่: ${req['area_size'] ?? '-'} ไร่"),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => showRequestDetail(req),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

// 📌 หน้าต่างรายละเอียดคำขอ
class RequestDetailContent extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final int villageHeadId;

  const RequestDetailContent({
    super.key,
    required this.requestData,
    required this.villageHeadId,
  });

  @override
  State<RequestDetailContent> createState() => _RequestDetailContentState();
}

class _RequestDetailContentState extends State<RequestDetailContent> {
  final TextEditingController reasonController = TextEditingController();
  List<Map<String, dynamic>>? weatherLogs;

  @override
  void initState() {
    super.initState();
    fetchWeatherLogs();
  }

  Future<void> fetchWeatherLogs() async {
    final requestId = int.tryParse(widget.requestData['id'].toString()) ?? 0;
    try {
      final url = Uri.parse(
          'http://localhost/flutter_fire/weather_logs.php?burn_request_id=$requestId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            weatherLogs =
                List<Map<String, dynamic>>.from(data['weather_logs'] ?? []);
          });
        }
      }
    } catch (_) {}
  }

  String classifyPM25(double pm25) {
    if (pm25 <= 15) return "🔵 ดีมาก";
    if (pm25 <= 25) return "🟢 ดี";
    if (pm25 <= 37.5) return "🟡 ปานกลาง";
    if (pm25 <= 50) return "🟠 เริ่มมีผลกระทบ";
    return "🔴 มีผลกระทบต่อสุขภาพ";
  }

  // 🔹 ฟังก์ชันส่ง API อัปเดตคำขอ
  Future<void> updateRequestStatus(String status) async {
    final requestId = int.tryParse(widget.requestData['id'].toString()) ?? 0;
    final url =
        Uri.parse('http://localhost/flutter_fire/update_burn_request.php');

    final body = json.encode({
      "request_id": requestId,
      "status": status,
      "approved_by": widget.villageHeadId,
      "approval_note": reasonController.text,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(status == 'approved'
                  ? '✅ อนุมัติคำขอเรียบร้อย'
                  : '❌ ปฏิเสธคำขอเรียบร้อย')),
        );
        Navigator.pop(context, true); // ✅ ส่ง true กลับไปเพื่อ refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: ${data['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
      );
    }
  }

  void approveRequest() => updateRequestStatus("approved");
  void rejectRequest() => updateRequestStatus("rejected");

  @override
  Widget build(BuildContext context) {
    final req = widget.requestData;
    return Column(
      children: [
        // 🔹 Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFDD6B00),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(req['area_name'] ?? 'รายละเอียดคำขอ',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white))
            ],
          ),
        ),

        // 🔹 Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfo("📍 ขนาดพื้นที่", "${req['area_size'] ?? '-'} ไร่"),
                _buildInfo("🗺️ ตำแหน่ง",
                    "${req['location_lat'] ?? '-'}, ${req['location_lng'] ?? '-'}"),
                _buildInfo("📅 วันที่ต้องการเผา", req['request_date'] ?? '-'),
                _buildInfo("⏰ เวลา",
                    "${req['time_slot_from'] ?? '-'} - ${req['time_slot_to'] ?? '-'}"),
                _buildInfo("🌾 ประเภทพืช", req['crop_type'] ?? '-'),
                _buildInfo("📝 เหตุผลการเผา", req['purpose'] ?? '-'),
                const SizedBox(height: 16),
                const Text("🌤 ข้อมูลสภาพอากาศรายชั่วโมง",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (weatherLogs != null && weatherLogs!.isNotEmpty)
                  ...weatherLogs!.map((w) {
                    final pm25 =
                        double.tryParse((w['pm25_model'] ?? '0').toString()) ??
                            0;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "📆 ${w['forecast_date'] ?? '-'} 🕒 ${w['forecast_hour'] ?? '-'}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                                "🌡️ Temp: ${w['temperature'] ?? '-'}°C | 💧 Humidity: ${w['humidity'] ?? '-'}%"),
                            Text(
                                "💨 Wind: ${w['wind_speed'] ?? '-'} m/s | ⛰️ Boundary: ${w['boundary_height'] ?? '-'} m"),
                            Text(
                                "PM2.5: ${w['pm25_model'] ?? '-'} µg/m³ ${classifyPM25(pm25)}"),
                          ],
                        ),
                      ),
                    );
                  }).toList()
                else
                  const Text("ไม่พบข้อมูลสภาพอากาศ"),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'เหตุผลในการอนุมัติ/ปฏิเสธ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),

        // 🔹 Footer (ปุ่ม)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: approveRequest,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text("อนุมัติ"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: rejectRequest,
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text("ปฏิเสธ"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 5, child: Text(value)),
        ],
      ),
    );
  }
}
