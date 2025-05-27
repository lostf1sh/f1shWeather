import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
          _hourlyForecast = (data['forecast']['forecastday'][0]['hour'] as List)
              .sublist(0, 6)
              .map<Map<String, dynamic>>((hour) => {
                    'time': hour['time'].split(' ')[1],
                    'temp_c': hour['temp_c'],
                    'temp_f': hour['temp_f'],
                    'icon': hour['condition']['icon'],
                  })
              .toList();
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('f1sh Weather',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            )),
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
                      _buildCurrentWeather(),
                      const SizedBox(height: 24),
                      _buildHourlyForecast(),
                      const SizedBox(height: 24),
                      _buildDailyForecast(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentWeather() {
    if (_currentWeather == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Now',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge),
                      Text(_currentWeather!['condition']['text'],
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium),
                    ],
                  ),
                ),
                Text(widget.useMetricSystem
                    ? '${_currentWeather!['temp'].toStringAsFixed(1)}°C'
                    : '${_currentWeather!['temp_f'].toStringAsFixed(1)}°F',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: colorScheme.primary,
                        )),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                    'Feels Like',
                    widget.useMetricSystem
                        ? '${_currentWeather!['feels_like'].toStringAsFixed(1)}°C'
                        : '${_currentWeather!['feels_like_f'].toStringAsFixed(1)}°F'),
                _buildWeatherDetail('Humidity',
                    '${_currentWeather!['humidity']}%'),
                _buildWeatherDetail('Wind',
                    widget.useMetricSystem
                        ? '${_currentWeather!['wind_kph']} km/h'
                        : '${_currentWeather!['wind_mph']} mph'),
                _buildWeatherDetail(
                    'UV', _currentWeather!['uv'].toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Hourly Forecast',
              style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _hourlyForecast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final hour = _hourlyForecast[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hour['time'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Image.network(
                          'https:${hour['icon']}',
                          width: 36,
                          height: 36,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.cloud_off,
                            size: 36,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.useMetricSystem
                            ? '${hour['temp_c'].toStringAsFixed(0)}°C'
                            : '${hour['temp_f'].toStringAsFixed(0)}°F',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('5-Day Forecast',
              style: Theme.of(context).textTheme.titleLarge),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _forecast.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final day = _forecast[index];
            final date = DateTime.parse(day['date']);
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                      Theme.of(context).colorScheme.surfaceContainerHigh,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${date.day}/${date.month}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Image.network(
                        'https:${day['icon']}',
                        width: 40,
                        height: 40,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: day['chance_of_rain'] / 100,
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rain Chance: ${day['chance_of_rain']}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.useMetricSystem
                              ? '${day['max_c'].toStringAsFixed(0)}°C'
                              : '${day['max_f'].toStringAsFixed(0)}°F',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          widget.useMetricSystem
                              ? '${day['min_c'].toStringAsFixed(0)}°C'
                              : '${day['min_f'].toStringAsFixed(0)}°F',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
} 