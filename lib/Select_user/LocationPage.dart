import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  LatLng? _selectedPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกตำแหน่งเพื่อวิเคราะห์ฝุ่น PM2.5'),
        backgroundColor: const Color(0xFFEF6C00),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(13.7563, 100.5018),
          zoom: 13,
          onTap: (tapPosition, point) {
            setState(() {
              _selectedPoint = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          if (_selectedPoint != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _selectedPoint!,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: _selectedPoint != null
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'พิกัดที่เลือก: ${_selectedPoint!.latitude.toStringAsFixed(6)}, ${_selectedPoint!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'ยืนยันตำแหน่ง: ${_selectedPoint!.latitude}, ${_selectedPoint!.longitude}',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF6C00),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('ยืนยันตำแหน่ง'),
                  ),
                ],
              ),
            )
          : const SizedBox(),
    );
  }
}