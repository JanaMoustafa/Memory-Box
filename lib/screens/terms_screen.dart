import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

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
          'Terms and Conditions',
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
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using Memory Box, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '2. Use License',
              content:
                  'Permission is granted to temporarily use Memory Box for personal, non-commercial use only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose\n• Attempt to decompile or reverse engineer any software\n• Remove any copyright or other proprietary notations',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '3. User Accounts',
              content:
                  'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '4. User Content',
              content:
                  'You retain ownership of any content you submit, post, or display on Memory Box. By submitting content, you grant Memory Box a worldwide, non-exclusive, royalty-free license to use, reproduce, and distribute your content solely for the purpose of providing the service.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '5. Privacy',
              content:
                  'Your use of Memory Box is also governed by our Privacy Policy. Please review our Privacy Policy to understand our practices regarding the collection and use of your information.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '6. Disclaimer',
              content:
                  'The materials on Memory Box are provided on an "as is" basis. Memory Box makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '7. Limitations',
              content:
                  'In no event shall Memory Box or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on Memory Box.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '8. Revisions',
              content:
                  'Memory Box may revise these terms of service at any time without notice. By using this service, you are agreeing to be bound by the then current version of these terms of service.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '9. Contact Information',
              content:
                  'If you have any questions about these Terms and Conditions, please contact us at support@memorybox.app',
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
