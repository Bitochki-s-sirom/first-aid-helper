import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:8080';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': firstName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  static Future<Map<String, dynamic>> getInfo({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer ' + token},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getDrugs(
      {required String token}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/drugs'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Ответ сервера: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('data') && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception(
          'Ожидался массив или объект с полем data, а пришло: $data');
    } else {
      print('Ошибка сервера: ${response.body}');
      throw Exception('Failed to get drugs: ${response.statusCode}');
    }
  }

  static Future<bool> addDrug(
      {required String token, required Map<String, dynamic> drug}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/drugs/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(drug),
    );
    if (response.statusCode != 200) {
      print('Ошибка добавления: ${response.statusCode} ${response.body}');
    }
    return response.statusCode == 200;
  }

  static Future<bool> removeDrug(
      {required String token, required int id}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/drugs/remove/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }
}
