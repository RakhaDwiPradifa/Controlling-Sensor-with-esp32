import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class ChartPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const ChartPage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<FlSpot> _mq135DataPoints = [];
  List<FlSpot> _temperatureDataPoints = [];
  List<FlSpot> _humidityDataPoints = [];
  List<String> _labels = [];
  bool _loading = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchAllData());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Fetch data from the server and handle the response
  Future<void> _fetchAllData() async {
    setState(() => _loading = true);
    try {
      final response = await _fetchData('/api'); // URL endpoint utama
      debugPrint('Response from API: $response');  // Add log to see the response

      setState(() {
        // Ensure we get the latest data based on timestamp or recency
        _mq135DataPoints = _parseChartData(response, 'MQ135');
        _temperatureDataPoints = _parseChartData(response, 'DHT11_temperature');
        _humidityDataPoints = _parseChartData(response, 'DHT11_humidity');
        _labels = _parseLabels(response);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => _loading = false);
    }
  }

  // Fetch data from the given endpoint
  Future<List<Map<String, dynamic>>> _fetchData(String endpoint) async {
    final url = 'https://nodejs-with-vercel.vercel.app$endpoint'; // Endpoint for fetching data
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body)); // Return the response in JSON format
    } else {
      throw Exception('Failed to fetch data from $endpoint');
    }
  }

  // Parse chart data into FlSpot list
  List<FlSpot> _parseChartData(List<Map<String, dynamic>> response, String sensorName) {
    List<FlSpot> dataPoints = [];
    for (var i = 0; i < response.length; i++) {
      double value = 0;
      if (sensorName == 'MQ135') {
        value = double.tryParse(response[i]['value'].toString()) ?? 0;
      } else if (sensorName == 'DHT11_temperature') {
        value = double.tryParse(response[i]['temperature'].toString()) ?? 0;
      } else if (sensorName == 'DHT11_humidity') {
        value = double.tryParse(response[i]['humidity'].toString()) ?? 0;
      }
      dataPoints.add(FlSpot(i.toDouble(), value));
    }
    return dataPoints;
  }

  // Parse labels (timestamps) for chart
  List<String> _parseLabels(List<Map<String, dynamic>> response) {
    return response.map((data) {
      return DateTime.parse(data['timestamp']).toString();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final cardColor = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFF0F151A);
    const textColor = Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charts'),
        backgroundColor: const Color(0xFF0F151A),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildChartCard(
                      title: 'MQ135 Value',
                      dataPoints: _mq135DataPoints,
                      chartColor: Colors.pink,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 16),
                    _buildChartCard(
                      title: 'DHT11 Temperature (°C)',
                      dataPoints: _temperatureDataPoints,
                      chartColor: Colors.blue,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 16),
                    _buildChartCard(
                      title: 'DHT11 Humidity (%)',
                      dataPoints: _humidityDataPoints,
                      chartColor: Colors.orange,
                      cardColor: cardColor,
                      textColor: textColor,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Build chart card widget
  Widget _buildChartCard({
    required String title,
    required List<FlSpot> dataPoints,
    required Color chartColor,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        return index >= 0 && index < _labels.length
                            ? Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  _labels[index],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: dataPoints,
                    color: chartColor,
                    barWidth: 2,
                    belowBarData: BarAreaData(
                      show: true,
                      color: chartColor.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
