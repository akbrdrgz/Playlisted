import 'package:drift/drift.dart';
import 'package:playlisted_api/database.dart';

class UserAchievementService {
  UserAchievementService(this._db);
  final AppDatabase _db;

  //Check and grant Achievements
  Future<void> checkAchievements({
    required int userId,
    int? completedGames,
    int? reviewsCount,
    double? latestRating,
  }) async {
    // a. "First Blood" - log your first game
    if (completedGames != null && completedGames == 1) {
      await grantAchievement(userId, 'First Blood');
    }

    // b. "Praise the Sun" - write first review
    if (reviewsCount != null && reviewsCount == 1) {
      await grantAchievement(userId, 'Praise the Sun');
    }

    // c. "Stay Determined" - complete 10 games
    if (completedGames != null && completedGames == 10) {
      await grantAchievement(userId, 'Stay Determined');
    }

    // d. "The Ultimate Disappointment" - give a game 1 star
    if (latestRating != null && latestRating == 1.0) {
      await grantAchievement(userId, 'The Ultimate Disappointment');
    }

    // e. "They Actually Cooked" - give a game 5 stars
    if (latestRating != null && latestRating == 5.0) {
      await grantAchievement(userId, 'They Actually Cooked');
    }
  }

  /// Grant an achievement if user doesn't already have it
  Future<void> grantAchievement(int userId, String achievementName) async {
    final achievement = await (_db.select(_db.achievements)
          ..where((a) => a.name.equals(achievementName)))
        .getSingleOrNull();

    if (achievement == null) return;

    final exists = await (_db.select(_db.userAchievements)
          ..where(
            (ua) =>
                ua.userId.equals(userId) &
                ua.achievementId.equals(achievement.id),
          ))
        .getSingleOrNull();

    if (exists == null) {
      await _db.into(_db.userAchievements).insert(
            UserAchievementsCompanion.insert(
              userId: userId,
              achievementId: achievement.id,
              achievedAt: DateTime.now(),
            ),
          );
      print(' Achievement unlocked: $achievementName for user $userId');
    }
  }
}
