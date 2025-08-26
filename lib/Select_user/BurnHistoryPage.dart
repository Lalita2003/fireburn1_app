import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BurnHistoryPage extends StatefulWidget {
  final int userId;

  const BurnHistoryPage({super.key, required this.userId});

  @override
  State<BurnHistoryPage> createState() => _BurnHistoryPageState();
}

class _BurnHistoryPageState extends State<BurnHistoryPage> {
  List<Map<String, dynamic>> burnRequests = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchBurnRequests();
  }

  Future<void> fetchBurnRequests() async {
    try {
      final uri = Uri.parse(
          'http://localhost/flutter_fire/burn_request.php?user_id=${widget.userId}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          burnRequests =
              data.map((item) => item as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'เกิดข้อผิดพลาด: ${response.statusCode} ${response.reasonPhrase}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '-';
    try {
      final t = DateFormat.Hms().parse(time);
      return DateFormat.Hm().format(t);
    } catch (e) {
      return time;
    }
  }

  String _formatDecimal(dynamic value) {
    if (value == null) return '-';
    final d = double.tryParse(value.toString());
    if (d == null) return '-';
    return d.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการขอเผา'),
        backgroundColor: const Color(0xFFEF6C00),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('เกิดข้อผิดพลาด: $errorMessage'))
              : burnRequests.isEmpty
                  ? const Center(child: Text('ไม่มีประวัติการขอเผา'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: burnRequests.length,
                      itemBuilder: (context, index) {
                        final req = burnRequests[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ชื่อพื้นที่และสถานะ
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      req['area_name'] ?? '-',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(req['status']),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        req['status']
                                                ?.toString()
                                                .toUpperCase() ??
                                            '-',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                    'ขนาดพื้นที่: ${_formatDecimal(req['area_size'])} ไร่'),
                                Text(
                                    'ละติจูด: ${_formatDecimal(req['location_lat'])}, ลองจิจูด: ${_formatDecimal(req['location_lng'])}'),
                                const SizedBox(height: 6),
                                Text(
                                    'วันที่ต้องการเผา: ${req['request_date'] ?? '-'}'),
                                Text(
                                    'เวลา: ${_formatTime(req['time_slot_from'])} - ${_formatTime(req['time_slot_to'])}'),
                                const SizedBox(height: 6),
                                Text('ประเภทพืช: ${req['crop_type'] ?? '-'}'),
                                Text('เหตุผล: ${req['purpose'] ?? '-'}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
