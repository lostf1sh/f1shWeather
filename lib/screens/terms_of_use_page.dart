import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms of Use',
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
              'Terms of Use',
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
              'Agreement to Terms',
              'By accessing and using f1sh Weather, you agree to be bound by these Terms of Use and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using this application.',
            ),
            _buildSection(
              context,
              'Use License',
              'Permission is granted to temporarily download one copy of f1sh Weather per device for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title.',
            ),
            _buildSection(
              context,
              'Restrictions',
              'You are specifically restricted from:\n\n'
              '• Modifying or copying the materials\n'
              '• Using the materials for commercial purposes\n'
              '• Attempting to reverse engineer any software\n'
              '• Removing any copyright or proprietary notations',
            ),
            _buildSection(
              context,
              'Disclaimer',
              'The materials on f1sh Weather are provided on an \'as is\' basis. We make no warranties, expressed or implied, and hereby disclaim and negate all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
            ),
            _buildSection(
              context,
              'Limitations',
              'In no event shall f1sh Weather or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the application.',
            ),
            _buildSection(
              context,
              'Accuracy of Materials',
              'The materials appearing in f1sh Weather could include technical, typographical, or photographic errors. We do not warrant that any of the materials are accurate, complete, or current. We may make changes to the materials at any time without notice.',
            ),
            _buildSection(
              context,
              'Links',
              'We have not reviewed all of the sites linked to our application and are not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by f1sh Weather of the site.',
            ),
            _buildSection(
              context,
              'Modifications',
              'We may revise these terms of service at any time without notice. By using this application, you agree to be bound by the current version of these terms of service.',
            ),
            _buildSection(
              context,
              'Governing Law',
              'These terms and conditions are governed by and construed in accordance with the laws and you irrevocably submit to the exclusive jurisdiction of the courts in that location.',
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