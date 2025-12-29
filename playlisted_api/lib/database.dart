import 'package:dotenv/dotenv.dart';
import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart';

part 'database.g.dart';

// =========================
// USERS TABLE
// =========================
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text()();
  TextColumn get password => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text()();
  TextColumn get updatedBy => text()();
}

// =========================
// GAMES TABLE (static)
// =========================
class Games extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  IntColumn get releaseYear => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

// =========================
// USER GAMES TABLE (logged games)
// =========================
class UserGames extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('REFERENCES users(id)')();
  IntColumn get gameId => integer().customConstraint('REFERENCES games(id)')();
  TextColumn get status => text().check(
        const Constant('queued').equals('queued') |
            const Constant('cleared').equals('cleared') |
            const Constant('dropped').equals('dropped') |
            const Constant('paused').equals('paused') |
            const Constant('playing').equals('playing'),
      )();
  DateTimeColumn get playedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, gameId},
      ];
}

// =========================
// ACHIEVEMENTS TABLE
// =========================
class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

// =========================
// USER ACHIEVEMENTS TABLE
// =========================
class UserAchievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('REFERENCES users(id)')();
  IntColumn get achievementId =>
      integer().customConstraint('REFERENCES achievements(id)')();
  DateTimeColumn get achievedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, achievementId},
      ];
}

// =========================
// REVIEWS TABLE
// =========================
class Reviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().customConstraint('REFERENCES users(id) ON DELETE CASCADE')();
  IntColumn get gameId =>
      integer().customConstraint('REFERENCES games(id) ON DELETE CASCADE')();
  RealColumn get rating =>
      real().customConstraint('CHECK (rating >= 0 AND rating <= 5)')();
  TextColumn get status => text().check(
        const Constant('cleared').equals('cleared') |
            const Constant('dropped').equals('dropped') |
            const Constant('playing').equals('playing'),
      )();
  TextColumn get reviewText => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdBy => text()();
  TextColumn get updatedBy => text()();
}

