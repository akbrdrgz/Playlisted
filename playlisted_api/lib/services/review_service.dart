import 'package:drift/drift.dart';
import 'package:playlisted_api/database.dart';
import 'package:playlisted_api/services/userAchievement_service.dart';

class ReviewService {
  ReviewService(this._db, this._achievementService);
  final AppDatabase _db;
  final UserAchievementService _achievementService;
  // 1. READ LOGIC - Get all ACTIVE reviews
  Future<List<Map<String, dynamic>>> getAllReviews() async {
    final rows = await (_db.select(_db.reviews)
          ..where((r) => r.isActive.equals(true)))
        .get();
    return rows.map((review) {
      return {
        'userId': review.userId,
        'gameId': review.gameId,
        'rating': review.rating,
        'status': review.status,
        'reviewText': review.reviewText,
        'createdAt': review.createdAt.toIso8601String(),
        'updatedAt': review.updatedAt.toIso8601String(),
        'createdBy': review.createdBy,
        'updatedBy': review.updatedBy,
      };
    }).toList();
  }

  // 2. CREATE LOGIC
  Future<void> createReview({
    required int userId,
    required int gameId,
    required double rating,
    required String status,
    String? reviewText,
    String createdBy = 'system',
  }) async {
    // a. Validate User
    final user = await (_db.select(_db.users)
          ..where((u) => u.id.equals(userId) & u.isActive.equals(true)))
        .getSingleOrNull();
    if (user == null) {
      throw Exception('Active user ID $userId does not exist.');
    }
    // b. Validate Game
    final game = await (_db.select(_db.games)
          ..where((g) => g.id.equals(gameId) & g.isActive.equals(true)))
        .getSingleOrNull();
    if (game == null) {
      throw Exception('Active game ID $gameId does not exist.');
    }
    final now = DateTime.now();
    // c. Insert Review
    await _db.into(_db.reviews).insert(
          ReviewsCompanion.insert(
            userId: userId,
            gameId: gameId,
            rating: rating,
            status: status,
            reviewText:
                reviewText != null ? Value(reviewText) : const Value.absent(),
            createdAt: now,
            updatedAt: now,
            isActive: const Value(true),
            updatedBy: createdBy,
            createdBy: createdBy,
          ),
        );
  }

  // 3. UPDATE LOGIC
  Future<void> updateReview({
    required int id,
    double? rating,
    String? status,
    String? reviewText,
    String updatedBy = 'system',
  }) async {
    final review = await (_db.select(_db.reviews)
          ..where((r) => (r.id.equals(id)) & (r.isActive.equals(true))))
        .getSingleOrNull();
    if (review == null) {
      throw Exception('Review does not exist.');
    }
    final now = DateTime.now();
    await (_db.update(_db.reviews)..where((r) => r.id.equals(id))).write(
      ReviewsCompanion(
        rating: rating != null ? Value(rating) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        reviewText:
            reviewText != null ? Value(reviewText) : const Value.absent(),
        updatedAt: Value(now),
        updatedBy: Value(updatedBy),
      ),
    );
  }

  // 4. SOFT DELETE LOGIC
  Future<void> deleteReview(int id, {String deletedBy = 'system'}) async {
    final review = await (_db.select(_db.reviews)
          ..where((r) => r.id.equals(id) & r.isActive.equals(true)))
        .getSingleOrNull();
    if (review == null) {
      throw Exception('Review does not exist.');
    }
    final now = DateTime.now();
    await (_db.update(_db.reviews)..where((r) => r.id.equals(id))).write(
      ReviewsCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
        updatedBy: Value(deletedBy),
      ),
    );
  }

  // 5. GET REVIEW BY ID
  Future<Review?> getReviewById(int id) async {
    return (_db.select(_db.reviews)
          ..where((r) => r.id.equals(id) & r.isActive.equals(true)))
        .getSingleOrNull();
  }

// 6. GRANT ACHIEVEMENT IF NOT ALREADY GRANTED (for 1-star or 5-star ratings)
  Future<void> grantAchievementIfNotExists(
    int userId,
    String achievementName,
  ) async {
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
      print('Achievement unlocked: $achievementName for user $userId');
    }
  }

  Future<int> countReviews(int userId) async {
    return (_db.select(_db.reviews)..where((r) => r.userId.equals(userId)))
        .get()
        .then((rows) => rows.length);
  }
}
