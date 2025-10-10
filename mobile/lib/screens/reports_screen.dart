import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('报告'),
      ),
      body: const Center(
        child: Text(
          '报告功能开发中...',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
