import 'package:facebook_clone/core/widgets/custom_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  Future<void> openGmailApp(BuildContext context) async {
    final Uri gmailUri = Uri(
      scheme: 'mailto',
      path: 'mahmodmansour2001@gmail.com',
      query: Uri.encodeFull(
        'subject=Privacy Inquiry&body=Hello, I have a question regarding your privacy policy.',
      ),
    );

    try {
      if (!await launchUrl(gmailUri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          _showEmailFallbackDialog(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showEmailFallbackDialog(context);
      }
    }
  }

  void _showEmailFallbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Not Available'),
        content: const Text(
          'We couldn\'t open your email app. The email address has been copied to your clipboard. '
          'Please paste it manually in your email app to contact us.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      Clipboard.setData(
          const ClipboardData(text: 'mahmoudmansor2001@gmail.com'));
    });
  }

  Future<void> openWhatsApp(BuildContext context) async {
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/201555798495?text=Hello Mahmoud, I have a question about your app.',
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = DateTime.now();
    final formattedDate =
        '${currentDate.year}-${currentDate.month}-${currentDate.day}';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Row(
          children: [
            CustomIconButton(
              onPressed: () => Navigator.of(context).pop(),
              iconData: Icons.arrow_back_ios,
            ),
            const Text('Privacy Policy'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Introduction'),
            _buildParagraph(
              'We value your privacy and are committed to protecting your personal information. '
              'This policy explains how we collect, use, and safeguard your data when you use our application.',
            ),
            _buildSectionHeader('Information We Collect'),
            _buildBulletPoint(
                'Account information: Your name, email address, and profile picture'),
            _buildBulletPoint(
                'User content: Posts, comments, and other content you create'),
            _buildBulletPoint('Usage data: How you interact with our services'),
            _buildBulletPoint(
                'Device information: Device type, operating system, and IP address'),
            _buildSectionHeader('How We Use Your Information'),
            _buildParagraph(
                'We use the information we collect to provide, maintain, and improve our services, including:'),
            _buildBulletPoint('Personalizing your experience'),
            _buildBulletPoint('Developing new features'),
            _buildBulletPoint('Communicating with you about updates'),
            _buildBulletPoint('Ensuring security and preventing fraud'),
            _buildSectionHeader('Sharing of Information'),
            _buildParagraph(
                'We do not sell your personal information. We may share data in the following limited circumstances:'),
            _buildBulletPoint('With your consent'),
            _buildBulletPoint(
                'With service providers who assist us in operations'),
            _buildBulletPoint('When required by law or to protect rights'),
            _buildSectionHeader('Data Security'),
            _buildParagraph(
              'We implement appropriate technical and organizational measures to protect your personal information '
              'against unauthorized access, alteration, or destruction.',
            ),
            _buildSectionHeader('Your Rights'),
            _buildParagraph(
                'Depending on your location, you may have certain rights regarding your personal data:'),
            _buildBulletPoint('Access and receive a copy of your data'),
            _buildBulletPoint('Request correction of inaccurate information'),
            _buildBulletPoint('Request deletion of your data'),
            _buildBulletPoint('Object to certain processing activities'),
            _buildSectionHeader('Changes to This Policy'),
            _buildParagraph(
              'We may update this privacy policy from time to time. We will notify you of significant changes '
              'through the app or via email.',
            ),
            _buildSectionHeader('Contact Us'),
            _buildParagraph(
                'If you have questions about this privacy policy, please contact us at:'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => openGmailApp(context),
              child: const Text(
                'Contact on Gmail',
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => openWhatsApp(context),
              child: const Text(
                'Contact on WhatsApp',
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Last updated: $formattedDate',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
