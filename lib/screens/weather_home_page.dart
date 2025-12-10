import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/weather_data.dart';
import '../constants/api_constants.dart';
import 'forecast_page.dart';

class WeatherHomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(bool) onMetricSystemChanged;
  final bool useMetricSystem;
  final List<String> favorites;
  final Function(String) onToggleFavorite;
  final String? cityToLoad;
  
  const WeatherHomePage({
    super.key,
    required this.onThemeChanged,
    required this.onMetricSystemChanged,
    required this.useMetricSystem,
    required this.favorites,
    required this.onToggleFavorite,
    this.cityToLoad,
  });

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController = TextEditingController();
  WeatherData? _currentWeatherData;
  bool _isLoading = false;
  String _errorMessage = '';
  Position? _currentPosition;
  bool _showWeather = false;
  final String _apiKey = K_WEATHER_API_KEY;

  @override
  void initState() {
    super.initState();
    // Check if we need to load a specific city or current location
    if (widget.cityToLoad != null) {
      _cityController.text = widget.cityToLoad!;
      _fetchWeather();
    } else {
      if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
         WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorMessage = 'API Key not configured. Please set K_WEATHER_API_KEY.';
            });
          }
        });
      } else {
        _getCurrentLocation();
      }
    }
  }

  @override
  void didUpdateWidget(WeatherHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cityToLoad != null && widget.cityToLoad != oldWidget.cityToLoad) {
      _cityController.text = widget.cityToLoad!;
      _fetchWeather();
    }
    // We might also want to reload weather if metric system changed
    if (widget.useMetricSystem != oldWidget.useMetricSystem) {
      setState(() {}); // Just rebuild to update UI if data is already there
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled';
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied';
        });
        return;
      }
      _currentPosition = await Geolocator.getCurrentPosition();
      if (_currentPosition != null) {
        _fetchWeatherByLocation();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
      });
    }
  }

  Future<void> _fetchWeatherByLocation() async {
    if (_currentPosition == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _showWeather = false;
    });
    try {
      final response = await http.get(Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=$_apiKey&q=${_currentPosition!.latitude},${_currentPosition!.longitude}&aqi=no'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentWeatherData = WeatherData(
            city: data['location']['name'],
            temp: data['current']['temp_c'],
            tempF: data['current']['temp_f'],
            description: data['current']['condition']['text'],
            iconUrl: data['current']['condition']['icon'],
            humidity: data['current']['humidity']?.toDouble(),
            windKph: data['current']['wind_kph']?.toDouble(),
            windMph: data['current']['wind_mph']?.toDouble(),
          );
          _errorMessage = '';
          _showWeather = true;
        });
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = 'Error: ${errorData['error']['message'] ?? 'Unknown error'}';
          _showWeather = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching weather: $e';
        _showWeather = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeather() async {
    if (_cityController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await http.get(Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=$_apiKey&q=${_cityController.text}&aqi=yes'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentWeatherData = WeatherData(
            city: data['location']['name'],
            temp: data['current']['temp_c'],
            tempF: data['current']['temp_f'],
            description: data['current']['condition']['text'],
            iconUrl: data['current']['condition']['icon'],
            humidity: data['current']['humidity']?.toDouble(),
            windKph: data['current']['wind_kph']?.toDouble(),
            windMph: data['current']['wind_mph']?.toDouble(),
          );
          _errorMessage = '';
          _showWeather = true;
        });
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = errorData['error']?['message'] ?? 'City not found or API error.';
          _showWeather = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _showWeather = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: No Scaffold here because it's wrapped in MainWrapper's Scaffold
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutQuart,
                switchOutCurve: Curves.easeInQuart,
                child: _isLoading
                    ? _buildShimmerLoader()
                    : _errorMessage.isNotEmpty
                        ? _buildErrorDisplay()
                        : _showWeather && _currentWeatherData != null
                            ? _buildWeatherContent()
                            : _buildEmptyState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SearchBar(
        controller: _cityController,
        hintText: 'Search city...',
        padding: const MaterialStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16.0)),
        onSubmitted: (_) => _fetchWeather(),
        leading: const Icon(Icons.search),
        trailing: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _fetchWeatherByLocation,
            tooltip: 'Use My Location',
          ),
        ],
        elevation: MaterialStateProperty.all(0),
        backgroundColor: MaterialStateProperty.all(
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          )
          .animate(onPlay: (controller) => controller.repeat())
          .scale(duration: 600.ms),
          const SizedBox(height: 16),
          Text('Loading...',
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.error, size: 64)
                .animate().shake(duration: 500.ms),
            const SizedBox(height: 16),
            Text(_errorMessage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchWeatherByLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
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
          Icon(Icons.wb_sunny_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.5),
              size: 100)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(end: 1.1, duration: 2000.ms),
          const SizedBox(height: 24),
          Text('Weather Check',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
          const SizedBox(height: 8),
          Text('Search for a city to start',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  )),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isFavorite = widget.favorites.contains(_currentWeatherData!.city);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Weather Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentWeatherData!.city,
                            style: textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat.yMMMMd().format(DateTime.now()),
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      icon: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? colorScheme.error : colorScheme.onPrimaryContainer,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surface.withOpacity(0.3),
                      ),
                      onPressed: () => widget.onToggleFavorite(_currentWeatherData!.city),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _currentWeatherData!.iconUrl.isNotEmpty
                        ? Image.network(
                            'https:${_currentWeatherData!.iconUrl}',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.wb_sunny,
                              size: 80,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : Icon(Icons.wb_sunny, size: 80, color: colorScheme.onPrimaryContainer),
                  ],
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  _currentWeatherData!.getFormattedTemp(widget.useMetricSystem),
                  style: textTheme.displayLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  _currentWeatherData!.description,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutQuart).fadeIn(),

          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard(
                Icons.water_drop_outlined,
                'Humidity',
                '${_currentWeatherData!.humidity?.toStringAsFixed(0) ?? 'N/A'}%',
                colorScheme.secondaryContainer,
                colorScheme.onSecondaryContainer,
              ),
              _buildStatCard(
                Icons.air,
                'Wind',
                _currentWeatherData!.getFormattedWind(widget.useMetricSystem),
                colorScheme.tertiaryContainer,
                colorScheme.onTertiaryContainer,
              ),
            ],
          ).animate().slideY(begin: 0.2, duration: 600.ms, delay: 200.ms, curve: Curves.easeOutQuart).fadeIn(),

          const SizedBox(height: 24),

          // Forecast Button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ForecastPage(
                    city: _currentWeatherData!.city,
                    useMetricSystem: widget.useMetricSystem,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('View 5-Day Forecast'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color bgColor,
    Color fgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: fgColor, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: fgColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
