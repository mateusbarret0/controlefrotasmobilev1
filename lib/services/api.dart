import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ApiService {
  final String baseUrl = "http://localhost:8000/api";
  final httpClient = http.Client();
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        return {
          'success': true,
          'message': 'Login realizado com sucesso',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Erro no servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> getUsur(Map<String, dynamic> userData) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/get/usur?usuario=${userData['usuario']}&senha=${userData['senha']}',
        ),
        headers: headers,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Usuário não encontrado'};
      } else {
        return {
          'success': false,
          'message': 'Erro no servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão GET: $e'};
    }
  }

  Future<Map<String, dynamic>> linkMotorista({
    required List<dynamic> routeInfo,
    required int codUsur,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rota/linkMotorista'),
        headers: headers,
        body: jsonEncode({'routeInfo': routeInfo, 'codUsur': codUsur}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> startRoute({
    required String vehicleId,
    required String driverId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/routes/start'),
        headers: headers,
        body: jsonEncode({
          'vehicle_id': vehicleId,
          'driver_id': driverId,
          'start_time': DateTime.now().toIso8601String(),
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> atualizarTermo(int id, String status) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/termo/atualizar'),
        headers: headers,
        body: jsonEncode({'id': id, 'status': status}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Erro no servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> insertHodometro({
    required String quilometragem,
    required String imageBase64,
    required int codUsur,
    routeInfo,
  }) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$baseUrl/rota/hodometro/insert');
    final body = jsonEncode({
      'quilometragem': quilometragem,
      'imagem': imageBase64,
      'codUsur': codUsur,
      'routeInfo': routeInfo,
    });
    final response = await http.post(url, headers: headers, body: body);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> insertPartida({
    required double latitude,
    required double longitude,
    required int codUsur,
    required routeInfo,
  }) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$baseUrl/rota/insertPartida');
    final body = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      'codUsur': codUsur,
      'routeInfo': routeInfo,
    });
    final response = await http.post(url, headers: headers, body: body);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getRotaMobile({
    required int codUsur,
    required routeInfo,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/rota/getRotaMobile');
      final body = jsonEncode({'codUsur': codUsur, 'routeInfo': routeInfo});
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);

        if (decodedBody['success'] == true) {
          return {
            'success': true,
            'data': decodedBody['rota'] ?? {},
            'message': decodedBody['message'] ?? '',
          };
        } else {
          return {
            'success': false,
            'message': decodedBody['message'] ?? 'Resposta sem sucesso da API',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Erro da API: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro na comunicação: $e'};
    }
  }

  Future<LatLng?> snapToRoads(LatLng point) async {
    final url = Uri.https('roads.googleapis.com', '/v1/snapToRoads', {
      'path': '${point.latitude},${point.longitude}',
      'interpolate': 'true',
      'key': 'AIzaSyDBwpZs8ef-S4luuIvphLWNSSs5XCga_kc',
    });

    try {
      final resp = await httpClient.get(url);
      if (resp.statusCode != 200) {
        print('⚠ Roads API error: ${resp.statusCode} – ${resp.body}');
        return null;
      }

      final body = json.decode(resp.body) as Map<String, dynamic>;
      final pts = body['snappedPoints'] as List<dynamic>?;
      if (pts == null || pts.isEmpty) return null;

      final loc = pts.first['location'] as Map<String, dynamic>;
      final lat = loc['latitude'] as double;
      final lng = loc['longitude'] as double;
      return LatLng(lat, lng);
    } catch (e, st) {
      print('❌ snapToRoads exception: $e\n$st');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getDirections({
    required Map<String, dynamic> start,
    required Map<String, dynamic> end,
    List<Map<String, dynamic>>? stops,
  }) async {
    print('start: $start, end: $end, stops: $stops');

    final uri = Uri.parse('http://localhost:8000/api/directions');
    final body = {
      'start': {'latitude': start['latitude'], 'longitude': start['longitude']},
      'end': {'latitude': end['latitude'], 'longitude': end['longitude']},
      'stops': stops ?? [],
    };
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final json = jsonDecode(resp.body);
    return {
      'success':
          json['status'] == 'OK' ||
          json['status'] == 200 ||
          json['status'] == true,
      'data': json,
    };
  }
}
