import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:playlisted_api/database.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<AppDatabase>();

  // POST: Create Users
  if (context.request.method == HttpMethod.post) {
    final body = await context.request.json();
    final now = DateTime.now();

    // [ORM / DRIFT] Simple Insert
    await db.into(db.users).insert(
          UsersCompanion.insert(
            username: body['username'] as String,
            password: body['password'] as String,
            createdAt: now,
            updatedAt: now,
            isActive: const Value(true),
            createdBy: 'system',
            updatedBy: 'system',
          ),
        );
    return Response.json(body: {'message': 'User added'});
  }

  // GET: List Users
  final all =
      await (db.select(db.users)..where((u) => u.isActive.equals(true))).get();
  return Response.json(body: all);
}
