import 'package:flutter/material.dart';
import 'package:fireburn1_app/Select_user/user_profile_page.dart';

class AdminHomePage extends StatefulWidget {
  final int userId;

  const AdminHomePage({super.key, required this.userId});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomeContent(),
      Container(color: Colors.white), // Notifications placeholder
      UserProfilePage(userId: widget.userId), // Profile page
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
            Text('สวัสดี, ผู้ดูแลระบบ',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            Text('จัดการระบบและผู้ใช้งานได้ที่นี่!',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Search box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: const TextField(
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  hintText: 'ค้นหาผู้ใช้งานหรือคำขอ...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Color(0xFFEF6C00), size: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Grid Menu
            const Text('เมนูการจัดการ',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF212121))),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                children: [
                  _buildCategory(Icons.people_alt_outlined, 'จัดการผู้ใช้งาน'),
                  _buildCategory(Icons.history_outlined, 'ประวัติคำขอ'),
                  _buildCategory(Icons.report_gmailerrorred_outlined, 'รายงาน'),
                  _buildCategory(Icons.settings_outlined, 'ตั้งค่า'),
                  _buildCategory(
                      Icons.notifications_none_outlined, 'แจ้งเตือน'),
                  _buildCategory(Icons.analytics_outlined, 'สถิติ'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(IconData icon, String title) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEF6C00), width: 0.5),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Implement navigation or action
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
              Icon(icon, color: const Color(0xFFEF6C00), size: 26),
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
}
