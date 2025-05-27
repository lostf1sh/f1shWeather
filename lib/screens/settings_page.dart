import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final bool isDarkMode;
  final bool useMetricSystem;
  final Function(bool) onThemeChanged;
  final Function(bool) onMetricSystemChanged;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.useMetricSystem,
    required this.onThemeChanged,
    required this.onMetricSystemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Dark Mode',
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('Enable dark theme',
                style: Theme.of(context).textTheme.bodyMedium),
            value: isDarkMode,
            onChanged: onThemeChanged,
          ),
          SwitchListTile(
            title: Text('Metric System',
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('Use Celsius and kilometers',
                style: Theme.of(context).textTheme.bodyMedium),
            value: useMetricSystem,
            onChanged: onMetricSystemChanged,
          ),
          const Divider(),
          ListTile(
            title: Text('About',
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('App information and version',
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
          ListTile(
            title: Text('Privacy Policy',
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('Read our privacy policy',
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/privacy'),
          ),
          ListTile(
            title: Text('Terms of Use',
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('Read our terms of use',
                style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/terms'),
          ),
        ],
      ),
    );
  }
} 