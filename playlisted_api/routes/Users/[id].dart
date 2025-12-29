import 'package:dart_frog/dart_frog.dart';
import 'package:playlisted_api/services/user_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  // [DART NATIVE] Extract the Service (Dependency Injection)
  final service = context.read<UserService>();
  // Parse the ID from the URL parameter
  final userId = int.tryParse(id);
  if (userId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Invalid ID format. Must be a number.'},
    );
  }

  // PUT Request - Update a user
  if (context.request.method == HttpMethod.put) {
    try {
      final body = await context.request.json();

      // [DART NATIVE] Partial update support - only update fields that are provided
      await service.updateUser(
        id: userId,
        username: body['username'] as String?,
        password: body['password'] as String?,
        updatedBy: (body['updatedBy'] as String?) ?? 'system',
      );

      return Response.json(body: {'message': 'User updated successfully'});
    } catch (e) {
      return Response.json(statusCode: 400, body: {'error': e.toString()});
    }
  }

  // DELETE Request - Soft delete a user
  if (context.request.method == HttpMethod.delete) {
    try {
      await service.deleteUser(userId);
      return Response.json(body: {'message': 'User soft deleted successfully'});
    } catch (e) {
      return Response.json(statusCode: 400, body: {'error': e.toString()});
    }
  }

  return Response(statusCode: 405);
}
