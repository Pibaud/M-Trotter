import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = "auth_token";
  static const _refreshTokenKey = "refresh_token";

  // Sauvegarder un token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Récupérer un token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Sauvegarder un refresh token
  static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  // Récupérer un refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Supprimer le token et refresh token (déconnexion)
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}