// user_id_service.dart
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getOrCreateUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString('usuarioId');
  if (existing != null) return existing;

  final random = Random();
  final newId =
  List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
  await prefs.setString('usuarioId', newId);
  return newId;
}
