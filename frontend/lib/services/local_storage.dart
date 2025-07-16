import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocalStorage {
  static const String _authTokenKey = 'auth_token';
  static const String _name = 'name';
  static const String _email = 'email';
  static const String _snils = 'snils';
  static const String _passport = 'passport';
  static const String _blood = 'blood';
  static const String _chronic = 'chronic';
  static const String _baseUrl = 'http://localhost:8080';
  static const String _medsKey = 'medications';
  static const String _chatsKey = 'chats';
  static const String _docsKey = 'documents';

  static Future<void> saveAuthData(
      String token, Map<String, dynamic> info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
    await prefs.setString(_name, info['name']);
    await prefs.setString(_email, info['email']);
    if (info['snils'] == null) {
      await prefs.setString(_snils, '');
    } else {
      await prefs.setString(_snils, info['snils']);
    }

    if (info['passport'] == null) {
      await prefs.setString(_passport, '');
    } else {
      await prefs.setString(_passport, info['passport']);
    }

    if (info['blood_type'] == null) {
      await prefs.setString(_blood, '');
    } else {
      await prefs.setString(_blood, info['blood_type']);
    }

    if (info['chronic_cond'] == null) {
      await prefs.setString(_chronic, '');
    } else {
      await prefs.setString(_chronic, info['chronic_cond']);
    }
  }

  static Future<Map<String, dynamic>?> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);

    if (token != null) {
      return {
        'token': token,
        'name': prefs.getString(_name),
        'email': prefs.getString(_email),
        'snils': prefs.getString(_snils),
        'passport': prefs.getString(_passport),
        'blood_type': prefs.getString(_blood),
        'chronic_cond': prefs.getString(_chronic),
      };
    }
    return null;
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_name);
    await prefs.remove(_email);
    await prefs.remove(_snils);
    await prefs.remove(_passport);
    await prefs.remove(_blood);
    await prefs.remove(_chronic);
  }

  // В классе LocalStorage измените метод updateAuthData:
  static Future<bool> updateAuthData(Map<String, dynamic> newData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);

      if (token == null) {
        print('Token is null');
        return false;
      }

      // Сначала сохраняем локально
      if (newData['blood_type'] != null) {
        await prefs.setString(_blood, newData['blood_type']);
      }
      if (newData['passport'] != null) {
        await prefs.setString(_passport, newData['passport']);
      }
      if (newData['snils'] != null) {
        await prefs.setString(_snils, newData['snils']);
      }
      if (newData['chronic_cond'] != null) {
        await prefs.setString(_chronic, newData['chronic_cond']);
      }

      // Затем отправляем на сервер
      print('Sending update to server: $newData');
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(newData),
      );

      print('Server response: ${response.statusCode} ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating auth data: $e');
      return false;
    }
  }

  static Future<void> saveMeds(List<Map<String, dynamic>> meds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_medsKey, jsonEncode(meds));
  }

  static Future<List<Map<String, dynamic>>> getMeds() async {
    final prefs = await SharedPreferences.getInstance();
    final medsString = prefs.getString(_medsKey);
    if (medsString != null) {
      final List<dynamic> jsonList = jsonDecode(medsString);
      return jsonList.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<void> saveChats(List<Map<String, dynamic>> chats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatsKey, jsonEncode(chats));
  }

  static Future<List<Map<String, dynamic>>> getChats() async {
    final prefs = await SharedPreferences.getInstance();
    final chatsString = prefs.getString(_chatsKey);
    if (chatsString != null) {
      final List<dynamic> jsonList = jsonDecode(chatsString);
      return jsonList.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<void> saveDocuments(List<Map<String, dynamic>> docs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_docsKey, jsonEncode(docs));
  }

  static Future<List<Map<String, dynamic>>> getDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final docsString = prefs.getString(_docsKey);
    if (docsString != null) {
      final List<dynamic> jsonList = jsonDecode(docsString);
      return jsonList.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
