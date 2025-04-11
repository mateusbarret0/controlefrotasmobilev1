import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://localhost:8000/api";

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
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
      print("Erro na requisição: $e");
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
      print("Erro de conexão GET: $e");
      return {'success': false, 'message': 'Erro de conexão GET: $e'};
    }
  }

  Future<Map<String, dynamic>> linkDriverToVehicle({
    required String vehicleHash,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/link-driver'),
        headers: headers,
        body: jsonEncode({'vehicle_hash': vehicleHash}),
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
    print('Atualizando termo com ID: $id e status: $status');
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
      print("Erro na requisição: $e");
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}
