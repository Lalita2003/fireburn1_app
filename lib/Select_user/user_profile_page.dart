import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userInfo = {
      'ชื่อผู้ใช้': 'ผู้ใช้ทั่วไป',
      'อีเมล': 'user@example.com',
      'เบอร์โทร': '0812345678',
      'หมู่บ้าน': 'บ้านสวน',
      'ตำบล': 'ฟ้าฮ่าม',
      'อำเภอ': 'เมืองเชียงใหม่',
      'จังหวัด': 'เชียงใหม่',
      'บทบาท': 'ผู้ใช้ทั่วไป',
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ไม่มีปุ่มย้อนกลับ
        title: const Text('โปรไฟล์ผู้ใช้'),
        centerTitle: true,
        backgroundColor: const Color(0xFFEF6C00),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              userInfo['ชื่อผู้ใช้'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30),
            ...userInfo.entries
                .where((entry) =>
                    entry.key != 'ชื่อผู้ใช้' && entry.key != 'บทบาท')
                .map((entry) {
              return ListTile(
                leading:
                    const Icon(Icons.info_outline, color: Colors.deepOrange),
                title: Text(entry.key),
                subtitle: Text(entry.value),
              );
            }).toList(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                // TODO: เขียนฟังก์ชัน logout ที่นี่
              },
              icon: const Icon(Icons.logout),
              label: const Text('ออกจากระบบ'),
            ),
          ],
        ),
      ),
    );
  }
}
