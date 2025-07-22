import 'package:flutter/material.dart';

class VillageHeadHomePage extends StatelessWidget {
  const VillageHeadHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ผู้ใหญ่บ้าน')),
      body: const Center(child: Text('Welcome, Village Head!')),
    );
  }
}