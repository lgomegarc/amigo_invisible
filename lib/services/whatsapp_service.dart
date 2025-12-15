// whatsapp_service.dart
import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  static Future<void> enviarCodigo(int codigo) async {
    final mensaje = Uri.encodeComponent(
      'Te invito a mi sorteo de Amigo Invisible. Este es el código para unirte: $codigo',
    );
    final url = Uri.parse('https://wa.me/?text=$mensaje');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir WhatsApp');
    }
  }
}
