import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProfilePage extends StatefulWidget {
  final int userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost/flutter_fire/user_profile.php?id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          setState(() {
            userData = json['user'];
            isLoading = false;
          });
        } else {
          setState(() {
            userData = null;
            isLoading = false;
          });
        }
      } else {
        throw Exception('ไม่สามารถโหลดข้อมูลผู้ใช้ได้');
      }
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return const Scaffold(
        body: Center(child: Text('ไม่พบข้อมูลผู้ใช้')),
      );
    }

    final String role = userData!['role'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('โปรไฟล์ผู้ใช้'),
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'ออกจากระบบ',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              children: [
                Icon(Icons.account_circle,
                    size: 100, color: Colors.orange.shade400),
                const SizedBox(height: 16),
                const Text(
                  "ข้อมูลผู้ใช้งาน",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 20),
                buildProfileTile(
                    Icons.person, 'ชื่อผู้ใช้', userData!['username']),
                buildProfileTile(Icons.email, 'อีเมล', userData!['email']),
                buildProfileTile(Icons.phone, 'เบอร์โทร', userData!['phone']),
                if (role != 'admin' && role != 'officer')
                  buildProfileTile(
                      Icons.home, 'หมู่บ้าน', userData!['village']),
                if (role != 'user' && role != 'village_head')
                  buildProfileTile(
                      Icons.business, 'หน่วยงาน', userData!['agency']),
                buildProfileTile(
                    Icons.location_on, 'ตำบล', userData!['subdistrict']),
                buildProfileTile(
                    Icons.location_city, 'อำเภอ', userData!['district']),
                buildProfileTile(Icons.map, 'จังหวัด', userData!['province']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProfileTile(IconData icon, String label, String? value) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
          leading: Icon(icon, color: Colors.orange.shade700),
          title: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text(value ?? '-', style: const TextStyle(fontSize: 15)),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
