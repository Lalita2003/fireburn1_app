import 'package:flutter/material.dart';

class RequestListPage extends StatelessWidget {
  const RequestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> requests = [
      {
        'date': '30 ก.ค. 2025',
        'status': 'อนุมัติแล้ว',
        'location': 'เชียงใหม่'
      },
      {'date': '28 ก.ค. 2025', 'status': 'รอดำเนินการ', 'location': 'ลำพูน'},
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ ไม่มีปุ่มย้อนกลับ
        title: const Text('รายการคำขอ'),
        centerTitle: true,
        backgroundColor: const Color(0xFFEF6C00),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.local_fire_department_outlined,
                  color: Colors.orange),
              title: Text(request['location']!),
              subtitle: Text('วันที่ขอ: ${request['date']}'),
              trailing: Text(
                request['status']!,
                style: TextStyle(
                  color: request['status'] == 'อนุมัติแล้ว'
                      ? Colors.green
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
