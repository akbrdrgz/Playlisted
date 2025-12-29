import 'package:dart_frog/dart_frog.dart';
import 'package:playlisted_api/services/review_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  // [DART NATIVE] Extract the Service (Dependency Injection)
  final service = context.read<ReviewService>();
  // Parse the ID from the URL parameter
  final reviewId = int.tryParse(id);
  if (reviewId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Invalid ID format. Must be a number.'},
    );
  }
  // PUT Request - Update a review
  if (context.request.method == HttpMethod.put) {
    try {
      final body = await context.request.json();
      // Fetch review before updating
      final review = await service.getReviewById(reviewId);
      // [DART NATIVE] Partial update support - only update fields that are provided
      await service.updateReview(
        id: reviewId,
        rating: body['rating'] as double?,
        status: body['status'] as String?,
        reviewText: body['reviewText'] as String?,
        updatedBy: (body['updatedBy'] as String?) ?? 'system',
      );
      // Trigger achievement only if rating changed to 1 or 5
      final newRating = body['rating'] as double?;
      if (newRating != null && newRating != review?.rating) {
        if (newRating == 1.0) {
          await service.grantAchievementIfNotExists(
            review!.userId,
            'The Ultimate Disappointment',
          );
        } else if (newRating == 5.0) {
          await service.grantAchievementIfNotExists(
            review!.userId,
            'They Actually Cooked',
          );
        }
      }
      return Response.json(body: {'message': 'Review updated successfully'});
    } catch (e) {
      return Response.json(statusCode: 400, body: {'error': e.toString()});
    }
  }
  // DELETE Request - Soft delete a ereview
  if (context.request.method == HttpMethod.delete) {
    try {
      await service.deleteReview(reviewId);
      return Response.json(
        body: {'message': 'Review soft deleted successfully'},
      );
    } catch (e) {
      return Response.json(statusCode: 400, body: {'error': e.toString()});
    }
  }
  return Response(statusCode: 405);
}
