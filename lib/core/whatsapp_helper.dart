import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  /// WhatsApp app open karne ka function
  static Future<void> sendWhatsAppMessage({
    required String phone,
    required String message,
  }) async {
    // Phone number se non-digit characters hatana
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    
    // Country code fallback (Agar 10 digit hai toh India +91 attach kar dega)
    final formattedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse('https://wa.me/$formattedPhone?text=$encodedMessage');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp for $formattedPhone';
    }
  }

  /// Template text ko dynamic values ke sath generate karna
  static String parseTemplate({
    required String templateText,
    required String leadName,
    required String businessName,
    Map<String, dynamic>? customFields,
  }) {
    String text = templateText
        .replaceAll('{name}', leadName)
        .replaceAll('{business_name}', businessName);

    // Custom fields variables ko replace karna (e.g. {budget}, {concern})
    if (customFields != null) {
      customFields.forEach((key, value) {
        text = text.replaceAll('{$key}', value.toString());
      });
    }

    return text;
  }
}