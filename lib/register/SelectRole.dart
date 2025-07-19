import 'package:fireburn1_app/register/SignupAdminPage.dart';
import 'package:fireburn1_app/register/SignupOfficerPage.dart';
import 'package:fireburn1_app/register/SignupUserPage.dart';
import 'package:fireburn1_app/register/SignupVillageHeadPage.dart';
import 'package:flutter/material.dart';


class SelectRolePage extends StatelessWidget {
  SelectRolePage({super.key});

  final Color primaryBrown = const Color(0xFF5D4037);
  final List<String> roles = ['User', 'ผู้ใหญ่บ้าน', 'เจ้าหน้าที่']; // ไม่แสดง Admin ในลิสต์
  final List<IconData> icons = [
    Icons.person,
    Icons.home,
    Icons.badge,
  ];

  void navigateToSignupPage(BuildContext context, String role) {
    switch (role) {
      case 'User':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SignupUserPage()));
        break;
      case 'ผู้ใหญ่บ้าน':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SignupVillageHeadPage()));
        break;
      case 'เจ้าหน้าที่':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SignupOfficerPage()));
        break;
    }
  }

  void showAdminAccessDialog(BuildContext context) {
    final TextEditingController passcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "เข้าถึงสำหรับ Admin",
          style: TextStyle(
            color: primaryBrown,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: TextField(
          controller: passcodeController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "ใส่รหัสผ่านสำหรับผู้ดูแลระบบ",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryBrown),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryBrown, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: primaryBrown),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              "ยกเลิก",
              style: TextStyle(color: primaryBrown, fontSize: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBrown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "ยืนยัน",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            onPressed: () {
              if (passcodeController.text == "admin1234") {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignupAdminPage()),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("รหัสไม่ถูกต้อง")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        title: const Text(
          'เลือกบทบาทผู้ใช้งาน',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryBrown,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock, color: Colors.white),
            tooltip: 'สำหรับ Admin',
            onPressed: () => showAdminAccessDialog(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'กรุณาเลือกบทบาทในการสมัครใช้งาน',
              style: TextStyle(fontSize: 18, color: Colors.brown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final role = roles[index];
                  final icon = icons[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: Icon(icon, size: 32, color: primaryBrown),
                      title: Text(
                        role,
                        style: TextStyle(
                          fontSize: 18,
                          color: primaryBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                      onTap: () => navigateToSignupPage(context, role),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}