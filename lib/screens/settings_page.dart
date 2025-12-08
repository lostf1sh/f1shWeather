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
                  Text('Settings',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSectionHeader(context, 'Preferences'),
                  const SizedBox(height: 8),
                  _buildSwitchTile(
                    context,
                    'Dark Mode',
                    'Enable dark theme',
                    isDarkMode,
                    Icons.dark_mode_outlined,
                    onThemeChanged,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    context,
                    'Metric System',
                    'Use Celsius and kilometers',
                    useMetricSystem,
                    Icons.straighten,
                    onMetricSystemChanged,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'About'),
                  const SizedBox(height: 8),
                  _buildActionTile(
                    context,
                    'About App',
                    'App information and version',
                    Icons.info_outline,
                    () => Navigator.pushNamed(context, '/about'),
                  ),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    context,
                    'Privacy Policy',
                    'Read our privacy policy',
                    Icons.privacy_tip_outlined,
                    () => Navigator.pushNamed(context, '/privacy'),
                  ),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    context,
                    'Terms of Use',
                    'Read our terms of use',
                    Icons.description_outlined,
                    () => Navigator.pushNamed(context, '/terms'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.onSurfaceVariant),
        ),
        title: Text(title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.onSurfaceVariant),
        ),
        title: Text(title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
