// user_name_service.dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveUserName(String nombre) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('usuarioNombre', nombre);
}

Future<String?> getUserName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('usuarioNombre');
}
