import 'package:flutter/material.dart';
import 'package:fireburn1_app/register/SignupAdminPage.dart';
import 'package:fireburn1_app/register/SignupOfficerPage.dart';
import 'package:fireburn1_app/register/SignupUserPage.dart';
import 'package:fireburn1_app/register/SignupVillageHeadPage.dart';

class SelectRolePage extends StatelessWidget {
  SelectRolePage({super.key});

  final Color primaryBrown = const Color(0xFF5D4037);
  final List<String> roles = ['User', 'ผู้ใหญ่บ้าน', 'เจ้าหน้าที่'];
  final List<IconData> icons = [Icons.person, Icons.home, Icons.badge];

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
    const Color startColor = Color.fromARGB(255, 208, 146, 1);
    const Color endColor = Color(0xFFEF6C00);

    LinearGradient gradient = const LinearGradient(
      colors: [startColor, endColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const Text(
            "เข้าถึงสำหรับ Admin",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        content: TextField(
          controller: passcodeController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "ใส่รหัสผ่านสำหรับผู้ดูแลระบบ",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: startColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: endColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: endColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: const Text(
                "ยกเลิก",
                style: TextStyle(fontSize: 16),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: startColor,
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => SignupAdminPage()));
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
      appBar: AppBar(
        title: const Text(
          'เลือกบทบาทผู้ใช้งาน',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 208, 146, 1),
                Color(0xFFEF6C00),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock, color: Colors.white),
            tooltip: 'สำหรับ Admin',
            onPressed: () => showAdminAccessDialog(context),
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF3E0), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -40,
            child: _circle(160, const Color(0xFFEF6C00), 0.15),
          ),
          Positioned(
            top: 100,
            left: 40,
            child: _circle(100, const Color(0xFFFFB300), 0.15),
          ),
          Positioned(
            bottom: -60,
            right: -30,
            child: _circle(180, const Color(0xFFC14400), 0.15),
          ),
          Positioned(
            bottom: 40,
            left: -50,
            child: _circle(130, const Color(0xFFFFB300), 0.12),
          ),
          Positioned(
            top: 30,
            right: -30,
            child: _circle(90, const Color(0xFFEF6C00), 0.12),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'กรุณาเลือกบทบาทในการสมัครใช้งาน',
                    style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 123, 44, 2)),
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

                            leading: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 167, 117, 1),
                                  Color(0xFFEF6C00),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: Icon(icon, size: 32),
                            ),

                            title: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 208, 146, 1),
                                  Color(0xFFEF6C00),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
