import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class WeatherForecastPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  const WeatherForecastPage({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<WeatherForecastPage> createState() => _WeatherForecastPageState();
}

class _WeatherForecastPageState extends State<WeatherForecastPage> {
  bool isLoading = false;
  Map<String, List<HourlyWeather>> groupedForecast = {};
  double rai = 0.0;
  String errorMsg = '';
  late TextEditingController raiController;

  Set<DateTime> selectedHours = {};
  Set<DateTime> disabledHours = {};

  // ------------ Box Model Functions ------------
  double raiToAcre(double rai) => rai * 0.39525691699605;
  double acreToAreaM2(double acre) => acre * 4046.85642;
  double calculateEmissionRate(double acre) => (4.0e7 * acre / 24) / 3600;
  double calculateWidth(double areaM2) => sqrt(areaM2) * (sqrt(2) / 2);

  double? calculatePM25(double rai, double windSpeed, double mixingHeight) {
    if (windSpeed == 0 || mixingHeight == 0) return null;
    final acre = raiToAcre(rai);
    final areaM2 = acreToAreaM2(acre);
    final P = calculateEmissionRate(acre);
    final W = calculateWidth(areaM2);
    final b = mixingHeight;
    final resultMgM3 = P / (windSpeed * W * b);
    return resultMgM3 * 1000; // µg/m³
  }

  String classifyPM25(double pm25) {
    if (pm25 <= 15) return "🔵 ดีมาก";
    if (pm25 <= 25) return "🟢 ดี";
    if (pm25 <= 37.5) return "🟡 ปานกลาง";
    if (pm25 <= 50) return "🟠 เริ่มมีผลกระทบต่อสุขภาพ";
    return "🔴 มีผลกระทบต่อสุขภาพ";
  }

  // ------------ Fetch Weather Data ------------
  Future<List<HourlyWeather>> fetchWeatherData(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=wind_speed_10m,boundary_layer_height,temperature_2m,relativehumidity_2m&timezone=auto');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception("ไม่สามารถดึงข้อมูลจาก Open-Meteo API");
    }

    final data = json.decode(res.body);
    final times = List<String>.from(data['hourly']['time']);
    final windSpeeds = List<double>.from(
        (data['hourly']['wind_speed_10m'] as List).map((e) => e.toDouble()));
    final mixingHeights = List<double>.from(
        (data['hourly']['boundary_layer_height'] as List)
            .map((e) => e.toDouble()));
    final temperatures = List<double>.from(
        (data['hourly']['temperature_2m'] as List).map((e) => e.toDouble()));
    final humidities = List<double>.from(
        (data['hourly']['relativehumidity_2m'] as List)
            .map((e) => e.toDouble()));

    List<HourlyWeather> list = [];
    for (int i = 0; i < times.length; i++) {
      list.add(HourlyWeather(
          time: DateTime.parse(times[i]),
          windSpeed: windSpeeds[i],
          mixingHeight: mixingHeights[i],
          temperature: temperatures[i],
          humidity: humidities[i]));
    }
    return list;
  }

  // ------------ Fetch Disabled Hours from PHP ------------
  Future<void> fetchDisabledHours() async {
    try {
      final url =
          Uri.parse("http://localhost/flutter_fire/get_selected_hours.php");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] ?? [];
        Set<DateTime> temp = {};
        for (var item in data) {
          final dateParts = item['forecast_date'].split('-');
          final hour = int.parse(item['forecast_hour'].split(':')[0]);
          temp.add(DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            hour,
          ));
        }
        setState(() {
          disabledHours = temp;
        });
      }
    } catch (e) {
      print("ไม่สามารถดึง disabled hours: $e");
    }
  }

  void loadForecast() async {
    if (rai <= 0) {
      setState(() {
        errorMsg = "กรุณากรอกจำนวนไร่ให้ถูกต้องก่อนโหลดข้อมูล";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMsg = '';
      selectedHours.clear();
    });

    try {
      await fetchDisabledHours();

      final data = await fetchWeatherData(widget.latitude, widget.longitude);

      final filtered = data
          .where((item) => item.time.hour >= 6 && item.time.hour <= 18)
          .toList();

      Map<String, List<HourlyWeather>> grouped = {};
      for (var item in filtered) {
        final dayKey = "${item.time.day.toString().padLeft(2, '0')}/"
            "${item.time.month.toString().padLeft(2, '0')}/"
            "${item.time.year}";
        grouped.putIfAbsent(dayKey, () => []);
        grouped[dayKey]!.add(item);
      }

      setState(() {
        groupedForecast = grouped;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    raiController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    raiController.dispose();
    super.dispose();
  }

  Widget buildTableForDay(String date, List<HourlyWeather> hours) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📅 วันที่ $date",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF6C00)),
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FixedColumnWidth(60),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
                3: FixedColumnWidth(60),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFEF6C00)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('เวลา',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('PM2.5 (µg/m³)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('สถานะ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('เลือก',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center),
                    ),
                  ],
                ),
                ...hours.map((item) {
                  final pm25 =
                      calculatePM25(rai, item.windSpeed, item.mixingHeight);
                  final status =
                      pm25 == null ? '❌ ข้อมูลไม่ครบ' : classifyPM25(pm25);
                  final timeStr =
                      item.time.hour.toString().padLeft(2, '0') + ':00';

                  final isDisabled = disabledHours.any((h) =>
                      h.year == item.time.year &&
                      h.month == item.time.month &&
                      h.day == item.time.day &&
                      h.hour == item.time.hour);

                  final isSelected = selectedHours.any((h) =>
                      h.year == item.time.year &&
                      h.month == item.time.month &&
                      h.day == item.time.day &&
                      h.hour == item.time.hour);

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(timeStr, textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          pm25 == null ? '-' : pm25.toStringAsFixed(2),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(status, textAlign: TextAlign.center),
                      ),
                      Center(
                        child: Checkbox(
                          value: isSelected,
                          activeColor: Colors.black,
                          checkColor: Colors.white,
                          onChanged: isDisabled
                              ? null
                              : (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedHours.add(item.time);
                                    } else {
                                      selectedHours.removeWhere((h) =>
                                          h.year == item.time.year &&
                                          h.month == item.time.month &&
                                          h.day == item.time.day &&
                                          h.hour == item.time.hour);
                                    }
                                  });
                                },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void saveSelectedHours() async {
    if (selectedHours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ กรุณาเลือกชั่วโมงก่อนบันทึก")),
      );
      return;
    }

    List<Map<String, dynamic>> dataToSave = [];
    for (var date in groupedForecast.keys) {
      for (var hour in groupedForecast[date]!) {
        if (selectedHours.any((h) =>
            h.year == hour.time.year &&
            h.month == hour.time.month &&
            h.day == hour.time.day &&
            h.hour == hour.time.hour)) {
          dataToSave.add(hour.toMap(rai));
        }
      }
    }

    try {
      final url =
          Uri.parse("http://localhost/flutter_fire/save_weather_log.php");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"weather_logs": dataToSave}),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res["status"] == "success") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "✅ บันทึกข้อมูลเรียบร้อย (${dataToSave.length} ชั่วโมง)")),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ บันทึกไม่สำเร็จ: ${res['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ เซิร์ฟเวอร์ตอบกลับผิดพลาด")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ เกิดข้อผิดพลาด: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.latitude == 0 || widget.longitude == 0) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('พยากรณ์ฝุ่น PM2.5'),
          backgroundColor: const Color(0xFFEF6C00),
        ),
        body: const Center(
          child: Text(
            '⚠️ กรุณาเลือกตำแหน่งก่อนเพื่อดูค่าฝุ่น PM2.5',
            style: TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('พยากรณ์ฝุ่น PM2.5'),
        backgroundColor: const Color(0xFFEF6C00),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              'ตำแหน่ง: (${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)})',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('พื้นที่เผา (ไร่): '),
                SizedBox(
                  width: 120,
                  child: TextField(
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      hintText: 'กรอกไร่',
                    ),
                    controller: raiController,
                    onChanged: (val) {
                      setState(() {
                        rai = double.tryParse(val) ?? 0;
                      });
                    },
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      if (rai > 0) {
                        loadForecast();
                      } else {
                        setState(() {
                          groupedForecast = {};
                          errorMsg =
                              "กรุณากรอกจำนวนไร่ให้ถูกต้องก่อนโหลดข้อมูล";
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF6C00),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(50, 40),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Go',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: errorMsg.isNotEmpty
                  ? Center(
                      child: Text(errorMsg,
                          style: const TextStyle(color: Colors.red)),
                    )
                  : isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : groupedForecast.isEmpty
                          ? const Center(
                              child: Text("ยังไม่มีข้อมูล กรุณากรอกและโหลด"),
                            )
                          : ListView(
                              children: groupedForecast.entries
                                  .map((entry) =>
                                      buildTableForDay(entry.key, entry.value))
                                  .toList(),
                            ),
            ),
            if (groupedForecast.isNotEmpty)
              ElevatedButton.icon(
                onPressed: saveSelectedHours,
                icon: const Icon(
                  Icons.save,
                  color: Colors.white,
                ),
                label: const Text(
                  "บันทึกชั่วโมงที่เลือก",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffe59513),
                  minimumSize: const Size.fromHeight(45),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class HourlyWeather {
  final DateTime time;
  final double windSpeed;
  final double mixingHeight;
  final double temperature;
  final double humidity;

  HourlyWeather({
    required this.time,
    required this.windSpeed,
    required this.mixingHeight,
    this.temperature = 0,
    this.humidity = 0,
  });

  double pm25(double rai) {
    if (windSpeed == 0 || mixingHeight == 0) return 0;
    final acre = rai * 0.39525691699605;
    final areaM2 = acre * 4046.85642;
    final P = (4.0e7 * acre / 24) / 3600;
    final W = sqrt(areaM2) * (sqrt(2) / 2);
    final b = mixingHeight;
    return P / (windSpeed * W * b) * 1000;
  }

  Map<String, dynamic> toMap(double rai) {
    return {
      "fetch_time": DateTime.now().toIso8601String(),
      "forecast_date":
          "${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}",
      "forecast_hour": "${time.hour.toString().padLeft(2, '0')}:00:00",
      "temperature": temperature,
      "humidity": humidity,
      "wind_speed": windSpeed,
      "boundary_height": mixingHeight,
      "pm25_model": double.parse(pm25(rai).toStringAsFixed(2)),
    };
  }
}
