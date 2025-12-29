import 'package:dart_frog/dart_frog.dart';
import 'package:playlisted_api/database.dart';
import 'package:playlisted_api/services/userAchievement_service.dart';
import 'package:playlisted_api/services/userGames_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<AppDatabase>();
  final achievementService = UserAchievementService(db);
  final gameService = UserGameService(db, achievementService);

  // Get query parameters (optional userId)
  final userIdParam = context.request.uri.queryParameters['userId'];
  final userId = userIdParam != null ? int.tryParse(userIdParam) : null;

  try {
    // GET: Fetch all games for a user
    if (context.request.method == HttpMethod.get) {
      if (userId == null) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Missing userId parameter'},
        );
      }

      final games = await gameService.getUserGames(userId);
      return Response.json(body: games);
    }

    // POST: Log a new game
    if (context.request.method == HttpMethod.post) {
      final body = await context.request.json();
      final userId = body['userId'] as int;
      final gameId = body['gameId'] as int;
      final status = (body['status'] as String?) ?? 'queued';

      await gameService.logGame(userId, gameId, status: status);

      return Response.json(body: {'message': 'Game logged successfully'});
    }

    // PUT: Update game status
    if (context.request.method == HttpMethod.put) {
      final body = await context.request.json();
      final userId = body['userId'] as int;
      final gameId = body['gameId'] as int;
      final status = body['status'] as String;

      await gameService.updateGameStatus(userId, gameId, status);

      return Response.json(body: {'message': 'Game status updated'});
    }

    // Method not allowed
    return Response(statusCode: 405, body: 'Method not allowed');
  } catch (e) {
    return Response.json(statusCode: 400, body: {'error': e.toString()});
  }
}
