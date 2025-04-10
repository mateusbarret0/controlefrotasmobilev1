import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //final String baseUrl = "http://10.0.2.2:8000/api"; //mobile
  final String baseUrl = "http://127.0.0.1:8000/api"; //web

  Future<Map<String, dynamic>> postData(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Garante que a resposta sempre terá o campo 'success' como bool
        return {
          'success': true,
          ...responseData, // Mantém todos os dados originais da resposta
          'message': responseData['message'] ?? 'Login bem-sucedido',
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
      final response = await http.get(
        Uri.parse(
          '$baseUrl/get/usur?usuario=${userData['usuario']}&senha=${userData['senha']}',
        ),
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
    // required String driverId, // Obter do estado de login
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/link-driver'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'vehicle_hash': vehicleHash,
          // 'driver_id': driverId,
        }),
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
      final response = await http.post(
        Uri.parse('$baseUrl/routes/start'),
        headers: {"Content-Type": "application/json"},
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
}
