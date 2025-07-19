import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      appBar: AppBar(
        automaticallyImplyLeading: false, // ❌ เอาลูกศรย้อนกลับออก
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'ยินดีต้อนรับ',
          style: TextStyle(color: Colors.white),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.notifications, color: Colors.white),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 ตรวจสอบค่าฝุ่น PM2.5 ก่อนทำการเผา',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'กรุณาเลือกตำแหน่งพื้นที่ที่ต้องการวิเคราะห์ เพื่อดูค่าฝุ่น PM2.5' ,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/select_location');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.map),
                label: const Text(
                  'เลือกตำแหน่งเพื่อดูค่าฝุ่น PM2.5',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'หมวดหมู่',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCategory(Icons.fireplace, 'การเผา'),
                _buildCategory(Icons.map, 'ตำแหน่ง'),
                _buildCategory(Icons.warning, 'แจ้งเตือน'),
                _buildCategory(Icons.health_and_safety, 'PM2.5'),
                _buildCategory(Icons.report, 'รายงาน'),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'การแจ้งเตือนล่าสุด',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.warning, color: Colors.orange),
                    title: Text('พื้นที่ตำบลแม่วิน PM2.5 เกินเกณฑ์'),
                    subtitle: Text('16 ก.ค. 2025 เวลา 08:00 น.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('อนุญาตให้เผา - พื้นที่ อ.ฮอด'),
                    subtitle: Text('15 ก.ค. 2025 เวลา 18:00 น.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        currentIndex: 0, // เพิ่มไว้เพื่อไม่ให้ BottomNavigationBar กระพริบ
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'รายการ'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  Widget _buildCategory(IconData icon, String title) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Color(0xFF4CAF50), size: 32),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
