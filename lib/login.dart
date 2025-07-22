import 'package:fireburn1_app/Welcomehome/AdminHomePage.dart';
import 'package:fireburn1_app/Welcomehome/OfficerHomePage.dart';
import 'package:fireburn1_app/Welcomehome/UserHomePage.dart';
import 'package:fireburn1_app/Welcomehome/VillageHeadHomePage.dart';
import 'package:fireburn1_app/register/SelectRole.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color primaryBrown = const Color(0xFF5D4037);
  final Color backgroundColor = Colors.white; // พื้นหลังสีขาว

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showSnack("กรุณากรอกอีเมลและรหัสผ่าน");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final uri = Uri.parse('http://localhost/flutter_fire/login.php');
      final response = await http.post(uri, body: {
        'email': email,
        'password': password,
      });

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        final user = data['user'];
        final role = user['role'];

        showSnack("เข้าสู่ระบบสำเร็จ: ยินดีต้อนรับ ${user['username']}");

        Widget homePage;
        if (role == 'user') {
          homePage = const UserHomePage();
        } else if (role == 'village_head') {
          homePage = const VillageHeadHomePage();
        } else if (role == 'officer') {
          homePage = const OfficerHomePage();
        } else if (role == 'admin') {
          homePage = const AdminHomePage();
        } else {
          showSnack("บทบาทไม่ถูกต้อง");
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => homePage),
        );
      } else {
        showSnack(data['message'] ?? "เข้าสู่ระบบไม่สำเร็จ");
      }
    } catch (e) {
      showSnack("เกิดข้อผิดพลาด: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient สีส้มอ่อน ไล่ไปขาว
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF3E0), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // วงกลมโปร่งใสสีส้มวางลอยๆ
          Positioned(
            top: -50,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFEF6C00).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // เนื้อหา LoginPage อยู่ด้านบน
          SafeArea(
            child: Container(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFDD6B00), Color(0xFFC14400)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // ต้องใส่สีนี้ไว้
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFEF6C00)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      "Login to your burning account",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white, // ต้องใส่สีนี้ไว้
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        inputField(label: "Email", controller: emailController, primaryBrown: primaryBrown),
                        inputField(label: "Password", obscureText: true, controller: passwordController, primaryBrown: primaryBrown),
                        const SizedBox(height: 30),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color.fromARGB(255, 208, 146, 1), Color(0xFFEF6C00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: isLoading ? null : loginUser,
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "Login",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "ไม่มีบัญชีใช่ไหม?",
                              style: TextStyle(color: primaryBrown.withOpacity(0.7)),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SelectRolePage())),
                              child: Text(
                                " สมัครสมาชิก",
                                style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        )
                      ],
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

  Widget inputField({
    required String label,
    bool obscureText = false,
    required TextEditingController controller,
    required Color primaryBrown,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: primaryBrown)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
