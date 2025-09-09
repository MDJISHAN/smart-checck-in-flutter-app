import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl; // from .env (without /webhook/... paths)
  ApiService(this.baseUrl);
// 🔑 Parse response safely
  Map<String, dynamic> _parseResponse(http.Response resp) {
    try {
      if (resp.headers['content-type']?.contains('application/json') == true) {
        return {
          'status': resp.statusCode,
          'body': jsonDecode(resp.body),
        };
      } else {
        return {
          'status': resp.statusCode,
          'body': {'error': resp.body},
        };
      }
    } catch (e) {
      return {
        'status': resp.statusCode,
        'body': {'error': e.toString()},
      };
    }
  }

  // 🔑 Login
  Future<Map<String, dynamic>> login(String empId, String password, String deviceId) async {
    final url = Uri.parse('$baseUrl/webhook/login');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employee_id': empId,
        'password': password,
        'device_id': deviceId
      }),
    );
    return _parseResponse(resp);
  }

      // 🕑 Check-in / Check-out with photo + GPS
  Future<Map<String, dynamic>> sendCheck({
  required String token,
  required String empId,
  required String name,
  required String action, // "check-in" / "check-out"
  required String location, // human-readable address
  required String deviceId,
  File? photoFile,
}) async {
  final url = Uri.parse('$baseUrl/webhook/employee-checkin');
  print("➡️ Sending POST to $url");

  final req = http.MultipartRequest('POST', url);

  // ✅ Set headers
  req.headers.addAll({
    'Authorization': 'Bearer $token',
    'Content-Type': 'multipart/form-data',
  });

  // ✅ Add fields
  req.fields['employee_id'] = empId;
  req.fields['name'] = name;
  req.fields['action'] = action;
  req.fields['location'] = location;
  req.fields['device_id'] = deviceId;

  // ✅ Attach photo if present
  if (photoFile != null) {
    final fileStream = http.ByteStream(photoFile.openRead());
    final length = await photoFile.length();
    req.files.add(
      http.MultipartFile(
        'photo',
        fileStream,
        length,
        filename: photoFile.path.split("/").last,
      ),
    );
  }

  try {
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);

    print("⬅️ Response code: ${response.statusCode}");
    print("⬅️ Response body: ${response.body}");

    return _parseResponse(response);
  } catch (e) {
    print("❌ Error sending request: $e");
    return {'status': 'error', 'message': e.toString()};
  }
}


   // 📱 Bind device (after login)
  Future<Map<String, dynamic>> bindDevice({
    required String empId,
    required String token,
    required String deviceId,
  }) async {
    final url = Uri.parse('$baseUrl/webhook/auth-bind-device');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'employee_id': empId, 'device_id': deviceId}),
    );
    // Print status code
      print('Login status code: ${resp.statusCode}');

      // Print full response body
      print('Login response body: ${resp.body}');
    return _parseResponse(resp);
  }



  // 📊 Attendance without photo (simple check-in/out)
  Future<Map<String, dynamic>> sendAttendance({
    required String empId,
    required String name,
    required String type, // "check-in" or "check-out"
    required String timestamp,
    required String location,


  }) async {
    final url = "$baseUrl/webhook/employee-checkin";
    final res = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "emp_id": empId,
        "name":   name,
        "type": type,
        "timestamp": timestamp,
        "location": location,
      }),
    );
     print('Login status code: ${res.statusCode}');

      // Print full response body
      print('Login response body: ${res.body}');

    return {
      "status": res.statusCode,
      "body": jsonDecode(res.body),
    };
  }
}

