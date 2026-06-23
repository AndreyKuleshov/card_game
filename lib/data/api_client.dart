import 'dart:convert';
import 'package:http/http.dart' as http;

const kApiBaseUrl = 'https://cardsspg.duckdns.org';

typedef PlayerCredentials = ({String playerId, String token});

typedef RemoteProgress = ({
  Map<String, dynamic> data,
  int crystals,
  int schemaVersion,
  DateTime updatedAt,
});

class ApiClient {
  final http.Client _client;
  static const _timeout = Duration(seconds: 8);

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<PlayerCredentials> createPlayer() async {
    final uri = Uri.parse('$kApiBaseUrl/v1/players');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(<String, dynamic>{}),
        )
        .timeout(_timeout);
    _checkResponse(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      playerId: body['player_id'] as String,
      token: body['token'] as String,
    );
  }

  Future<RemoteProgress?> getProgress(String token) async {
    final uri = Uri.parse('$kApiBaseUrl/v1/progress');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(_timeout);
    if (response.statusCode == 404) return null;
    _checkResponse(response);
    return _parseProgress(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<RemoteProgress> putProgress(
    String token, {
    required Map<String, dynamic> data,
    required int crystals,
    required int schemaVersion,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl/v1/progress');
    final body = jsonEncode({
      'data': data,
      'crystals': crystals,
      'schema_version': schemaVersion,
    });
    final response = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    ).timeout(_timeout);
    _checkResponse(response);
    return _parseProgress(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  RemoteProgress _parseProgress(Map<String, dynamic> json) {
    return (
      data: json['data'] as Map<String, dynamic>,
      crystals: json['crystals'] as int,
      schemaVersion: json['schema_version'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(response.statusCode, response.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
