//import 'package:drift/drift.dart';
import 'package:playlisted_api/database.dart';

// CANNOT BE ALTERED BY USERS
class FeatService {
  FeatService(this._db);
  final AppDatabase _db;

  // 1. READ LOGIC - Get all games
  Future<List<Map<String, dynamic>>> getAllGames() async {
    final rows = await _db.select(_db.achievements).get();

    return rows.map((achievements) {
      return {
        'id': achievements.id,
        'name': achievements.name,
        'description': achievements.description,
      };
    }).toList();
  }
}
