import 'package:dart_frog/dart_frog.dart';
//import 'package:drift/drift.dart';
import 'package:playlisted_api/database.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<AppDatabase>();

  // GET: List Games
  final games = await db.select(db.games).get();

  final result = games.map((g) {
    return {
      'id': g.id,
      'title': g.title,
      'summary': g.summary,
      'releaseYear': g.releaseYear,
      'isActive': g.isActive,
    };
  }).toList();
  return Response.json(body: result);
}
