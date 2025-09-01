import 'package:fireburn1_app/Select_user/BurnHistoryPage.dart';
import 'package:fireburn1_app/Select_user/NotificationPage.dart';
import 'package:flutter/material.dart';
import 'package:fireburn1_app/Select_user/weather_forecast_page.dart';
import 'package:fireburn1_app/Select_user/LocationPage.dart';
import 'package:fireburn1_app/Select_user/burn_request_page.dart';

import 'package:fireburn1_app/Select_user/user_profile_page.dart';

class UserHomePage extends StatefulWidget {
  final int userId; // รับ userId มาที่นี่

  const UserHomePage({super.key, required this.userId});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  double? selectedLatitude;
  double? selectedLongitude;

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomeContent(),
      NotificationPage(userId: widget.userId),
      UserProfilePage(userId: widget.userId), // ส่ง userId ไปหน้าโปรไฟล์
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
              icon: Icon(Icons.home_outlined),
              label: 'หน้าหลัก',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_outlined),
              label: 'การแจ้งเตือน',
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
            Text('สวัสดี, ผู้ใช้ทั่วไป',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            Text('พร้อมตรวจสอบการเผาแล้ว!',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
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
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: 'ค้นหา...',
                  hintStyle:
                      const TextStyle(color: Color(0xFF757575), fontSize: 13),
                  border: InputBorder.none,
                  icon: Icon(Icons.search,
                      color: const Color(0xFFEF6C00).withOpacity(0.8),
                      size: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // PM2.5 Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFEF6C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ตรวจสอบค่าฝุ่น PM2.5 ก่อนทำการเผา',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    const Text(
                      'กรุณาเลือกตำแหน่งพื้นที่ที่ต้องการวิเคราะห์ เพื่อดูค่าฝุ่น PM2.5',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SelectLocationPage()),
                        );

                        if (result != null && result is Map<String, double>) {
                          setState(() {
                            selectedLatitude = result['latitude'];
                            selectedLongitude = result['longitude'];
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFEF6C00),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('เลือกตำแหน่งเพื่อดูค่าฝุ่น PM2.5',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('หมวดหมู่',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF212121))),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                children: [
                  _buildCategory(Icons.cloud_outlined,
                      'เช็คค่าฝุ่น PM2.5 ก่อนขอเผา', context),
                  _buildCategory(Icons.local_fire_department_outlined,
                      'การขออนุญาตเผา', context),
                  _buildCategory(
                      Icons.description_outlined, 'ประวัติการขอเผา', context),

                  // _buildCategory(
                  //     Icons.map_outlined, 'แผนที่พื้นที่ควบคุม', context),
                  // _buildCategory(Icons.warning_amber_outlined,
                  //     'แจ้งเตือนฉุกเฉิน', context),
                  // _buildCategory(
                  //    Icons.settings_outlined, 'การตั้งค่า', context),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(IconData icon, String title, BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEF6C00), width: 0.5),
      ),
      child: InkWell(
        onTap: () {
          if (title == 'การขออนุญาตเผา') {
            if (selectedLatitude != null && selectedLongitude != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BurnRequestPage(
                    latitude: selectedLatitude!,
                    longitude: selectedLongitude!,
                    userId: widget.userId,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('กรุณาเลือกตำแหน่งก่อนขออนุญาตเผา')));
            }
          } else if (title == 'เช็คค่าฝุ่น PM2.5 ก่อนขอเผา') {
            if (selectedLatitude != null && selectedLongitude != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeatherForecastPage(
                    latitude: selectedLatitude!,
                    longitude: selectedLongitude!,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('กรุณาเลือกตำแหน่งก่อนดูค่าฝุ่น PM2.5')));
            }
          } else if (title == 'ประวัติการขอเผา') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BurnHistoryPage(userId: widget.userId),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('คุณเลือก: $title')),
            );
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
              Icon(icon, color: const Color(0xFFEF6C00), size: 26),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}