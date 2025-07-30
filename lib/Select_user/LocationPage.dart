import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  final MapController _mapController = MapController();
  final String maptilerApiKey = 'Y8g2eswyXF5l1B1LSOMD';

  LatLng _mapCenter = LatLng(13.7563, 100.5018); // กรุงเทพฯ เริ่มต้น
  bool hasConfirmedLocation = false;
  bool isLoadingCoordinates = false;

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
    _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    _mapController.move(LatLng(position.latitude, position.longitude), 15);
    setState(() {
      _mapCenter = LatLng(position.latitude, position.longitude);
    });
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

  Future<void> loadSubdistricts(String districtId) async {
    try {
      final uri = Uri.parse("http://localhost/flutter_fire/subdistricts.php");
      final res = await http.post(uri, body: {"amphure_id": districtId});
      if (res.statusCode == 200) {
        final responseData = json.decode(res.body);
        if (responseData['status'] == 'success') {
          setState(() {
            subdistricts = responseData['data'];
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

  Future<LatLng?> fetchCoordinates(
      String province, String district, String subdistrict) async {
    Future<LatLng?> tryQuery(String query) async {
      final encodedQuery = Uri.encodeComponent(query);
      final url =
          'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1';

      try {
        final res = await http.get(Uri.parse(url), headers: {
          'User-Agent': 'fireburn1_app_example',
          'Accept-Language': 'th',
        });
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data is List && data.isNotEmpty) {
            final lat = double.tryParse(data[0]['lat']);
            final lon = double.tryParse(data[0]['lon']);
            if (lat != null && lon != null) {
              return LatLng(lat, lon);
            }
          }
        }
      } catch (e) {
        print('Geocoding error: $e');
      }
      return null;
    }

    if (subdistrict.isNotEmpty) {
      final query =
          '$subdistrict ตำบล, $district อำเภอ, $province จังหวัด, ประเทศไทย';
      final result = await tryQuery(query);
      if (result != null) return result;
    }

    if (district.isNotEmpty) {
      final query = '$district อำเภอ, $province จังหวัด, ประเทศไทย';
      final result = await tryQuery(query);
      if (result != null) return result;
    }

    final query = '$province จังหวัด, ประเทศไทย';
    return await tryQuery(query);
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _onMapMoved(MapPosition position, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        _mapCenter = position.center!;
        hasConfirmedLocation = false;
        selectedProvince = null;
        selectedDistrict = null;
        selectedSubdistrict = null;
        districts = [];
        subdistricts = [];
      });
    }
  }

  void openLocationFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String? tempSelectedProvince = selectedProvince;
        String? tempSelectedDistrict = selectedDistrict;
        String? tempSelectedSubdistrict = selectedSubdistrict;
        List tempDistricts = districts;
        List tempSubdistricts = subdistricts;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('เลือกตำแหน่ง (จังหวัด/อำเภอ/ตำบล)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tempSelectedProvince != null &&
                              provinces.any((e) =>
                                  e['id'].toString() == tempSelectedProvince)
                          ? tempSelectedProvince
                          : null,
                      decoration: InputDecoration(
                        labelText: 'จังหวัด',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: provinces.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'].toString(),
                          child: Text(item['name_th']),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        setModalState(() {
                          tempSelectedProvince = val;
                          tempSelectedDistrict = null;
                          tempSelectedSubdistrict = null;
                          tempDistricts = [];
                          tempSubdistricts = [];
                        });
                        if (val != null) {
                          final uri = Uri.parse(
                              "http://localhost/flutter_fire/districts.php");
                          final res =
                              await http.post(uri, body: {"province_id": val});
                          if (res.statusCode == 200) {
                            final responseData = json.decode(res.body);
                            if (responseData['status'] == 'success') {
                              setModalState(() {
                                tempDistricts = responseData['data'];
                              });
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tempSelectedDistrict != null &&
                              tempDistricts.any((e) =>
                                  e['id'].toString() == tempSelectedDistrict)
                          ? tempSelectedDistrict
                          : null,
                      decoration: InputDecoration(
                        labelText: 'อำเภอ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items:
                          tempDistricts.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'].toString(),
                          child: Text(item['name_th']),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        setModalState(() {
                          tempSelectedDistrict = val;
                          tempSelectedSubdistrict = null;
                          tempSubdistricts = [];
                        });
                        if (val != null) {
                          final uri = Uri.parse(
                              "http://localhost/flutter_fire/subdistricts.php");
                          final res =
                              await http.post(uri, body: {"amphure_id": val});
                          if (res.statusCode == 200) {
                            final responseData = json.decode(res.body);
                            if (responseData['status'] == 'success') {
                              setModalState(() {
                                tempSubdistricts = responseData['data'];
                              });
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tempSelectedSubdistrict != null &&
                              tempSubdistricts.any((e) =>
                                  e['id'].toString() == tempSelectedSubdistrict)
                          ? tempSelectedSubdistrict
                          : null,
                      decoration: InputDecoration(
                        labelText: 'ตำบล',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: tempSubdistricts
                          .map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'].toString(),
                          child: Text(item['name_th']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          tempSelectedSubdistrict = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (tempSelectedProvince == null ||
                            tempSelectedDistrict == null ||
                            tempSelectedSubdistrict == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'กรุณาเลือก จังหวัด, อำเภอ และตำบล ให้ครบถ้วน')),
                          );
                          return;
                        }

                        Navigator.pop(context); // ปิด bottom sheet ก่อน

                        setState(() {
                          selectedProvince = tempSelectedProvince;
                          selectedDistrict = tempSelectedDistrict;
                          selectedSubdistrict = tempSelectedSubdistrict;
                          districts = tempDistricts;
                          subdistricts = tempSubdistricts;
                          hasConfirmedLocation = false;
                          isLoadingCoordinates = true;
                        });

                        final sub = subdistricts.firstWhere(
                            (e) => e['id'].toString() == selectedSubdistrict,
                            orElse: () => null);
                        final district = districts.firstWhere(
                            (e) => e['id'].toString() == selectedDistrict,
                            orElse: () => null);
                        final province = provinces.firstWhere(
                            (e) => e['id'].toString() == selectedProvince,
                            orElse: () => null);

                        if (province == null ||
                            district == null ||
                            sub == null) {
                          showSnack('ข้อมูลจังหวัด อำเภอ หรือตำบลไม่ครบถ้วน');
                          setState(() {
                            isLoadingCoordinates = false;
                          });
                          return;
                        }

                        final latLng = await fetchCoordinates(
                            province['name_th'],
                            district['name_th'],
                            sub['name_th']);

                        setState(() {
                          isLoadingCoordinates = false;
                        });

                        if (latLng != null) {
                          _mapController.move(latLng, 15);
                          setState(() {
                            _mapCenter = latLng;
                          });
                        } else {
                          showSnack('ไม่พบพิกัดตำบลนี้');
                        }
                      },
                      child: const Text('เลือก'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        foregroundColor: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกตำแหน่ง'),
        backgroundColor: const Color(0xFFEF6C00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            tooltip: 'เลือกจังหวัด/อำเภอ/ตำบล',
            onPressed: openLocationFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          if (isLoadingCoordinates) const LinearProgressIndicator(),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _mapCenter,
                    zoom: 15,
                    onPositionChanged: _onMapMoved,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.png?key=$maptilerApiKey',
                      additionalOptions: {'key': maptilerApiKey},
                      userAgentPackageName: 'com.example.fireburn1_app',
                    ),
                  ],
                ),
                Center(
                  child: Icon(
                    Icons.location_on,
                    size: 50,
                    color: Colors.red.shade700,
                  ),
                ),
                Positioned(
                  bottom: 80,
                  right: 12,
                  child: FloatingActionButton(
                    heroTag: 'current_location_btn',
                    mini: true,
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    onPressed: _moveToCurrentLocation,
                    tooltip: 'ตำแหน่งปัจจุบัน',
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'พิกัดที่เลือก: ${_mapCenter.latitude.toStringAsFixed(6)}, ${_mapCenter.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, {
                      'latitude': _mapCenter.latitude,
                      'longitude': _mapCenter.longitude,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF6C00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('ยืนยันตำแหน่ง'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
