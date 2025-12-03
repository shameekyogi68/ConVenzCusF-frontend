import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

class ApiService {
  // Use centralized configuration from AppConstants
  static const String baseUrl = AppConstants.userBaseUrl;


  // -----------------------
  // POST REQUEST
  // -----------------------
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {

    final String url = "$baseUrl$endpoint";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // -----------------------
  // GET REQUEST
  // -----------------------
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final String url = "$baseUrl$endpoint";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      return _handleResponse(response);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // -----------------------
  // RESPONSE HANDLER
  // -----------------------
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message":
          "Server error: ${response.statusCode} ${response.reasonPhrase}"
        };
      }
    } catch (e) {
      return {"success": false, "message": "Invalid server response"};
    }
  }
}
