import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/weather_data.dart';
import '../constants/api_constants.dart';

class FavoritesPage extends StatefulWidget {
  final List<String> favorites;
  final bool useMetricSystem;
  final Function(String) onCitySelected;

  const FavoritesPage({
    super.key,
    required this.favorites,
    required this.useMetricSystem,
    required this.onCitySelected,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final Map<String, WeatherData> _favoriteWeather = {};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllFavorites();
  }

  Future<void> _fetchAllFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      for (final city in widget.favorites) {
        await _fetchWeatherForCity(city);
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching weather data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeatherForCity(String city) async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=${K_WEATHER_API_KEY}&q=$city&aqi=no'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _favoriteWeather[city] = WeatherData(
            city: data['location']['name'],
            temp: data['current']['temp_c'],
            tempF: data['current']['temp_f'],
            description: data['current']['condition']['text'],
            iconUrl: data['current']['condition']['icon'],
            humidity: data['current']['humidity']?.toDouble(),
            windKph: data['current']['wind_kph']?.toDouble(),
            windMph: data['current']['wind_mph']?.toDouble(),
          );
        });
      } else {
        setState(() {
          _error = 'Error fetching weather for $city';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching weather for $city: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)))
              : widget.favorites.isEmpty
                  ? Center(
                      child: Text('No favorites yet',
                          style: Theme.of(context).textTheme.bodyLarge))
                  : RefreshIndicator(
                      onRefresh: _fetchAllFavorites,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: widget.favorites.length,
                        itemBuilder: (context, index) {
                          final city = widget.favorites[index];
                          final weather = _favoriteWeather[city];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              onTap: () => widget.onCitySelected(city),
                              contentPadding: const EdgeInsets.all(16),
                              leading: weather != null
                                  ? Image.network(
                                      'https:${weather.iconUrl}',
                                      width: 48,
                                      height: 48,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.cloud_off,
                                              size: 48,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error),
                                    )
                                  : const SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Center(
                                          child: CircularProgressIndicator())),
                              title: Text(city,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              subtitle: weather != null
                                  ? Text(
                                      weather.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    )
                                  : null,
                              trailing: weather != null
                                  ? Text(
                                      weather.getFormattedTemp(
                                          widget.useMetricSystem),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
} 