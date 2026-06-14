import 'package:flutter/material.dart';

class SettingsDetailScreen extends StatelessWidget {
  const SettingsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Manage app preferences, appearance, and timers here.'),
          ],
        ),
      ),
    );
  }
}
