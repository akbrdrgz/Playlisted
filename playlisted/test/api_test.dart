import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  final baseUrl = Uri.parse('http://localhost:8080');

  group('API Connection Tests', () {
    test('GET /Users returns 200 OK', () async {
      final response = await http.get(baseUrl.replace(path: '/Users'));
      expect(response.statusCode, 200);
    });

    test('GET /Users returns data', () async {
      final response = await http.get(baseUrl.replace(path: '/Users'));
      expect(response.body.isNotEmpty, true);
    });

    test('GET /unknown_route returns 404', () async {
      final response = await http.get(baseUrl.replace(path: '/api/ghosts'));
      expect(response.statusCode, 404);
    });
  });
}
