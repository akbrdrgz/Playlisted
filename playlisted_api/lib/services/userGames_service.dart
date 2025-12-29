import 'package:drift/drift.dart';
import 'package:playlisted_api/database.dart';

import 'package:playlisted_api/services/userAchievement_service.dart';

// USER GAME LOGS
class UserGameService {
  final AppDatabase _db;
  final UserAchievementService _achievementService;
  UserGameService(this._db, this._achievementService);

  // Add a game to user's list
  Future<void> logGame(
    int userId,
    int gameId, {
    String status = 'queued',
  }) async {
    final now = DateTime.now();
    // insert if it doesnt exist, update otherwise
    final existing = await (_db.select(_db.userGames)
          ..where((t) => t.userId.equals(userId) & t.gameId.equals(gameId)))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(
        _db.userGames,
      )..where((t) => t.userId.equals(userId) & t.gameId.equals(gameId)))
          .write(
        UserGamesCompanion(status: Value(status), updatedAt: Value(now)),
      );
    } else {
      await _db.into(_db.userGames).insert(
            UserGamesCompanion.insert(
              userId: userId,
              gameId: gameId,
              status: status,
              playedAt: now,
              updatedAt: now,
            ),
          );
    }

    // if status is cleared, grant achievement
    if (status == 'cleared') {
      await grantAchievement(userId);
    }
  }

  // Update status
  Future<void> updateGameStatus(int userId, int gameId, String status) async {
    final now = DateTime.now();
    await (_db.update(
      _db.userGames,
    )..where((t) => t.userId.equals(userId) & t.gameId.equals(gameId)))
        .write(
      UserGamesCompanion(status: Value(status), updatedAt: Value(now)),
    );

    // if status is cleared, grant achievement
    if (status == 'cleared') {
      await grantAchievement(userId);
    }
  }

  // Count games by status
  Future<int> countGamesByStatus(int userId, String status) async {
    return await (_db.select(_db.userGames)
          ..where((t) => t.userId.equals(userId) & t.status.equals(status)))
        .get()
        .then((rows) => rows.length);
  }

  // Get all games for a user - shows the user library
  /*
  Future<List<Map<String, dynamic>>> getUserGames(int userId) async {
    final rows = await (_db.select(
      _db.userGames,
    )..where((t) => t.userId.equals(userId)))
        .get();

    return rows.map((row) {
      return {
        'gameId': row.gameId,
        'status': row.status,
        'playedAt': row.playedAt.toIso8601String(),
        'updatedAt': row.updatedAt.toIso8601String(),
      };
    }).toList();
  } */
  // In your usergames_service.dart file, update this method:

  // Get all games for a user - shows the user library
  Future<List<Map<String, dynamic>>> getUserGames(int userId) async {
    final rows = await (_db.select(
      _db.userGames,
    )..where((t) => t.userId.equals(userId)))
        .get();

    return rows.map((row) {
      return {
        'id': row.id, // ✅ userGame ID
        'userId': row.userId, // ✅ FIXED: Include userId
        'gameId': row.gameId,
        'status': row.status,
        'playedAt': row.playedAt.toIso8601String(),
        'updatedAt': row.updatedAt.toIso8601String(),
      };
    }).toList();
  }

  Future<void> grantAchievement(int userId) async {
    // Count completed games
    final completedGames = await countGamesByStatus(userId, 'cleared');

    // Count reviews
    final reviewsCount = await (_db.select(
      _db.reviews,
    )..where((r) => r.userId.equals(userId)))
        .get()
        .then((rows) => rows.length);

    // Check latest rating
    final latestReview = await (_db.select(_db.reviews)
          ..where((r) => r.userId.equals(userId))
          ..orderBy([
            (r) => OrderingTerm(
                  expression: r.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();

    final latestRating = latestReview?.rating;

    // Call achievement service
    await _achievementService.checkAchievements(
      userId: userId,
      completedGames: completedGames,
      reviewsCount: reviewsCount,
      latestRating: latestRating,
    );
  }
}
