import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Privacy and Security',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: '1. Information We Collect',
              content:
                  'Memory Box collects the following types of information:\n\n• Account Information: Email address, display name, and authentication credentials\n• Memory Data: Titles, notes, photos, locations, and timestamps of your memories\n• Device Information: Device type, operating system, and app version\n• Usage Data: How you interact with the app and features you use',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '2. How We Use Your Information',
              content:
                  'We use the information we collect to:\n\n• Provide and maintain the Memory Box service\n• Process your memories and store them securely\n• Send you important service updates and notifications\n• Improve our app and develop new features\n• Detect and prevent fraud or abuse',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '3. Data Storage and Security',
              content:
                  'Your data is stored securely using Firebase, which provides enterprise-grade security:\n\n• All data is encrypted in transit using SSL/TLS\n• Data is encrypted at rest in Firebase servers\n• Authentication is handled securely through Firebase Authentication\n• Access to your data is restricted to your authenticated account only',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '4. Data Sharing',
              content:
                  'We do not sell, trade, or rent your personal information to third parties. Your memories are private to you unless you explicitly choose to share them. We may share aggregated, anonymized data for analytics purposes.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '5. Your Rights',
              content:
                  'You have the right to:\n\n• Access your personal data at any time\n• Update or correct your information\n• Delete your account and all associated data\n• Export your memories in a standard format\n• Opt-out of non-essential communications',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '6. Data Retention',
              content:
                  'We retain your data for as long as your account is active or as needed to provide services. If you delete your account, we will delete your personal data within 30 days, except where we are required to retain it by law.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '7. Third-Party Services',
              content:
                  'Memory Box uses the following third-party services:\n\n• Firebase (Authentication and Database) - Google\n• Mapbox (Maps) - Mapbox Inc.\n\nThese services have their own privacy policies. We encourage you to review them.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '8. Children\'s Privacy',
              content:
                  'Memory Box is not intended for users under the age of 13. We do not knowingly collect personal information from children under 13. If we become aware that we have collected such information, we will take steps to delete it.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '9. Security Measures',
              content:
                  'We implement appropriate technical and organizational measures to protect your data:\n\n• Secure authentication methods\n• Regular security audits\n• Encrypted data transmission\n• Secure data storage\n• Access controls and monitoring',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '10. Changes to Privacy Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '11. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy or our data practices, please contact us at privacy@memorybox.app',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}
