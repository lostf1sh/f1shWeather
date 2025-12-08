import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import '../constants/api_constants.dart';

class ForecastPage extends StatefulWidget {
  final String city;
  final bool useMetricSystem;

  const ForecastPage({
    super.key,
    required this.city,
    required this.useMetricSystem,
  });

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _forecast = [];
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _hourlyForecast = [];

  final String _apiKey = K_WEATHER_API_KEY;

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  Future<void> _fetchForecast() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse(
          'https://api.weatherapi.com/v1/forecast.json?key=$_apiKey&q=${Uri.encodeComponent(widget.city)}&days=5&aqi=no&alerts=no'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentWeather = {
            'temp': data['current']['temp_c'],
            'temp_f': data['current']['temp_f'],
            'feels_like': data['current']['feelslike_c'],
            'feels_like_f': data['current']['feelslike_f'],
            'humidity': data['current']['humidity'],
            'wind_kph': data['current']['wind_kph'],
            'wind_mph': data['current']['wind_mph'],
            'uv': data['current']['uv'],
            'condition': data['current']['condition'],
          };
          // Get next 24 hours (or as many as available for today/tomorrow overlap)
          // Simplified to next few hours for now from the first day
          // Better approach: combine hours from today and tomorrow
          List hours = [];
          if (data['forecast']['forecastday'].length > 0) {
             hours.addAll(data['forecast']['forecastday'][0]['hour']);
          }
          if (data['forecast']['forecastday'].length > 1) {
             hours.addAll(data['forecast']['forecastday'][1]['hour']);
          }

          final now = DateTime.now();
          // Filter hours after now
          _hourlyForecast = hours.where((h) {
            final t = DateTime.parse(h['time']); // 2024-01-01 00:00
            return t.isAfter(now);
          }).take(12).map<Map<String, dynamic>>((hour) => {
            'time': hour['time'].split(' ')[1],
            'temp_c': hour['temp_c'],
            'temp_f': hour['temp_f'],
            'icon': hour['condition']['icon'],
          }).toList();

          _forecast = (data['forecast']['forecastday'] as List)
              .map<Map<String, dynamic>>((day) => {
                    'date': day['date'],
                    'icon': day['day']['condition']['icon'],
                    'desc': day['day']['condition']['text'],
                    'min_c': day['day']['mintemp_c'],
                    'max_c': day['day']['maxtemp_c'],
                    'min_f': day['day']['mintemp_f'],
                    'max_f': day['day']['maxtemp_f'],
                    'humidity': day['day']['avghumidity'],
                    'uv': day['day']['uv'],
                    'chance_of_rain': day['day']['daily_chance_of_rain'],
                  })
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Could not fetch forecast data';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not fetch forecast data: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: TextStyle(color: colorScheme.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentDetails(),
                      const SizedBox(height: 32),
                      _buildHourlyForecast(),
                      const SizedBox(height: 32),
                      _buildDailyForecast(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentDetails() {
     if (_currentWeather == null) return const SizedBox.shrink();
     final colorScheme = Theme.of(context).colorScheme;

     return Container(
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
         color: colorScheme.surfaceContainerHighest,
         borderRadius: BorderRadius.circular(32),
       ),
       child: Column(
         children: [
           Text('Current Conditions',
             style: Theme.of(context).textTheme.titleMedium?.copyWith(
               color: colorScheme.onSurfaceVariant
             )
           ),
           const SizedBox(height: 16),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             children: [
               _buildDetailItem(Icons.thermostat, 'Feels Like',
                 widget.useMetricSystem
                   ? '${_currentWeather!['feels_like']}°'
                   : '${_currentWeather!['feels_like_f']}°'),
               _buildDetailItem(Icons.water_drop, 'Humidity', '${_currentWeather!['humidity']}%'),
               _buildDetailItem(Icons.sunny, 'UV Index', '${_currentWeather!['uv']}'),
             ],
           ),
         ],
       ),
     ).animate().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('Hourly Forecast',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold
              )),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _hourlyForecast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final hour = _hourlyForecast[index];
              return Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(50), // Pill shape
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hour['time'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    Image.network(
                      'https:${hour['icon']}',
                      width: 40,
                      height: 40,
                    ),
                    Text(
                      widget.useMetricSystem
                          ? '${hour['temp_c'].toStringAsFixed(0)}°'
                          : '${hour['temp_f'].toStringAsFixed(0)}°',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (50 * index).ms).slideX(begin: 0.2, curve: Curves.easeOut);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('Daily Forecast',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold
              )),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _forecast.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final day = _forecast[index];
            final date = DateTime.parse(day['date']);
            final weekDay = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(weekDay,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${date.day}/${date.month}',
                          style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Image.network(
                    'https:${day['icon']}',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day['desc'],
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium),
                        if (day['chance_of_rain'] > 0)
                        Row(
                          children: [
                            Icon(Icons.water_drop, size: 12, color: Colors.blue),
                            Text('${day['chance_of_rain']}%', style: TextStyle(fontSize: 12, color: Colors.blue)),
                          ],
                        )
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                       Text(
                        widget.useMetricSystem
                            ? '${day['max_c'].toStringAsFixed(0)}°'
                            : '${day['max_f'].toStringAsFixed(0)}°',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.useMetricSystem
                            ? '${day['min_c'].toStringAsFixed(0)}°'
                            : '${day['min_f'].toStringAsFixed(0)}°',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ).animate(delay: (100 * index).ms).slideY(begin: 0.2, curve: Curves.easeOut);
          },
        ),
      ],
    );
  }
}
