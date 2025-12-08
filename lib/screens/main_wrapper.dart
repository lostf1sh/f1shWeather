import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_home_page.dart';
import 'favorites_page.dart';
import 'settings_page.dart';

class MainWrapper extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final Function(bool) onMetricSystemChanged;
  final bool useMetricSystem;
  final bool isDarkMode;

  const MainWrapper({
    super.key,
    required this.onThemeChanged,
    required this.onMetricSystemChanged,
    required this.useMetricSystem,
    required this.isDarkMode,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  List<String> _favorites = [];
  String? _selectedCityFromFavorites;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('favourites') ?? [];
    });
  }

  Future<void> _toggleFavorite(String city) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(city)) {
        _favorites.remove(city);
      } else {
        _favorites.add(city);
      }
    });
    await prefs.setStringList('favourites', _favorites);
  }

  void _onCitySelected(String city) {
    setState(() {
      _selectedCityFromFavorites = city;
      _currentIndex = 0; // Switch to Home
    });
  }

  @override
  Widget build(BuildContext context) {
    // We recreate the pages to pass the updated favorites list.
    // Ideally we would use a state management solution to avoid rebuilding everything,
    // but for this scale, passing props is acceptable.
    final pages = [
      WeatherHomePage(
        onThemeChanged: widget.onThemeChanged,
        onMetricSystemChanged: widget.onMetricSystemChanged,
        useMetricSystem: widget.useMetricSystem,
        favorites: _favorites,
        onToggleFavorite: _toggleFavorite,
        cityToLoad: _selectedCityFromFavorites,
        // Reset cityToLoad after it's consumed? WeatherHomePage should handle that
        // or we pass a wrapper object/timestamp to force update.
        // For now let's pass the string.
      ),
      FavoritesPage(
        favorites: _favorites,
        useMetricSystem: widget.useMetricSystem,
        onCitySelected: _onCitySelected,
      ),
      SettingsPage(
        isDarkMode: widget.isDarkMode,
        useMetricSystem: widget.useMetricSystem,
        onThemeChanged: widget.onThemeChanged,
        onMetricSystemChanged: widget.onMetricSystemChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            // Clear selected city when manually navigating to prevent auto-reloading if we go back to home
            if (index != 0) {
               _selectedCityFromFavorites = null;
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Weather',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOutQuart),
    );
  }
}
