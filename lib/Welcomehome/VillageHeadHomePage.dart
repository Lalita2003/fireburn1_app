import 'dart:convert';
import 'package:fireburn1_app/Select_village_head/BurnReportPage.dart';
import 'package:fireburn1_app/Select_village_head/PendingRequestsPage.dart';
import 'package:fireburn1_app/Select_village_head/VillageBurnHistoryPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fireburn1_app/Select_village_head/village_head_notification_page.dart';
import 'package:fireburn1_app/Select_user/user_profile_page.dart';

class VillageHeadHomePage extends StatefulWidget {
  final int userId;
  const VillageHeadHomePage({super.key, required this.userId});

  @override
  State<VillageHeadHomePage> createState() => _VillageHeadHomePageState();
}

class _VillageHeadHomePageState extends State<VillageHeadHomePage> {
  int _currentIndex = 0;

  // Summary variables
  int pendingToday = 0;
  int approvedToday = 0;
  int rejectedToday = 0;
  int burnedToday = 0;

  int pendingMonth = 0;
  int approvedMonth = 0;
  int rejectedMonth = 0;
  int burnedMonth = 0;

  String village = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          'http://localhost/flutter_fire/get_today_summary.php?user_id=${widget.userId}'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            pendingToday =
                int.tryParse(data['today']?['pending']?.toString() ?? "0") ?? 0;
            approvedToday =
                int.tryParse(data['today']?['approved']?.toString() ?? "0") ??
                    0;
            rejectedToday =
                int.tryParse(data['today']?['rejected']?.toString() ?? "0") ??
                    0;

            pendingMonth =
                int.tryParse(data['month']?['pending']?.toString() ?? "0") ?? 0;
            approvedMonth =
                int.tryParse(data['month']?['approved']?.toString() ?? "0") ??
                    0;
            rejectedMonth =
                int.tryParse(data['month']?['rejected']?.toString() ?? "0") ??
                    0;

            burnedToday = pendingToday + approvedToday;
            burnedMonth = pendingMonth + approvedMonth;

            village = data['village'] ?? '';

            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomeContent(),
      VillageHeadNotificationPage(
        userId: widget.userId,
        village: village,
      ),
      UserProfilePage(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_currentIndex],
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
                icon: Icon(Icons.home_outlined), label: 'หน้าหลัก'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none_outlined),
                label: 'แจ้งเตือน'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined), label: 'โปรไฟล์'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    const int maxValue = 50;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
            Text('ตรวจสอบคำขอเผาในพื้นที่ของคุณ',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchSummary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard("รออนุมัติวันนี้", pendingToday.toString(),
                      Colors.orange),
                  _buildSummaryCard(
                      "อนุมัติวันนี้", approvedToday.toString(), Colors.green),
                  _buildSummaryCard(
                      "ปฏิเสธวันนี้", rejectedToday.toString(), Colors.red),
                ],
              ),
              const SizedBox(height: 16),
              const Text('หมวดหมู่',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                children: [
                  _buildCategory(Icons.list_alt_outlined, 'คำขอรออนุมัติ',
                      badgeCount: pendingToday),
                  _buildCategory(Icons.history_outlined, 'ประวัติการอนุมัติ'),
                  _buildCategory(Icons.map_outlined, 'รายงานพื้นที่เผา',
                      badgeCount: burnedToday),
                ],
              ),
              const SizedBox(height: 20),
              const Text('สถิติรวมเดือนนี้',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              _buildProgressCard(
                  "รออนุมัติ", pendingMonth, maxValue, Colors.orange),
              _buildProgressCard(
                  "อนุมัติ", approvedMonth, maxValue, Colors.green),
              _buildProgressCard("ปฏิเสธ", rejectedMonth, maxValue, Colors.red),
              _buildProgressCard(
                  "พื้นที่เผา", burnedMonth, maxValue, Colors.purple),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(IconData icon, String title, {int badgeCount = 0}) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEF6C00), width: 0.5),
      ),
      child: InkWell(
        onTap: () async {
          if (title == 'คำขอรออนุมัติ') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PendingRequestsPage(
                  userId: widget.userId,
                  village: village,
                ),
              ),
            );
            // เรียก fetchSummary ใหม่ทันทีหลังกลับจากหน้า PendingRequestsPage
            fetchSummary();
          } else if (title == 'ประวัติการอนุมัติ') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VillageBurnHistoryPage(
                  userId: widget.userId,
                  village: village,
                ),
              ),
            );
            fetchSummary();
          } else if (title == 'รายงานพื้นที่เผา') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BurnReportPage(
                  userId: widget.userId,
                  village: village,
                ),
              ),
            );
            fetchSummary();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Icon(icon, color: const Color(0xFFEF6C00), size: 26),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
      String title, int value, int maxValue, Color color) {
    double progress = maxValue > 0 ? value / maxValue : 0;
    if (progress > 1) progress = 1;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("$value รายการ", style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}