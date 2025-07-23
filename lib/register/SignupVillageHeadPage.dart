import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      final response =
          await rootBundle.loadString('assets/api/thai_provinces.json');
      final data = json.decode(response);
      setState(() {
        provinces = data;
      });
    } catch (e) {
      print('Error loading provinces: $e');
    }
  }

  Future<void> loadDistricts(String provinceId) async {
    try {
      final response =
          await rootBundle.loadString('assets/api/thai_amphures.json');
      final data = json.decode(response);
      setState(() {
        districts = data
            .where((d) => d['province_id'].toString() == provinceId)
            .toList();
        selectedDistrict = null;
        subdistricts = [];
        selectedSubdistrict = null;
      });
    } catch (e) {
      print('Error loading districts: $e');
    }
  }

  Future<void> loadSubdistricts(String districtId) async {
    try {
      final response =
          await rootBundle.loadString('assets/api/thai_tambons.json');
      final data = json.decode(response);
      setState(() {
        subdistricts = data
            .where((s) => s['amphure_id'].toString() == districtId)
            .toList();
        selectedSubdistrict = null;
      });
    } catch (e) {
      print('Error loading subdistricts: $e');
    }
  }

  Future<void> registerVillageHead() async {
    if (!acceptTerms) {
      showSnack("กรุณายอมรับข้อตกลง");
      return;
    }

    if (usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        villageController.text.isEmpty ||
        selectedProvince == null ||
        selectedDistrict == null ||
        selectedSubdistrict == null ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      showSnack("กรุณากรอกข้อมูลให้ครบทุกช่อง");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showSnack('รหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() => isLoading = true);

    // แปลง selectedProvince (id) เป็น ชื่อจังหวัด
    String provinceName = '';
    if (selectedProvince != null) {
      final prov = provinces.firstWhere(
        (p) => p['id'].toString() == selectedProvince,
        orElse: () => null,
      );
      provinceName = prov != null ? prov['name_th'] : '';
    }

    // แปลง selectedDistrict (id) เป็น ชื่ออำเภอ
    String districtName = '';
    if (selectedDistrict != null) {
      final dist = districts.firstWhere(
        (d) => d['id'].toString() == selectedDistrict,
        orElse: () => null,
      );
      districtName = dist != null ? dist['name_th'] : '';
    }

    // selectedSubdistrict เก็บชื่ออยู่แล้ว เพราะตอนสร้าง dropdown ใช้ชื่อเป็น value
    String subdistrictName = selectedSubdistrict ?? '';

    final url = Uri.parse('http://localhost/flutter_fire/register_village.php');

    try {
      final response = await http.post(
        url,
        body: {
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'village': villageController.text.trim(),
          'subdistrict': subdistrictName,
          'district': districtName,
          'province': provinceName,
          'password': passwordController.text,
        },
      );

      final result = json.decode(response.body);

      showSnack(result['message'] ?? 'เกิดข้อผิดพลาด');

      if (result['status'] == 'success') {
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        });
      }
    } catch (e) {
      showSnack("เกิดข้อผิดพลาดในการเชื่อมต่อ: $e");
    }

    setState(() => isLoading = false);
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    villageController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'สมัครสมาชิก - ผู้ใหญ่บ้าน',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
            dropdownField(
              label: "จังหวัด",
              value: selectedProvince,
              items: provinces.map<DropdownMenuItem<String>>((prov) {
                return DropdownMenuItem<String>(
                  value: prov['id'].toString(),
                  child: Text(prov['name_th']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedProvince = value);
                loadDistricts(value!);
              },
            ),
            dropdownField(
              label: "อำเภอ",
              value: selectedDistrict,
              items: districts.map<DropdownMenuItem<String>>((dist) {
                return DropdownMenuItem<String>(
                  value: dist['id'].toString(),
                  child: Text(dist['name_th']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedDistrict = value);
                loadSubdistricts(value!);
              },
            ),
            dropdownField(
              label: "ตำบล",
              value: selectedSubdistrict,
              items: subdistricts.map<DropdownMenuItem<String>>((sub) {
                return DropdownMenuItem<String>(
                  value: sub['name_th'],
                  child: Text(sub['name_th']),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedSubdistrict = value),
            ),
            const SizedBox(height: 10),
            header("รหัสผ่าน"),
            inputField('รหัสผ่าน',
                obscureText: true, controller: passwordController),
            inputField('ยืนยันรหัสผ่าน',
                obscureText: true, controller: confirmPasswordController),
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
                onPressed: isLoading
                    ? null
                    : () {
                        if (!acceptTerms) {
                          showSnack("กรุณายอมรับข้อตกลง");
                          return;
                        }
                        registerVillageHead();
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
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
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
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
        style: TextStyle(
            color: primaryBrown, fontSize: 16, fontWeight: FontWeight.w700),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  Widget dropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value?.isEmpty == true ? null : value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: primaryBrown),
          filled: true,
          fillColor: lightBrown.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: gradientEnd),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: gradientStart, width: 2),
          ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
