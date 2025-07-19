import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:fireburn1_app/login.dart'; // แก้ path ให้ถูกต้องของ LoginPage

class SignupVillageHeadPage extends StatefulWidget {
  const SignupVillageHeadPage({super.key});

  @override
  _SignupVillageHeadPageState createState() => _SignupVillageHeadPageState();
}

class _SignupVillageHeadPageState extends State<SignupVillageHeadPage> {
  final Color primaryBrown = const Color(0xFF5D4037);
  final Color lightBrown = const Color(0xFFD7CCC8);
  final Color backgroundColor = const Color(0xFFFFF3E0);

  bool acceptTerms = false;
  bool isLoading = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController villageController = TextEditingController();
  final TextEditingController subDistrictController = TextEditingController();
  final TextEditingController provinceController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    villageController.dispose();
    subDistrictController.dispose();
    provinceController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerVillageHead() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน')),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse('http://localhost/flutter_fire/register_village.php'); // แก้เป็น URL จริง
    final response = await http.post(
      url,
      body: {
        'username': usernameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'village': villageController.text,
        'subdistrict': subDistrictController.text,
        'province': provinceController.text,
        'password': passwordController.text,
      },
    );

    final result = json.decode(response.body);
    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'เกิดข้อผิดพลาด')),
    );

    if (result['status'] == 'success') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBrown,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'สมัครสมาชิก - ผู้ใหญ่บ้าน',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header("ข้อมูลผู้ใช้งาน"),
            inputField('ชื่อผู้ใช้งาน', controller: usernameController),
            inputField('อีเมล', controller: emailController),
            inputField('เบอร์โทรศัพท์', controller: phoneController),
            inputField('หมู่บ้าน', controller: villageController),
            inputField('ตำบล', controller: subDistrictController),
            inputField('จังหวัด', controller: provinceController),
            const SizedBox(height: 10),
            header("รหัสผ่าน"),
            inputField('รหัสผ่าน', obscureText: true, controller: passwordController),
            inputField('ยืนยันรหัสผ่าน', obscureText: true, controller: confirmPasswordController),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: acceptTerms,
                  activeColor: primaryBrown,
                  onChanged: (value) {
                    setState(() {
                      acceptTerms = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    "ฉันยอมรับข้อตกลงและนโยบายการใช้งาน",
                    style: TextStyle(color: primaryBrown, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (!acceptTerms) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("กรุณายอมรับข้อตกลง")),
                          );
                          return;
                        }
                        registerVillageHead();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBrown,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'สมัครสมาชิก',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget header(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),
      child: Text(
        title,
        style: TextStyle(
          color: primaryBrown,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget inputField(String label, {bool obscureText = false, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryBrown, fontSize: 14),
          filled: true,
          fillColor: lightBrown.withOpacity(0.15),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.brown),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBrown, width: 2),
          ),
        ),
      ),
    );
  }
}
