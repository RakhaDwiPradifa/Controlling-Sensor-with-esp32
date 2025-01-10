import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const HomePage({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  // Fetch data from the API endpoint
  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      // Fetch data from the /api endpoint
      final response = await _fetchSensorData('/api');
      debugPrint('Response from API: $response');  // Add log to see the response

      setState(() {
        // Ensure we get the latest data based on timestamp or recency
        _mq135Value = _getSensorValue(response, 'MQ135');
        _dht11Temperature = _getSensorValue(response, 'DHT11_temperature');
        _dht11Humidity = _getSensorValue(response, 'DHT11_humidity');
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _mq135Value = 'Error fetching data';
        _dht11Temperature = 'Error fetching data';
        _dht11Humidity = 'Error fetching data';
      });
      debugPrint('Error fetching data: $e');
    }
  }

  // Fetch data from the given API endpoint
  Future<List<Map<String, dynamic>>> _fetchSensorData(String endpoint) async {
    final response = await http.get(Uri.parse('https://nodejs-with-vercel.vercel.app$endpoint'));
    if (response.statusCode == 200) {
      // Assuming the response is a list of sensor readings
      List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(json.decode(response.body));

      // Sort data to ensure we always get the most recent entry
      data.sort((a, b) {
        // Compare based on timestamp field (assuming 'timestamp' is available)
        return DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp']));
      });

      return data;
    } else {
      throw Exception('Failed to fetch data from $endpoint');
    }
  }

  // Function to find the value for a specific sensor
  String _getSensorValue(List<Map<String, dynamic>> response, String sensorName) {
    try {
      // Debugging log for checking response
      debugPrint('Response: $response');

      // Find the most recent sensor data for the specified sensor name
      for (var sensorData in response) {
        debugPrint('Sensor Data: $sensorData'); // Log each sensor data

        if (sensorData['sensor'] == 'DHT11') {
          if (sensorName == 'DHT11_temperature') {
            // For DHT11, return the temperature field
            return sensorData['temperature']?.toString() ?? 'N/A';
          } else if (sensorName == 'DHT11_humidity') {
            // For DHT11, return the humidity field
            return sensorData['humidity']?.toString() ?? 'N/A';
          }
        } else if (sensorData['sensor'] == 'MQ135' && sensorName == 'MQ135') {
          // For MQ135, return the value field
          return sensorData['value']?.toString() ?? 'N/A';
        }
      }
      return 'Sensor data not found'; // Return this if the sensor name is not found in the response
    } catch (e) {
      debugPrint('Error while parsing sensor value: $e');
      return 'Error fetching data'; // Return error message if an exception occurs
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = widget.isDarkMode ? const Color(0xFF0F151A) : const Color(0xFF0F151A);
    final cardColor = widget.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFF0F151A);
    const textColor = Colors.white;  // White text color for all modes

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: TextStyle(color: textColor), // White text color
        ),
        backgroundColor: headerColor, // Header color
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())  // Show loading indicator while data is being fetched
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Display MQ135 sensor data
                  Card(
                    color: cardColor, // Card color
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        'MQ135 Sensor Value',
                        style: TextStyle(color: textColor), // White text
                      ),
                      subtitle: Text(
                        'Latest reading: $_mq135Value',
                        style: TextStyle(color: textColor), // White text
                      ),
                    ),
                  ),
                  // Display DHT11 temperature data
                  Card(
                    color: cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        'DHT11 Temperature',
                        style: TextStyle(color: textColor), // White text
                      ),
                      subtitle: Text(
                        'Temperature: $_dht11Temperature°C',
                        style: TextStyle(color: textColor), // White text
                      ),
                    ),
                  ),
                  // Display DHT11 humidity data
                  Card(
                    color: cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        'DHT11 Humidity',
                        style: TextStyle(color: textColor), // White text
                      ),
                      subtitle: Text(
                        'Humidity: $_dht11Humidity%',
                        style: TextStyle(color: textColor), // White text
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
