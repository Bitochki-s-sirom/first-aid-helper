import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class ApiService {
  static const String _baseUrl = Config.apiBaseUrl;

  static Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        body: jsonEncode({'email': email, 'password': password}),
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

  static Future<Map<String, dynamic>> getInfo({required String token}) async {
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

  static Future<List<Map<String, dynamic>>> getDrugs({
    required String token,
  }) async {
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
        'Ожидался массив или объект с полем data, а пришло: $data',
      );
    } else {
      print('Ошибка сервера: ${response.body}');
      throw Exception('Failed to get drugs: ${response.statusCode}');
    }
  }

  static Future<bool> addDrug({
    required String token,
    required Map<String, dynamic> drug,
  }) async {
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

  static Future<bool> removeDrug({
    required String token,
    required int id,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/drugs/remove/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getChats({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/chats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('data')) {
        if (data['data'] == null) {
          return [];
        }
        if (data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        throw Exception('Ожидался массив чатов в поле data');
      }
      throw Exception('Ожидался объект с полем data');
    } else {
      throw Exception('Failed to get chats: ${response.statusCode}');
    }
  }

  static Future<int> createChat({required String token}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/new_chat'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as int;
    } else {
      throw Exception('Failed to create chat: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getChatMessages({
    required String token,
    required int chatId,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/chats/$chatId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('data') && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Ожидался объект с полем data (массив сообщений)');
    } else {
      throw Exception('Failed to get chat messages: ${response.statusCode}');
    }
  }

  static Stream<String> sendAiMessageStream({
    required String token,
    required int chatId,
    required String message,
  }) async* {
    final url = Uri.parse('$_baseUrl/auth/send_message');
    final request = http.Request('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode({'text': message, 'chat_id': chatId});

    final client = http.Client();
    final response = await client.send(request);

    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.statusCode}');
    }

    final stream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where(
          (line) => line.startsWith('data: ') || line.startsWith('event: done'),
        )
        .map((line) {
      if (line.startsWith('event: done') ||
          line.trim() == 'data: [DONE]' ||
          line.trim() == 'data: completed') {
        return '[DONE]';
      }
      return line.substring(6);
    });

    yield* stream;
  }

  static Future<List<Map<String, dynamic>>> getDocuments({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/documents'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('data') && data['data'] is List) {
          return (data['data'] as List).cast<Map<String, dynamic>>();
        } else if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }

        throw Exception(
            'Неверный формат ответа сервера. Ожидался объект с полем data или массив документов. Получено: $data');
      } else {
        throw Exception(
            'Failed to get documents: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка получения документов: $e');
    }
  }

  static Future<bool> addDocumentWithPhoto({
    required String token,
    required Map<String, dynamic> document,
    File? photoFile,
  }) async {
    try {
      final docToSend = Map<String, dynamic>.from(document);

      if (docToSend['date'] != null && docToSend['date'] is String) {
        final dateStr = docToSend['date'] as String;
        if (dateStr.isNotEmpty) {
          try {
            final date = DateTime.parse(dateStr);
            docToSend['date'] = date.toUtc().toIso8601String();
          } catch (e) {
            print('Ошибка преобразования даты: $e');
          }
        }
      }

      if (photoFile != null) {
        final bytes = await photoFile.readAsBytes();
        docToSend['file_data'] = base64Encode(bytes);
      } else {
        docToSend.remove('file_data');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/documents/add'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(docToSend),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            'Server error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка при добавлении документа: $e');
    }
  }

  static Future<bool> removeDocument({
    required String token,
    required dynamic id,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/documents/remove/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            'Server error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка при удалении документа: $e');
    }
  }
}
