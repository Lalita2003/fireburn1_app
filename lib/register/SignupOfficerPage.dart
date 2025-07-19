import 'package:fireburn1_app/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupOfficerPage extends StatefulWidget {
  const SignupOfficerPage({super.key});

  @override
  _SignupOfficerPageState createState() => _SignupOfficerPageState();
}

class _SignupOfficerPageState extends State<SignupOfficerPage> {
  final Color primaryBrown = const Color(0xFF5D4037);
  final Color lightBrown = const Color(0xFFD7CCC8);
  final Color backgroundColor = const Color(0xFFFFF3E0);

  bool acceptTerms = false;
  bool isLoading = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController provinceController = TextEditingController();
  final TextEditingController agencyController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    provinceController.dispose();
    agencyController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerOfficer() async {
    if (!acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณายอมรับข้อตกลง")),
      );
      return;
    }

    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        provinceController.text.isEmpty ||
        agencyController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบทุกช่อง")),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("รหัสผ่านไม่ตรงกัน")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://localhost/flutter_fire/register_officer.php'); // แก้ URL ตามจริง
    try {
      final response = await http.post(
        url,
        body: {
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'province': provinceController.text.trim(),
          'agency': agencyController.text.trim(),
          'password': passwordController.text,
        },
      );

      final data = json.decode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'เกิดข้อผิดพลาด')),
      );

      if (data['status'] == 'success') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBrown,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'สมัครสมาชิก - เจ้าหน้าที่',
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
            inputField('จังหวัด', controller: provinceController),
            inputField('หน่วยงานต้นสังกัด', controller: agencyController),
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
                onPressed: isLoading ? null : registerOfficer,
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
        style: TextStyle(color: primaryBrown, fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget inputField(String label,
      {bool obscureText = false, TextEditingController? controller}) {
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
