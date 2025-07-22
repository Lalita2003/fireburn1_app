import 'package:fireburn1_app/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupUserPage extends StatefulWidget {
  const SignupUserPage({super.key});

  @override
  _SignupUserPageState createState() => _SignupUserPageState();
}

class _SignupUserPageState extends State<SignupUserPage> {
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
  final TextEditingController villageController = TextEditingController();
  final TextEditingController subdistrictController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController provinceController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    villageController.dispose();
    subdistrictController.dispose();
    districtController.dispose();
    provinceController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> registerUser() async {
    if (!acceptTerms) {
      showSnack("กรุณายอมรับข้อตกลง");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showSnack("รหัสผ่านไม่ตรงกัน");
      return;
    }

    setState(() => isLoading = true);

    final uri = Uri.parse('http://localhost/flutter_fire/register_user.php');

    try {
      final response = await http.post(uri, body: {
        "username": usernameController.text,
        "email": emailController.text,
        "phone": phoneController.text,
        "village": villageController.text,
        "subdistrict": subdistrictController.text,
        "district": districtController.text,
        "province": provinceController.text,
        "password": passwordController.text,
        "agency": "", // สำหรับ user ทั่วไป
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => isLoading = false);

        if (data['status'] == 'success') {
          showSnack("สมัครสมาชิกสำเร็จ");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          showSnack(data['message'] ?? "เกิดข้อผิดพลาดในการสมัครสมาชิก");
        }
      } else {
        setState(() => isLoading = false);
        showSnack("เกิดข้อผิดพลาด: เซิร์ฟเวอร์ตอบกลับสถานะ ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      showSnack("เกิดข้อผิดพลาดในการเชื่อมต่อ: $e");
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'สมัครสมาชิก - ผู้ใช้ทั่วไป',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
            header("ข้อมูลผู้ใช้งาน"),
            inputField('ชื่อผู้ใช้งาน', controller: usernameController),
            inputField('อีเมล', controller: emailController),
            inputField('เบอร์โทรศัพท์', controller: phoneController),
            inputField('หมู่บ้าน', controller: villageController),
            inputField('ตำบล', controller: subdistrictController),
            inputField('อำเภอ', controller: districtController),
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
                onPressed: isLoading ? null : registerUser,
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

  Widget header(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),
      child: Text(
        title,
        style: TextStyle(color: primaryBrown, fontSize: 16, fontWeight: FontWeight.w700),
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
