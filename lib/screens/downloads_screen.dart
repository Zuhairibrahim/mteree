import 'package:flutter/material.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("التنزيلات")),
      body: const Center(
        child: Text("جاهزة لاحقًا: تنزيلات + إدارة ملفات"),
      ),
    );
  }
}
