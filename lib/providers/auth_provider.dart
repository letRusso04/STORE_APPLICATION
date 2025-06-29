import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:store_application/models/user.dart';

String baseUrl = "http://10.0.2.2:5000/api";

class AuthProvider with ChangeNotifier {
  User? currentUser;
  bool get isLoggedIn => currentUser != null;

  // Ejemplo de login (ajusta según tu API)
  Future<bool> login({required String email, required String password}) async {
    try {
      final uri = Uri.parse('$baseUrl/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        currentUser = User.fromJson(data['user']);
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  // Registro (ajusta según tu API)
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? location,
    String? phone,
    String? estado,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/register');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'location': location,
          'phone': phone,
          'estado': estado,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error en registro: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception en register: $e');
      return false;
    }
  }

  // Actualizar usuario con imagen y nuevos campos
  Future<bool> updateUser({
    required String name,
    required String email,
    String? location,
    String? phone,
    String? estado,
    File? profileImageFile,
  }) async {
    if (currentUser == null) return false;
    try {
      var uri = Uri.parse('$baseUrl/profile/${currentUser!.id}');
      var request = http.MultipartRequest('PUT', uri);

      // Campos de texto
      request.fields['name'] = name;
      request.fields['email'] = email;
      if (location != null) request.fields['location'] = location;
      if (phone != null) request.fields['phone'] = phone;
      if (estado != null) request.fields['estado'] = estado;

      // Imagen perfil
      if (profileImageFile != null) {
        final mimeTypeData = lookupMimeType(profileImageFile.path)?.split('/');
        if (mimeTypeData != null && mimeTypeData.length == 2) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              profileImageFile.path,
              contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
              filename: path.basename(profileImageFile.path),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        currentUser = User.fromJson(data['user']);
        notifyListeners();
        return true;
      } else {
        print('Error actualizando usuario: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception en updateUser: $e');
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentUser == null) return false;

    final url = Uri.parse("$baseUrl/change_password");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': currentUser!.id,
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al cambiar contraseña: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción al cambiar contraseña: $e');
      return false;
    }
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }
}
