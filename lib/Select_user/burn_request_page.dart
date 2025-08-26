import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BurnRequestPage extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final int userId; // ✅ รับ userId ของผู้ใช้

  const BurnRequestPage(
      {super.key, this.latitude, this.longitude, required this.userId});

  @override
  State<BurnRequestPage> createState() => _BurnRequestPageState();
}

class _BurnRequestPageState extends State<BurnRequestPage> {
  final _formKey = GlobalKey<FormState>();

  // ตัวแปรเก็บข้อมูล
  String? areaName;
  double? areaSize;
  double? latitude;
  double? longitude;
  DateTime? requestDate;
  TimeOfDay? timeFrom;
  TimeOfDay? timeTo;
  String? purpose;
  String? cropType;

  @override
  void initState() {
    super.initState();
    latitude = widget.latitude;
    longitude = widget.longitude;
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.Hm().format(dt);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 14)),
    );
    if (picked != null) {
      setState(() {
        requestDate = picked;
      });
    }
  }

  Future<void> _selectTimeFrom() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        timeFrom = picked;
      });
    }
  }

  Future<void> _selectTimeTo() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        timeTo = picked;
      });
    }
  }

  InputDecoration buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFEF6C00)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFDD6B00), width: 2),
      ),
    );
  }

  // ✅ ฟังก์ชันบันทึกข้อมูลลง DB ผ่าน API
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final body = {
      "user_id": widget.userId,
      "area_name": areaName,
      "area_size": areaSize,
      "location_lat": latitude,
      "location_lng": longitude,
      "request_date": DateFormat('yyyy-MM-dd').format(requestDate!),
      "time_slot_from":
          "${timeFrom!.hour.toString().padLeft(2, '0')}:${timeFrom!.minute.toString().padLeft(2, '0')}:00",
      "time_slot_to":
          "${timeTo!.hour.toString().padLeft(2, '0')}:${timeTo!.minute.toString().padLeft(2, '0')}:00",
      "purpose": purpose,
      "crop_type": cropType,
      "status": "pending", // ✅ ค่าเริ่มต้น
    };

    try {
      final res = await http.post(
        Uri.parse(
            "http://localhost/flutter_fire/burn_request.php"), // ✅ แก้เป็น API จริง
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      print('Status code: ${res.statusCode}');
      print('Body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final burnRequestId = data['id'];

        // อัปเดต weather_logs สำหรับ forecast_date ที่ตรงกัน
        try {
          final updateRes = await http.post(
            Uri.parse("http://localhost/flutter_fire/save_weather_log.php"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "burn_request_id": burnRequestId,
              "forecast_date": DateFormat('yyyy-MM-dd').format(requestDate!)
            }),
          );
          print(
              'Update weather_logs status: ${updateRes.statusCode}, body: ${updateRes.body}');
        } catch (e) {
          print('Error updating weather_logs: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("✅ ส่งคำขอสำเร็จ"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // กลับไปหน้าเดิม + refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("❌ เกิดข้อผิดพลาด: ${res.body}"),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error: $e'); // ✅ ปริ้น error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("❌ ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์: $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        title: const Text('ขออนุญาตเผา'),
        backgroundColor: const Color(0xFFDD6B00),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'กรอกข้อมูลการขอเผา',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF6C00)),
              ),
              const SizedBox(height: 16),

              // ชื่อพื้นที่
              TextFormField(
                decoration:
                    buildInputDecoration('ชื่อพื้นที่ (เช่น ไร่อ้อยข้างบ้าน)'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกชื่อพื้นที่' : null,
                onSaved: (val) => areaName = val,
              ),
              const SizedBox(height: 12),

              // ขนาดพื้นที่
              TextFormField(
                decoration: buildInputDecoration('ขนาดพื้นที่ (ไร่)'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  final d = double.tryParse(val ?? '');
                  if (d == null || d <= 0)
                    return 'กรุณากรอกขนาดพื้นที่ให้ถูกต้อง';
                  return null;
                },
                onSaved: (val) => areaSize = double.parse(val!),
              ),
              const SizedBox(height: 12),

              // ละติจูด
              TextFormField(
                initialValue: widget.latitude?.toString() ?? '',
                decoration: buildInputDecoration('ละติจูด (Latitude)'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกละติจูด' : null,
                onSaved: (val) => latitude = double.parse(val!),
              ),
              const SizedBox(height: 12),

              // ลองจิจูด
              TextFormField(
                initialValue: widget.longitude?.toString() ?? '',
                decoration: buildInputDecoration('ลองจิจูด (Longitude)'),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกลองจิจูด' : null,
                onSaved: (val) => longitude = double.parse(val!),
              ),
              const SizedBox(height: 12),

              // วันที่ต้องการเผา
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: buildInputDecoration('วันที่ต้องการเผา'),
                    controller: TextEditingController(
                      text: requestDate == null
                          ? ''
                          : DateFormat('yyyy-MM-dd').format(requestDate!),
                    ),
                    validator: (val) => requestDate == null
                        ? 'กรุณาเลือกวันที่ต้องการเผา'
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // เวลาเริ่มเผา
              GestureDetector(
                onTap: _selectTimeFrom,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: buildInputDecoration('เวลาเริ่มเผา'),
                    controller: TextEditingController(
                      text: timeFrom == null ? '' : formatTime(timeFrom),
                    ),
                    validator: (val) =>
                        timeFrom == null ? 'กรุณาเลือกเวลาเริ่มเผา' : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // เวลาสิ้นสุดเผา
              GestureDetector(
                onTap: _selectTimeTo,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: buildInputDecoration('เวลาสิ้นสุดเผา'),
                    controller: TextEditingController(
                      text: timeTo == null ? '' : formatTime(timeTo),
                    ),
                    validator: (val) =>
                        timeTo == null ? 'กรุณาเลือกเวลาสิ้นสุดเผา' : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // เหตุผล
              TextFormField(
                decoration: buildInputDecoration('เหตุผลในการเผา'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกเหตุผล' : null,
                onSaved: (val) => purpose = val,
              ),
              const SizedBox(height: 12),

              // ประเภทพืช
              TextFormField(
                decoration: buildInputDecoration('ประเภทพืช (เช่น ข้าวโพด)'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'กรุณากรอกประเภทพืช' : null,
                onSaved: (val) => cropType = val,
              ),
              const SizedBox(height: 24),

              // ปุ่มส่งคำขอ
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.fireplace, color: Colors.white),
                  label: const Text(
                    'ส่งคำขอ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF6C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submitRequest, // ✅ กดแล้วส่งไป DB
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
