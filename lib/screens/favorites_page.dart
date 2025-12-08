import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
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

  // We need to fetch data whenever the favorites list changes or on init
  @override
  void initState() {
    super.initState();
    _fetchAllFavorites();
  }

  @override
  void didUpdateWidget(FavoritesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.favorites.length != oldWidget.favorites.length ||
        !widget.favorites.every((element) => oldWidget.favorites.contains(element))) {
      _fetchAllFavorites();
    }
  }

  Future<void> _fetchAllFavorites() async {
    if (widget.favorites.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    // Don't show full loading screen if we are just updating
    // But for simplicity, let's keep it simple.
    // Actually, let's only set loading if we have no data for new items.

    setState(() {
      _isLoading = true;
    });

    try {
      for (final city in widget.favorites) {
        // Skip if we already have it? Maybe not, we want fresh data.
        await _fetchWeatherForCity(city);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchWeatherForCity(String city) async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=${K_WEATHER_API_KEY}&q=$city&aqi=no'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
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
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Note: MainWrapper provides the Scaffold
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
             Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Text('Favorites',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                ],
              ),
            ),
            Expanded(
              child: widget.favorites.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.favorites.length,
                      itemBuilder: (context, index) {
                        final city = widget.favorites[index];
                        final weather = _favoriteWeather[city];
                        return _buildFavoriteCard(city, weather, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border,
              size: 80,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No favorites yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const SizedBox(height: 8),
          Text('Add cities from the home screen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildFavoriteCard(String city, WeatherData? weather, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    // Alternate colors for variety
    final cardColor = index % 2 == 0
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerHighest;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      child: InkWell(
        onTap: () => widget.onCitySelected(city),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const SizedBox(height: 4),
                    if (weather != null)
                      Text(
                        weather.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              if (weather != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      weather.getFormattedTemp(widget.useMetricSystem),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                    ),
                    if (weather.iconUrl.isNotEmpty)
                      Image.network(
                        'https:${weather.iconUrl}',
                        width: 40,
                        height: 40,
                        errorBuilder: (_,__,___) => const SizedBox(),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate(delay: (100 * index).ms).slideX(begin: 0.2, duration: 400.ms, curve: Curves.easeOutQuart).fadeIn();
  }
}
