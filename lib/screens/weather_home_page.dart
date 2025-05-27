import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/weather_data.dart';
import '../constants/api_constants.dart';
import 'forecast_page.dart';
import 'favorites_page.dart';
import 'settings_page.dart';

class WeatherHomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(bool) onMetricSystemChanged;
  final bool useMetricSystem;
  
  const WeatherHomePage({
    super.key,
    required this.onThemeChanged,
    required this.onMetricSystemChanged,
    required this.useMetricSystem,
  });

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _cityController = TextEditingController();
  WeatherData? _currentWeatherData;
  bool _isLoading = false;
  String _errorMessage = '';
  Position? _currentPosition;
  bool _showWeather = false;
  List<String> _favourites = [];
  Map<String, WeatherData> _favouriteWeather = {};
  final String _apiKey = K_WEATHER_API_KEY;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
    _loadThemePreference();
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorMessage = 'API Key not configured. Please set K_WEATHER_API_KEY.';
            _isLoading = false;
          });
        }
      });
    } else {
      _getCurrentLocation();
    }
    _cityController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favourites = prefs.getStringList('favourites') ?? [];
    });
    await _fetchAllFavouriteWeather();
  }

  Future<void> _saveFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favourites', _favourites);
  }

  Future<void> _fetchAllFavouriteWeather() async {
    Map<String, WeatherData> newData = {};
    for (final city in _favourites) {
      try {
        final response = await http.get(Uri.parse(
            'https://api.weatherapi.com/v1/current.json?key=$_apiKey&q=$city&aqi=no'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          newData[city] = WeatherData(
            city: data['location']['name'],
            temp: data['current']['temp_c'],
            tempF: data['current']['temp_f'],
            description: data['current']['condition']['text'],
            iconUrl: data['current']['condition']['icon'],
            humidity: data['current']['humidity']?.toDouble(),
            windKph: data['current']['wind_kph']?.toDouble(),
            windMph: data['current']['wind_mph']?.toDouble(),
          );
        }
      } catch (_) {}
    }
    setState(() {
      _favouriteWeather = newData;
    });
  }

  void _toggleFavourite() async {
    if (_currentWeatherData == null) return;
    setState(() {
      if (_favourites.contains(_currentWeatherData!.city)) {
        _favourites.remove(_currentWeatherData!.city);
        _favouriteWeather.remove(_currentWeatherData!.city);
      } else {
        _favourites.add(_currentWeatherData!.city);
      }
    });
    await _saveFavourites();
    await _fetchAllFavouriteWeather();
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

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildModernDrawer(),
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildModernDrawer() {
    return Drawer(
      width: 280,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('f1sh Weather',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            )),
                    Text('v1.0.3',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            )),
                  ],
                ),
              ),
              const Divider(),
              _buildDrawerItem(Icons.favorite, 'Favorites', _openFavorites),
              _buildDrawerItem(Icons.settings, 'Settings', _openSettings),
              _buildDrawerItem(Icons.info, 'About', () {
                Navigator.pushNamed(context, '/about');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon,
          color: Theme.of(context).colorScheme.onSurface),
      title: Text(text,
          style: Theme.of(context).textTheme.titleMedium),
      onTap: onTap,
    );
  }

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FavoritesPage(
          favorites: _favourites,
          useMetricSystem: widget.useMetricSystem,
          onCitySelected: (city) {
            _cityController.text = city;
            _fetchWeather();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          isDarkMode: _isDarkMode,
          useMetricSystem: widget.useMetricSystem,
          onThemeChanged: (value) {
            setState(() {
              _isDarkMode = value;
            });
            widget.onThemeChanged(value);
          },
          onMetricSystemChanged: widget.onMetricSystemChanged,
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('f1sh Weather',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              )),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchWeatherByLocation,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _isLoading
                ? _buildShimmerLoader()
                : _errorMessage.isNotEmpty
                    ? _buildErrorDisplay()
                    : _showWeather
                        ? _buildWeatherContent(
                            Theme.of(context).colorScheme,
                            Theme.of(context).textTheme)
                        : _buildEmptyState(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _cityController,
        decoration: InputDecoration(
          hintText: 'Search city...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _fetchWeatherByLocation,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onSubmitted: (_) => _fetchWeather(),
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
          ),
          const SizedBox(height: 16),
          Text('Loading...',
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.error, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchWeatherByLocation,
            child: const Text('Use My Location'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5),
              size: 64),
          const SizedBox(height: 16),
          Text('Search for a city',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  )),
          const SizedBox(height: 8),
          Text('or use your location',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  )),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(
      ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Icon(Icons.error_outline_rounded,
              color: colorScheme.onErrorContainer,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_errorMessage,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ]),
        ),
      );
    }
    if (!_showWeather || _currentWeatherData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wb_sunny_outlined,
                size: 80,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Search for a city or use your location',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceContainerHighest,
                    colorScheme.surfaceContainerHigh,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_currentWeatherData!.city,
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _favourites.contains(_currentWeatherData!.city)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _favourites.contains(_currentWeatherData!.city)
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                            size: 28,
                          ),
                          tooltip: _favourites.contains(_currentWeatherData!.city)
                              ? 'Remove from Favorites'
                              : 'Add to Favorites',
                          onPressed: _toggleFavourite,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentWeatherData!.getFormattedTemp(widget.useMetricSystem),
                      style: textTheme.displayLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_currentWeatherData!.description,
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        if (_currentWeatherData!.humidity != null)
                          _buildMainCardDetailItem(
                            Icons.water_drop,
                            '${_currentWeatherData!.humidity!.toStringAsFixed(0)}%',
                            'Humidity',
                            colorScheme,
                            textTheme,
                          ),
                        if (_currentWeatherData!.windKph != null ||
                            _currentWeatherData!.windMph != null)
                          _buildMainCardDetailItem(
                            Icons.air_outlined,
                            _currentWeatherData!.getFormattedWind(widget.useMetricSystem),
                            'Wind',
                            colorScheme,
                            textTheme,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      icon: Icon(Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      label: Text('View Forecast',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _currentWeatherData!.iconUrl.isNotEmpty
                  ? Image.network(
                      'https:${_currentWeatherData!.iconUrl}',
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                      errorBuilder: (c, o, s) => Icon(
                        Icons.cloud_off,
                        size: 50,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : Icon(
                      Icons.thermostat,
                      size: 50,
                      color: colorScheme.onPrimaryContainer,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCardDetailItem(
    IconData icon,
    String value,
    String label,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _fetchWeatherByLocation,
      child: const Icon(Icons.my_location),
    );
  }

  Future<void> _fetchWeather() async {
    if (_cityController.text.isEmpty) return;
    await _fetchWeatherData(_cityController.text);
  }

  Future<void> _fetchWeatherData(String query) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
      if (mounted) {
        setState(() {
          _errorMessage = 'API Key not configured.';
          _isLoading = false;
          _showWeather = false;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await http.get(Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=$_apiKey&q=$query&aqi=yes'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
        setState(() {
          _errorMessage = '';
          _showWeather = true;
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?['message'] ??
            'City not found or API error.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _showWeather = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }
} 