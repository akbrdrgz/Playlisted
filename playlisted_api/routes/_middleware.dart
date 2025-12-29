import 'package:dart_frog/dart_frog.dart';
import 'package:playlisted_api/database.dart';
import 'package:playlisted_api/services/user_service.dart';
import 'package:playlisted_api/services/game_service.dart';
import 'package:playlisted_api/services/feat_service.dart';
import 'package:playlisted_api/services/review_service.dart';
import 'package:playlisted_api/services/userAchievement_service.dart';

// [DART NATIVE] Singleton instantiation
// We only want ONE connection to the database
final _db = AppDatabase();
final _userService = UserService(_db);
final _gameService = GameService(_db);
final _featService = FeatService(_db);
final _reviewService = ReviewService(_db, _achievementService);
final _achievementService = UserAchievementService(_db);

// Seed database on startup
Future<void> _initializeDatabase() async {
  await _db.seedData();
}

Handler middleware(Handler handler) {
  // Trigger database seeding (runs once)
  _initializeDatabase();

  return handler
      .use(requestLogger())
      // [DART NATIVE] Injecting the Service for the Controllers to use
      .use(provider<UserService>((context) => _userService))
      .use(provider<GameService>((context) => _gameService))
      .use(provider<FeatService>((context) => _featService))
      .use(provider<ReviewService>((context) => _reviewService))
      .use(provider<UserAchievementService>((context) => _achievementService))

      // Inject DB (for the simple Species route)
      .use(provider<AppDatabase>((context) => _db));
}
