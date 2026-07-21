import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static const String baseUrl = 'https://36a5-129-0-60-54.ngrok-free.app/api/';
  final _storage = const FlutterSecureStorage();

  // ─── Token helpers ────────────────────────────────────────────────────────

  Future<String?> getToken() async => _storage.read(key: 'jwt_token');
  Future<String?> getRefreshToken() async => _storage.read(key: 'refresh_token');

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Tente de renouveler le token d'accès avec le refresh token.
  /// Retourne true si le renouvellement a réussi.
  Future<bool> _refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    final url = Uri.parse('${baseUrl}token/refresh/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: 'jwt_token', value: data['access']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ─── HTTP methods avec retry automatique sur 401 ──────────────────────────

  Future<dynamic> get(String endpoint, {bool isRetry = false}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    return _processResponse(response, () => get(endpoint, isRetry: true), isRetry: isRetry);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body, {bool isRetry = false}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );
    return _processResponse(response, () => post(endpoint, body, isRetry: true), isRetry: isRetry);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body, {bool isRetry = false}) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );
    return _processResponse(response, () => put(endpoint, body, isRetry: true), isRetry: isRetry);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body, {bool isRetry = false}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );
    return _processResponse(response, () => patch(endpoint, body, isRetry: true), isRetry: isRetry);
  }

  Future<dynamic> delete(String endpoint, {bool isRetry = false}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    return _processResponse(response, () => delete(endpoint, isRetry: true), isRetry: isRetry);
  }

  /// Traite la réponse HTTP. Si le serveur répond 401, tente un refresh
  /// automatique du token puis rejoue la requête une seule fois.
  Future<dynamic> _processResponse(
    http.Response response,
    Future<dynamic> Function() retry, {
    bool isRetry = false,
  }) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 401 && !isRetry) {
      // Token expiré → on tente un refresh
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        // Rejouer la requête originale avec le nouveau token
        return retry();
      } else {
        // Refresh échoué → on force le logout
        await logout();
        throw ApiException(401, 'Session expirée. Veuillez vous reconnecter.');
      }
    } else {
      String message = 'Erreur ${response.statusCode}';
      try {
        final body = json.decode(response.body);
        if (body is Map) {
          message = body.values.first?.toString() ?? message;
        }
      } catch (_) {}
      throw ApiException(response.statusCode, message);
    }
  }

  // ─── Authentification ─────────────────────────────────────────────────────

  /// Connecte l'utilisateur et stocke les tokens JWT.
  /// Retourne true si la connexion a réussi, false sinon.
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('${baseUrl}token/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _storage.write(key: 'jwt_token', value: data['access']);
      await _storage.write(key: 'refresh_token', value: data['refresh']);
      return true;
    }
    return false;
  }

  /// Déconnecte l'utilisateur et supprime les tokens stockés.
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
  }

  /// Vérifie si l'utilisateur est actuellement authentifié.
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Récupère le profil de l'utilisateur connecté
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final data = await get('utilisateurs/me/');
      return data;
    } catch (e) {
      return null;
    }
  }
}

/// Exception personnalisée pour les erreurs API.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
