class WeatherData {
  final String city;
  final double temp;
  final String description;
  final String iconUrl;
  final double? humidity;
  final double? windKph;
  final double? windMph;
  final double? tempF;

  WeatherData({
    required this.city,
    required this.temp,
    required this.description,
    required this.iconUrl,
    this.humidity,
    this.windKph,
    this.windMph,
    this.tempF,
  });

  String getFormattedTemp(bool useMetric) {
    if (useMetric) {
      return '${temp.toStringAsFixed(1)}°C';
    } else {
      return '${tempF?.toStringAsFixed(1) ?? temp.toStringAsFixed(1)}°F';
    }
  }

  String getFormattedWind(bool useMetric) {
    if (useMetric) {
      return '${windKph?.toStringAsFixed(1) ?? "N/A"} km/h';
    } else {
      return '${windMph?.toStringAsFixed(1) ?? "N/A"} mph';
    }
  }
} 