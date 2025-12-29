import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:playlisted_api/database.dart';
import 'package:playlisted_api/services/userAchievement_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<AppDatabase>();

  // POST: Write Reviews
  if (context.request.method == HttpMethod.post) {
    final body = await context.request.json();
    final now = DateTime.now();

    // [ORM / DRIFT] Simple Insert
    await db.into(db.reviews).insert(
          ReviewsCompanion.insert(
            userId: body['userId'] as int,
            gameId: body['gameId'] as int,
            rating: body['rating'] as double,
            status: body['status'] as String,
            reviewText: body['reviewText'] != null
                ? Value(body['reviewText'] as String)
                : const Value.absent(),
            createdAt: now,
            updatedAt: now,
            isActive: Value(true),
            createdBy: 'system',
            updatedBy: 'system',
          ),
        );

    final userId = body['userId'] as int;
    final userReviews = await (db.select(db.reviews)
          ..where((r) => r.userId.equals(userId)))
        .get();
    final reviewsCount = userReviews.length;
    final latestRating = userReviews.isNotEmpty ? userReviews.last.rating : 0.0;

    // Trigger achievements
    final achievementService = UserAchievementService(db);
    await achievementService.checkAchievements(
        userId: userId, reviewsCount: reviewsCount, latestRating: latestRating);
    return Response.json(body: {'message': 'Review added'});
  }

  // GET: List Reviews
  final all = await (db.select(db.reviews)
        ..where((r) => r.isActive.equals(true)))
      .get();
  return Response.json(body: all);
}
