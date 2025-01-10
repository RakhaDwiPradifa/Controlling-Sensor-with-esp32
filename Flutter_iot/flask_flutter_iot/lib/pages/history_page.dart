import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<Map<String, dynamic>> _sensorHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  // Fetch history data from the API
  Future<void> _fetchHistoryData() async {
    setState(() => _loading = true);
    try {
      final response = await _fetchSensorData('/api');

      final List<Map<String, dynamic>> history = List<Map<String, dynamic>>.from(response);

      setState(() {
        _sensorHistory.clear();
        // Reverse the order of the history so the latest data comes first
        history.reversed.forEach((data) {
          _sensorHistory.add({
            'timestamp': DateTime.parse(data['timestamp']).toString(),
            'mq135': data['value'].toString(),  // Assuming MQ135 value is stored under 'value'
            'temperature': data['temperature'].toString(),  // Assuming temperature is inside the response
            'humidity': data['humidity'].toString(),  // Assuming humidity is inside the response
          });
        });
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      debugPrint('Error fetching history data: $e');
    }
  }

  // Fetch data from the given API endpoint
  Future<List<Map<String, dynamic>>> _fetchSensorData(String endpoint) async {
    final url = 'https://nodejs-with-vercel.vercel.app$endpoint';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch data from $endpoint');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFF0F151A);
    const textColor = Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sensor History',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: const Color(0xFF0F151A),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _sensorHistory.length,
              itemBuilder: (context, index) {
                final history = _sensorHistory[index];
                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(
                      'Timestamp: ${history['timestamp']}',
                      style: TextStyle(color: textColor),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MQ135 Value: ${history['mq135']}',
                          style: TextStyle(color: textColor),
                        ),
                        Text(
                          'Temperature: ${history['temperature']}°C',
                          style: TextStyle(color: textColor),
                        ),
                        Text(
                          'Humidity: ${history['humidity']}%',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchHistoryData,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
