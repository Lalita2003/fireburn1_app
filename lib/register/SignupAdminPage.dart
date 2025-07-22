import 'package:fireburn1_app/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupAdminPage extends StatefulWidget {
  const SignupAdminPage({super.key});

  @override
  _SignupAdminPageState createState() => _SignupAdminPageState();
}

class _SignupAdminPageState extends State<SignupAdminPage> {
  final Color primaryBrown = const Color(0xFF5D4037);
  final Color gradientStart = const Color.fromARGB(255, 208, 146, 1);
  final Color gradientEnd = const Color(0xFFEF6C00);
  final Color backgroundColor = const Color(0xFFFFF3E0);
  final Color lightBrown = const Color(0xFFFFF8E1);

  bool acceptTerms = false;
  bool isLoading = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> handleSignup() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (!acceptTerms) {
      showSnack("กรุณายอมรับข้อตกลง");
      return;
    }

    if ([username, email, phone, password, confirmPassword].contains('')) {
      showSnack("กรุณากรอกข้อมูลให้ครบทุกช่อง");
      return;
    }

    if (password != confirmPassword) {
      showSnack("รหัสผ่านไม่ตรงกัน");
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('http://localhost/flutter_fire/register_admin.php'); // เปลี่ยน URL ให้ตรงกับเซิร์ฟเวอร์จริง
      final response = await http.post(url, body: {
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
      });

      final data = json.decode(response.body);
      showSnack(data['message'] ?? 'เกิดข้อผิดพลาด');

      if (data['status'] == 'success') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      showSnack('เกิดข้อผิดพลาดในการเชื่อมต่อ');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'สมัครสมาชิก - Admin',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientStart, gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader("ข้อมูลผู้ดูแลระบบ"),
            inputField('Username', controller: usernameController),
            inputField('Email', controller: emailController),
            inputField('เบอร์โทรศัพท์', controller: phoneController),
            sectionHeader("รหัสผ่าน"),
            inputField('Password', obscureText: true, controller: passwordController),
            inputField('Confirm Password', obscureText: true, controller: confirmPasswordController),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: acceptTerms,
                  activeColor: gradientEnd,
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
                onPressed: isLoading ? null : handleSignup,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.zero,
                  elevation: 4,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [gradientStart, gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'สมัครสมาชิก',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionHeader(String title) {
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
          fillColor: lightBrown.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: gradientEnd),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: gradientStart, width: 2),
          ),
        ),
      ),
    );
  }
}
