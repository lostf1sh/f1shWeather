import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Last updated: March 2024',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'Introduction',
              'This Privacy Policy describes how f1sh Weather ("we", "us", or "our") collects, uses, and shares your personal information when you use our weather application.',
            ),
            _buildSection(
              context,
              'Information We Collect',
              'We collect minimal information necessary to provide weather services:\n\n'
              '• Location data (only when you grant permission)\n'
              '• Device information\n'
              '• Usage statistics',
            ),
            _buildSection(
              context,
              'How We Use Your Information',
              'We use the collected information to:\n\n'
              '• Provide accurate weather forecasts\n'
              '• Improve our services\n'
              '• Enhance user experience\n'
              '• Maintain app functionality',
            ),
            _buildSection(
              context,
              'Data Storage',
              'Your data is stored securely and locally on your device. We do not store your personal information on our servers.',
            ),
            _buildSection(
              context,
              'Third-Party Services',
              'We use WeatherAPI.com to provide weather data. Their privacy policy applies to the data they collect.',
            ),
            _buildSection(
              context,
              'Your Rights',
              'You have the right to:\n\n'
              '• Access your data\n'
              '• Delete your data\n'
              '• Opt-out of data collection\n'
              '• Request data portability',
            ),
            _buildSection(
              context,
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n\n'
              'support@f1shweather.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
} 