@DriftDatabase(
  tables: [Users, Games, UserGames, Achievements, UserAchievements, Reviews],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // DATABASE SEEDING - Pre-populate with sample data
  Future<void> seedData() async {
    final now = DateTime.now();

    // -------------------------
    // USERS
    // -------------------------
    final usersCount =
        await (select(users)..where((t) => t.isActive.equals(true))).get();

    if (usersCount.isEmpty) {
      final akiaId = await into(users).insert(
        UsersCompanion.insert(
          username: 'akia',
          password: 'akia123',
          createdAt: now,
          updatedAt: now,
          isActive: const Value(true),
          createdBy: 'system',
          updatedBy: 'system',
        ),
      );

      final ellaId = await into(users).insert(
        UsersCompanion.insert(
          username: 'ella',
          password: 'ella123',
          createdAt: now,
          updatedAt: now,
          isActive: const Value(true),
          createdBy: 'system',
          updatedBy: 'system',
        ),
      );

      print('✅ Users seeded');
    } else {
      print('ℹ️ Users already exist, skipping');
    }

    // -------------------------
    // GAMES
    // -------------------------
    final gamesCount = await select(games).get();

    if (gamesCount.isEmpty) {
      final d1 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Danganronpa: Trigger Happy Havoc',
          summary:
              'A group of elite students are trapped in a deadly killing game where murder is the only way to escape.',
          releaseYear: 2010,
          isActive: const Value(true),
        ),
      );

      final d2 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Danganronpa 2: Goodbye Despair',
          summary:
              'Students are stranded on a tropical island where despair returns in an even deadlier killing game.',
          releaseYear: 2012,
          isActive: const Value(true),
        ),
      );

      final d3 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Danganronpa V3: Killing Harmony',
          summary:
              'A new cast of students is thrust into a twisted killing game that challenges the meaning of truth and lies.',
          releaseYear: 2017,
          isActive: const Value(true),
        ),
      );

      final g4 = await into(games).insert(
        GamesCompanion.insert(
          title: 'The Legend of Zelda: Breath of the Wild',
          summary:
              'An open-world adventure where Link explores a vast land to defeat Calamity Ganon.',
          releaseYear: 2017,
          isActive: const Value(true),
        ),
      );

      final g5 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Elden Ring',
          summary:
              'A vast open-world action RPG set in a dark fantasy universe created with George R. R. Martin.',
          releaseYear: 2022,
          isActive: const Value(true),
        ),
      );

      final g6 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Dark Souls',
          summary:
              'A punishing action RPG known for its difficulty and cryptic storytelling.',
          releaseYear: 2011,
          isActive: const Value(true),
        ),
      );

      final g7 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Hades',
          summary:
              'A rogue-like dungeon crawler where you defy the god of the dead.',
          releaseYear: 2020,
          isActive: const Value(true),
        ),
      );

      final g8 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Celeste',
          summary:
              'A precision platformer about climbing a mountain and confronting inner struggles.',
          releaseYear: 2018,
          isActive: const Value(true),
        ),
      );

      final g9 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Undertale',
          summary:
              'A unique RPG where players can choose non-violent solutions to conflict.',
          releaseYear: 2015,
          isActive: const Value(true),
        ),
      );

      final g10 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Stardew Valley',
          summary:
              'A relaxing farming and life simulation game set in a small town.',
          releaseYear: 2016,
          isActive: const Value(true),
        ),
      );

      final g11 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Persona 5 Royal',
          summary:
              'A stylish JRPG about phantom thieves changing corrupt hearts.',
          releaseYear: 2020,
          isActive: const Value(true),
        ),
      );

      final g12 = await into(games).insert(
        GamesCompanion.insert(
          title: 'God of War',
          summary:
              'A mythological action-adventure following Kratos and his son.',
          releaseYear: 2018,
          isActive: const Value(true),
        ),
      );

      final g13 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Red Dead Redemption 2',
          summary: 'An epic tale of life in America’s unforgiving heartland.',
          releaseYear: 2018,
          isActive: const Value(true),
        ),
      );

      final g14 = await into(games).insert(
        GamesCompanion.insert(
          title: 'The Witcher 3: Wild Hunt',
          summary:
              'A story-driven RPG set in a visually stunning fantasy universe.',
          releaseYear: 2015,
          isActive: const Value(true),
        ),
      );

      final g15 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Hollow Knight',
          summary:
              'A hand-drawn action-adventure set in a vast underground kingdom.',
          releaseYear: 2017,
          isActive: const Value(true),
        ),
      );

      final g16 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Final Fantasy VII',
          summary: 'A classic JRPG about eco-terrorism and identity.',
          releaseYear: 1997,
          isActive: const Value(true),
        ),
      );

      final g17 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Mass Effect 2',
          summary:
              'A sci-fi RPG where your choices shape the fate of the galaxy.',
          releaseYear: 2010,
          isActive: const Value(true),
        ),
      );

      final g18 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Disco Elysium',
          summary:
              'A narrative-driven RPG focused on dialogue, choice, and consequence.',
          releaseYear: 2019,
          isActive: const Value(true),
        ),
      );

      final g19 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Minecraft',
          summary:
              'A sandbox game about creativity, survival, and exploration.',
          releaseYear: 2011,
          isActive: const Value(true),
        ),
      );

      final g20 = await into(games).insert(
        GamesCompanion.insert(
          title: 'Portal 2',
          summary: 'A puzzle game with innovative mechanics and dark humor.',
          releaseYear: 2011,
          isActive: const Value(true),
        ),
      );

      print('✅ 20 games seeded');
    } else {
      print('ℹ️ Games already exist, skipping');
    }

    // -------------------------
    // ACHIEVEMENTS
    // -------------------------
    final achievementsCount = await select(achievements).get();

    if (achievementsCount.isEmpty) {
      final firstBloodId = await into(achievements).insert(
        AchievementsCompanion.insert(
          name: 'First Blood',
          description: 'Clear your first game',
        ),
      );

      final praiseTheSunId = await into(achievements).insert(
        AchievementsCompanion.insert(
          name: 'Praise the Sun',
          description: 'Write your first review',
        ),
      );

      final stayDeterminedId = await into(achievements).insert(
        AchievementsCompanion.insert(
          name: 'Stay Determined',
          description: 'Complete 10 games',
        ),
      );

      final disappointmentId = await into(achievements).insert(
        AchievementsCompanion.insert(
          name: 'The Ultimate Disappointment',
          description: 'Give a game 1 star',
        ),
      );

      final cookedId = await into(achievements).insert(
        AchievementsCompanion.insert(
          name: 'They Actually Cooked',
          description: 'Give a game 5 stars',
        ),
      );

      print('✅ Achievements seeded');
    } else {
      print('ℹ️ Achievements already exist, skipping');
    }

    /*
 // -------------------------
 // Sample Review
 // -------------------------
 final reviewsCount = await (select(reviews)).get();
 if (reviewsCount.isEmpty) {
   final akia = await (select(users)..where((u) => u.username.equals('akia'))).getSingle();
   final d1 = await (select(games)..where((g) => g.title.equals('Danganronpa: Trigger Happy Havoc'))).getSingle();


   await into(reviews).insert(
     ReviewsCompanion.insert(
       userId: akia.id,
       gameId: d1.id,
       rating: 4.5,
       status: 'cleared',
       reviewText: const Value('Kyoko Kirigiri top 10 goats'),
       createdAt: now,
       updatedAt: now,
       isActive: Value(true),
       createdBy: 'system',
       updatedBy: 'system',
     ),
   );

   print('✅ Sample review seeded');
 }
 */
  }
}

// [SECURITY] Connection Configuration with Environment Variables
QueryExecutor _openConnection() {
  // Load environment variables from .env file
  final env = DotEnv()..load();

  // Get database credentials from environment variables
  // NO DEFAULTS - Fail fast if .env is missing or incomplete
  final host = env['DB_HOST'];
  final portStr = env['DB_PORT'];
  final database = env['DB_NAME'];
  final username = env['DB_USER'];
  final password = env['DB_PASSWORD'];

  // Validate all required environment variables are present
  if (host == null || host.isEmpty) {
    throw Exception('DB_HOST is not set in .env file');
  }
  if (portStr == null || portStr.isEmpty) {
    throw Exception('DB_PORT is not set in .env file');
  }
  if (database == null || database.isEmpty) {
    throw Exception('DB_NAME is not set in .env file');
  }
  if (username == null || username.isEmpty) {
    throw Exception('DB_USER is not set in .env file');
  }
  if (password == null || password.isEmpty) {
    throw Exception('DB_PASSWORD is not set in .env file');
  }

  final port = int.parse(portStr);

  return PgDatabase(
    endpoint: Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );
}
