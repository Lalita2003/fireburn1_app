import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestListPage extends StatefulWidget {
  const RequestListPage({super.key});

  @override
  State<RequestListPage> createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> fetchRequests() async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://localhost/flutter_fire/burn_request.php"), // ✅ เปลี่ยน URL จริง
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          requests = data.cast<Map<String, dynamic>>();
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

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('รายการคำขอ'),
        centerTitle: true,
        backgroundColor: const Color(0xFFEF6C00),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : requests.isEmpty
                  ? const Center(child: Text("ยังไม่มีคำขอ"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.local_fire_department_outlined,
                              color: Colors.orange,
                            ),
                            title:
                                Text(request['area_name'] ?? 'ไม่ทราบพื้นที่'),
                            subtitle: Text(
                                'วันที่ขอ: ${request['request_date'] ?? '-'}\n'
                                'ขนาด: ${request['area_size'] ?? '-'} ไร่\n'
                                'พืช: ${request['crop_type'] ?? '-'}'),
                            trailing: Text(
                              _statusText(request['status']),
                              style: TextStyle(
                                fontSize: 12,
                                color: _statusColor(request['status']),
                                fontWeight: FontWeight.bold,
                              ),
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
        return 'อนุมัติแล้ว';
      case 'pending':
        return 'รอดำเนินการ';
      case 'rejected':
        return 'ถูกปฏิเสธ';
      case 'cancelled':
        return 'ยกเลิก';
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
