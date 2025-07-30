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

  // ------------ Box Model Functions ------------
  double raiToAcre(double rai) => rai * 0.39525691699605;
  double acreToAreaM2(double acre) => acre * 4046.85642;
  double calculateEmissionRate(double acre) =>
      (4.0e7 * acre / 24) / 3600; // mg/s
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
    if (pm25 <= 37) return "🟡 ปานกลาง";
    if (pm25 <= 50) return "🟠 เริ่มมีผลกระทบต่อสุขภาพ";
    return "🔴 มีผลกระทบต่อสุขภาพ";
  }

  // ------------ Fetch Weather Data ------------
  Future<List<HourlyWeather>> fetchWeatherData(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=wind_speed_10m,boundary_layer_height&timezone=auto');
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

    List<HourlyWeather> list = [];
    for (int i = 0; i < times.length; i++) {
      list.add(HourlyWeather(
          time: DateTime.parse(times[i]),
          windSpeed: windSpeeds[i],
          mixingHeight: mixingHeights[i]));
    }
    return list;
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
    });

    try {
      final data = await fetchWeatherData(widget.latitude, widget.longitude);

      final filtered = data
          .where((item) => item.time.hour >= 6 && item.time.hour <= 18)
          .toList();

      Map<String, List<HourlyWeather>> grouped = {};
      for (var item in filtered) {
        final dayKey = "${item.time.day.toString().padLeft(2, '0')}/"
            "${item.time.month.toString().padLeft(2, '0')}/"
            "${item.time.year}";
        if (!grouped.containsKey(dayKey)) {
          grouped[dayKey] = [];
        }
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
                  ],
                ),
                ...hours.map((item) {
                  final pm25 =
                      calculatePM25(rai, item.windSpeed, item.mixingHeight);
                  final status =
                      pm25 == null ? '❌ ข้อมูลไม่ครบ' : classifyPM25(pm25);
                  final timeStr =
                      item.time.hour.toString().padLeft(2, '0') + ':00';

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

  HourlyWeather({
    required this.time,
    required this.windSpeed,
    required this.mixingHeight,
  });
}
