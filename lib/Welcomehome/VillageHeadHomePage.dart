import 'package:fireburn1_app/Select_user/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VillageHeadHomePage extends StatefulWidget {
  final int userId; // userId ของผู้ใหญ่บ้าน

  const VillageHeadHomePage({super.key, required this.userId});

  @override
  State<VillageHeadHomePage> createState() => _VillageHeadHomePageState();
}

class _VillageHeadHomePageState extends State<VillageHeadHomePage> {
  int _currentIndex = 0;

  List<dynamic> requests = [];
  bool isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    fetchPendingRequests();
  }

  Future<void> fetchPendingRequests() async {
    setState(() {
      isLoadingRequests = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost/flutter_fire/get_pending_requests.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          requests = data;
          isLoadingRequests = false;
        });
      } else {
        throw Exception('โหลดคำขอล้มเหลว');
      }
    } catch (e) {
      setState(() {
        isLoadingRequests = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดคำขอล้มเหลว: $e')),
      );
    }
  }

  Widget _buildHome() {
    return const Center(
      child: Text(
        'หน้าหลัก',
        style: TextStyle(fontSize: 24, color: Color(0xFF212121)),
      ),
    );
  }

  Widget _buildRequestList() {
    if (isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return const Center(
          child: Text('ไม่มีคำขอที่รอดำเนินการ',
              style: TextStyle(color: Color(0xFF212121))));
    }

    return RefreshIndicator(
      onRefresh: fetchPendingRequests,
      child: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Card(
            margin: const EdgeInsets.all(10),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(
                '📍 ${request['area_name']} (${request['area_size']} ไร่)',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF212121)),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProfilePage(userId: request['user_id']),
                        ),
                      );
                    },
                    child: Text(
                      '👤 ผู้ขอ: ${request['username']} (ID: ${request['user_id']})',
                      style: const TextStyle(
                        color: Color(0xFFEF6C00),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text('🌾 ประเภทพืช: ${request['crop_type']}',
                      style: const TextStyle(color: Color(0xFF212121))),
                  Text('🎯 เหตุผล: ${request['purpose']}',
                      style: const TextStyle(color: Color(0xFF212121))),
                  Text('🗓 วันที่ขอเผา: ${request['request_date']}',
                      style: const TextStyle(color: Color(0xFF212121))),
                  Text(
                      '🕒 เวลา: ${request['time_slot_from']} - ${request['time_slot_to']}',
                      style: const TextStyle(color: Color(0xFF212121))),
                  Text(
                      '📌 พิกัด: ละติจูด ${request['location_lat']}, ลองจิจูด ${request['location_lng']}',
                      style: const TextStyle(color: Color(0xFF212121))),
                ],
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C00),
                  foregroundColor: Colors.white,
                ),
                child: const Text('ตรวจสอบ'),
                onPressed: () {
                  _showApproveDialog(request);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showApproveDialog(dynamic request) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('ตรวจสอบคำขอจาก ${request['username']}'),
          content: const Text('คุณต้องการอนุมัติคำขอนี้หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('อนุมัติคำขอเรียบร้อย',
                          style: TextStyle(color: Colors.green))),
                );
              },
              child: const Text('อนุมัติ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('ปฏิเสธคำขอเรียบร้อย',
                          style: TextStyle(color: Colors.red))),
                );
              },
              child: const Text('ปฏิเสธ'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfile() {
    return UserProfilePage(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    PreferredSizeWidget? appBar;

    if (_currentIndex == 0) {
      appBar = AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFDD6B00), Color(0xFFC14400)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('สวัสดี, ผู้ใหญ่บ้าน',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            Text('พร้อมตรวจสอบคำขอเผาแล้ว!',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      );
    } else if (_currentIndex == 1) {
      appBar = AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange.shade700,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'รายการคำขอ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      );
    } else {
      appBar = null; // ไม่มี AppBar ในหน้าโปรไฟล์
    }

    final List<Widget> _screens = [
      _buildHome(),
      _buildRequestList(),
      _buildProfile(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDD6B00), Color(0xFFC14400)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'หน้าหลัก',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              label: 'รายการ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              label: 'โปรไฟล์',
            ),
          ],
        ),
      ),
    );
  }
}
