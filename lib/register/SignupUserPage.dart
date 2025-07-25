import 'package:fireburn1_app/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupUserPage extends StatefulWidget {
  const SignupUserPage({super.key});

  @override
  State<SignupUserPage> createState() => _SignupUserPageState();
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
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  List provinces = [];
  List districts = [];
  List subdistricts = [];

  String? selectedProvince;
  String? selectedDistrict;
  String? selectedSubdistrict;

  @override
  void initState() {
    super.initState();
    loadProvinces();
  }

  Future<void> loadProvinces() async {
    try {
      final uri = Uri.parse("http://localhost/flutter_fire/provinces.php");
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final responseData = json.decode(res.body);
        if (responseData['status'] == 'success') {
          setState(() {
            provinces = responseData['data'];
          });
        } else {
          showSnack("โหลดจังหวัดล้มเหลว: ${responseData['message']}");
        }
      } else {
        showSnack("โหลดจังหวัดล้มเหลว: HTTP ${res.statusCode}");
      }
    } catch (e) {
      showSnack("โหลดจังหวัดล้มเหลว: $e");
    }
  }

  Future<void> loadDistricts(String provinceId) async {
    try {
      final uri = Uri.parse("http://localhost/flutter_fire/districts.php");
      final res = await http.post(uri, body: {"province_id": provinceId});
      if (res.statusCode == 200) {
        final responseData = json.decode(res.body);
        if (responseData['status'] == 'success') {
          setState(() {
            districts = responseData['data'];
            selectedDistrict = null;
            subdistricts = [];
            selectedSubdistrict = null;
          });
        } else {
          showSnack("โหลดอำเภอล้มเหลว: ${responseData['message']}");
        }
      } else {
        showSnack("โหลดอำเภอล้มเหลว: HTTP ${res.statusCode}");
      }
    } catch (e) {
      showSnack("โหลดอำเภอล้มเหลว: $e");
    }
  }

  Future<void> loadSubdistricts(String amphureId) async {
    try {
      final uri = Uri.parse("http://localhost/flutter_fire/subdistricts.php");
      final res = await http.post(uri, body: {"amphure_id": amphureId});
      if (res.statusCode == 200) {
        final responseData = json.decode(res.body);
        if (responseData['status'] == 'success') {
          setState(() {
            subdistricts = responseData['data'];
            selectedSubdistrict = null;
          });
        } else {
          showSnack("โหลดตำบลล้มเหลว: ${responseData['message']}");
        }
      } else {
        showSnack("โหลดตำบลล้มเหลว: HTTP ${res.statusCode}");
      }
    } catch (e) {
      showSnack("โหลดตำบลล้มเหลว: $e");
    }
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

    if (selectedProvince == null ||
        selectedDistrict == null ||
        selectedSubdistrict == null) {
      showSnack("กรุณาเลือกจังหวัด อำเภอ และตำบลให้ครบถ้วน");
      return;
    }

    setState(() => isLoading = true);

    final uri = Uri.parse("http://localhost/flutter_fire/register_user.php");
    try {
      final response = await http.post(uri, body: {
        "username": usernameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "village": villageController.text.trim(),
        "province_id": selectedProvince!,
        "district_id": selectedDistrict!,
        "subdistrict_id": selectedSubdistrict!,
        "password": passwordController.text,
        "agency": "",
      });

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          if (data['status'] == 'success') {
            showSnack("สมัครสมาชิกสำเร็จ");
            Future.delayed(const Duration(milliseconds: 500), () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginPage()));
            });
          } else {
            showSnack(data['message'] ?? "เกิดข้อผิดพลาดในการสมัครสมาชิก");
          }
        } catch (e) {
          showSnack("เกิดข้อผิดพลาด: ข้อมูลไม่ใช่ JSON\n$e");
        }
      } else {
        showSnack("เกิดข้อผิดพลาด: HTTP ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      showSnack("เกิดข้อผิดพลาดในการเชื่อมต่อ: $e");
    }
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('สมัครสมาชิก - ผู้ใช้ทั่วไป'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            header("ข้อมูลผู้ใช้งาน"),
            inputField("ชื่อผู้ใช้งาน", controller: usernameController),
            inputField("อีเมล", controller: emailController),
            inputField("เบอร์โทรศัพท์", controller: phoneController),
            inputField("หมู่บ้าน", controller: villageController),
            dropdownField("จังหวัด", selectedProvince, provinces, (val) {
              setState(() {
                selectedProvince = val;
                selectedDistrict = null;
                selectedSubdistrict = null;
                districts = [];
                subdistricts = [];
              });
              if (val != null) loadDistricts(val);
            }),
            dropdownField("อำเภอ", selectedDistrict, districts, (val) {
              setState(() {
                selectedDistrict = val;
                selectedSubdistrict = null;
                subdistricts = [];
              });
              if (val != null) loadSubdistricts(val);
            }),
            dropdownField("ตำบล", selectedSubdistrict, subdistricts, (val) {
              setState(() => selectedSubdistrict = val);
            }),
            header("รหัสผ่าน"),
            inputField("รหัสผ่าน",
                controller: passwordController, obscureText: true),
            inputField("ยืนยันรหัสผ่าน",
                controller: confirmPasswordController, obscureText: true),
            Row(
              children: [
                Checkbox(
                  value: acceptTerms,
                  activeColor: gradientEnd,
                  onChanged: (value) =>
                      setState(() => acceptTerms = value ?? false),
                ),
                const Expanded(
                    child: Text("ฉันยอมรับข้อตกลงและนโยบายการใช้งาน")),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient:
                        LinearGradient(colors: [gradientStart, gradientEnd]),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("สมัครสมาชิก",
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget header(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryBrown)),
      );

  Widget inputField(String label,
      {TextEditingController? controller, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: lightBrown.withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget dropdownField(String label, String? value, List list,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value:
            list.any((item) => item['id'].toString() == value) ? value : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: lightBrown.withOpacity(0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: list.map<DropdownMenuItem<String>>((item) {
          return DropdownMenuItem<String>(
            value: item['id'].toString(),
            child: Text(item['name_th']),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
