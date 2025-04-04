import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get serverUrl => dotenv.env['SERVER_URL'] ?? '';
}