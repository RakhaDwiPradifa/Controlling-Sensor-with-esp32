import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const SettingsPage({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0F151A), // Warna utama biru
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: toggleTheme,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F151A), // Warna utama biru
            foregroundColor: Colors.white, // Warna teks putih
          ),
          child: Text(
            isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            style: const TextStyle(color: Colors.white), // Memastikan teks tetap putih
          ),
        ),
      ),
    );
  }
}
