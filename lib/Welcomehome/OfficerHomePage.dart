import 'package:flutter/material.dart';

class OfficerHomePage extends StatelessWidget {
  const OfficerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เจ้าหน้าที่รัฐ')),
      body: const Center(child: Text('Welcome, Officer!')),
    );
  }
}
