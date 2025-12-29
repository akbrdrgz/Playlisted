// test/unit_test.dart
import 'package:flutter_test/flutter_test.dart';

/// Simple function to "parse" a game from JSON
Map<String, dynamic> parseGame(Map<String, dynamic> json) {
  return {'title': json['title'] ?? 'Unknown', 'year': json['year'] ?? 2000};
}

/// Simple utility function to validate usernames
bool isValidUsername(String username) {
  return username.isNotEmpty && username.length >= 3;
}

void main() {
  group('Unit Tests', () {
    // 1️⃣ Happy Path: parses valid JSON
    test('Happy Path: parseGame parses valid JSON', () {
      final json = {'title': 'Zelda', 'year': 2023};
      final game = parseGame(json);

      expect(game['title'], 'Zelda');
      expect(game['year'], 2023);
    });

    // 2️⃣ Edge Case: missing or null fields
    test('Edge Case: parseGame handles missing fields', () {
      final json = {'title': null};
      final game = parseGame(json);

      expect(game['title'], 'Unknown'); // default value
      expect(game['year'], 2000); // default value
    });

    // 3️⃣ Logic: username validation
    test('Logic: username validation works correctly', () {
      expect(isValidUsername('Alex'), true);
      expect(isValidUsername('Al'), false); // too short
      expect(isValidUsername(''), false); // empty string
    });
  });
}
