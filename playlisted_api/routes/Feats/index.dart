import 'package:dart_frog/dart_frog.dart';
//import 'package:drift/drift.dart';
import 'package:playlisted_api/database.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<AppDatabase>();

  // GET: List Achievements
  final all = await db.select(db.achievements).get();
  return Response.json(body: all);
}
