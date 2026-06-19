import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://10.130.51.73:3000';

  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/ping'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<int> measurePing() async {
    try {
      final stopwatch = Stopwatch()..start();

      final response = await http
          .get(Uri.parse('$baseUrl/ping'))
          .timeout(const Duration(seconds: 5));

      stopwatch.stop();

      if (response.statusCode == 200) {
        return stopwatch.elapsedMilliseconds;
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  static Future<double> measureDownloadSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();

      final response = await http
          .get(Uri.parse('$baseUrl/download'))
          .timeout(const Duration(seconds: 30));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final bytes = response.contentLength ?? response.bodyBytes.length;
        final seconds = stopwatch.elapsedMilliseconds / 1000;
        final mbps = (bytes * 8) / (seconds * 1000000);
        return double.parse(mbps.toStringAsFixed(2));
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }

  static Future<double> measureUploadSpeed() async {
    try {
      const size = 2 * 1024 * 1024;
      final data = List.generate(size, (i) => i % 256);
      final bytes = Uint8List.fromList(data);

      final stopwatch = Stopwatch()..start();

      final response = await http
          .post(
            Uri.parse('$baseUrl/upload'),
            headers: {'Content-Type': 'application/octet-stream'},
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final seconds = stopwatch.elapsedMilliseconds / 1000;
        final mbps = (size * 8) / (seconds * 1000000);
        return double.parse(mbps.toStringAsFixed(2));
      }
      return -1;
    } catch (e) {
      return -1;
    }
  }
}
