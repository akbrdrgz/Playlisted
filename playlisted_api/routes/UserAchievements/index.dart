import 'package:dart_frog/dart_frog.dart';
import 'package:playlisted_api/database.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<AppDatabase>();

  // Get userId from query
  final userIdParam = context.request.uri.queryParameters['userId'];
  final userId = userIdParam != null ? int.tryParse(userIdParam) : null;

  if (userId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing userId parameter'},
    );
  }

  // Fetch user's achievements
  final rows = await (db.select(db.userAchievements)
        ..where((ua) => ua.userId.equals(userId)))
      .get();

  // Map to displayable data
  final achievements = await Future.wait(
    rows.map((ua) async {
      final achievement = await (db.select(db.achievements)
            ..where((a) => a.id.equals(ua.achievementId)))
          .getSingleOrNull();

      return {
        'name': achievement?.name,
        'description': achievement?.description,
        'achievedAt': ua.achievedAt.toIso8601String(),
      };
    }),
  );

  return Response.json(body: achievements);
}
