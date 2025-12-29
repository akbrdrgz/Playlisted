//import 'package:drift/drift.dart';
import 'package:playlisted_api/database.dart';

// CANNOT BE ALTERED BY USERS
// STORES ALL GAMES IN THE APP
class GameService {
  GameService(this._db);
  final AppDatabase _db;

  // 1. READ LOGIC - Get all games
  Future<List<Map<String, dynamic>>> getAllGames() async {
    final rows = await _db.select(_db.games).get();

    return rows.map((game) {
      return {
        'id': game.id,
        'title': game.title,
        'summary': game.summary,
        'releaseYear': game.releaseYear,
        'isActive': game.isActive,
      };
    }).toList();
  }
}
