import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SensorDataPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const SensorDataPage({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  _SensorDataPageState createState() => _SensorDataPageState();
}

class _SensorDataPageState extends State<SensorDataPage> {
  String _mq135Value = "Loading...";
  String _dht11Temperature = "Loading...";
  String _dht11Humidity = "Loading...";
  bool _loading = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Refresh data every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Function to fetch sensor data from the API
  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final mq135Response = await _fetchSensorData('/sensor/mq135');
      final dht11Response = await _fetchSensorData('/sensor/dht11');
      
      setState(() {
        _mq135Value = mq135Response['value'].toString();
        _dht11Temperature = dht11Response['temperature'].toString();
        _dht11Humidity = dht11Response['humidity'].toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _mq135Value = 'Error fetching data';
        _dht11Temperature = 'Error fetching data';
        _dht11Humidity = 'Error fetching data';
      });
    }
  }

  // Function to fetch sensor data from API using the given endpoint
  Future<Map<String, dynamic>> _fetchSensorData(String endpoint) async {
    // Update URL to match the new API
    final response = await http.get(Uri.parse('https://nodejs-with-vercel.vercel.app/api$endpoint'));  // Updated URL
    if (response.statusCode == 200) {
      return json.decode(response.body);  // Parse the JSON data from the response
    } else {
      throw Exception('Failed to fetch data from $endpoint');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define card and text color based on the theme (dark or light)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Data'),
        backgroundColor: const Color(0xFF0F151A), // Main header color
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())  // Show loading indicator while fetching data
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Card to display MQ135 sensor data
                  Card(
                    color: cardColor,
                    child: ListTile(
                      title: Text(
                        'Sensor MQ135 Value',
                        style: TextStyle(color: textColor), // Text color based on theme
                      ),
                      subtitle: Text(
                        'Latest reading: $_mq135Value',
                        style: TextStyle(color: textColor), // Text color based on theme
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Card to display temperature and humidity from DHT11 sensor
                  Card(
                    color: cardColor,
                    child: ListTile(
                      title: Text(
                        'DHT11 Temperature & Humidity',
                        style: TextStyle(color: textColor), // Text color based on theme
                      ),
                      subtitle: Text(
                        'Latest readings: Temp $_dht11Temperature°C, Hum $_dht11Humidity%',
                        style: TextStyle(color: textColor), // Text color based on theme
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
