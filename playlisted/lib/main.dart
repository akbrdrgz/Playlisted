import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; //For API calls
import 'package:flutter/rendering.dart'; //For text shadows
import 'package:flutter/services.dart';

void main() {
  runApp(const PlaylistedApp());
}

class PlaylistedApp extends StatelessWidget {
  const PlaylistedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Playlisted',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF5a9a9a),
        scaffoldBackgroundColor: const Color(0xFFe5ddd5),
        fontFamily: 'monospace',
      ),
      home: const AuthScreen(),
    );
  }
}

// ============================================
// NOTIFICATION SERVICE FOR CENTERED POP-UPS
// ============================================
class NotificationService {
  // Show centered notification
  static void showCenteredNotification({
    required BuildContext context,
    required String message,
    Color backgroundColor = const Color(0xFF5a9a9a),
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  // Show success notification
  static void showSuccessNotification({
    required BuildContext context,
    required String message,
  }) {
    showCenteredNotification(
      context: context,
      message: message,
      backgroundColor: const Color(0xFF5a9a9a),
    );
  }

  // Show error notification
  static void showErrorNotification({
    required BuildContext context,
    required String message,
  }) {
    showCenteredNotification(
      context: context,
      message: message,
      backgroundColor: Colors.red,
    );
  }
}

// User Model
class User {
  final int id;
  final String username;
  final String password;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

// ============================================
// FIXED AUTHENTICATION SERVICE
// ============================================
class AuthService {
  static const String baseUrl = 'http://localhost:8080';

  // ✅ FIXED: Login now checks the REAL database
  static Future<bool> login(String username, String password) async {
    try {
      // Fetch all users from the actual database
      final response = await http.get(Uri.parse('$baseUrl/Users'));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch users from database');
      }

      final List<dynamic> users = jsonDecode(response.body);

      // Find user with matching credentials
      final user = users.firstWhere(
        (u) =>
            u['username'] == username &&
            u['password'] == password &&
            u['isActive'] == true,
        orElse: () => null,
      );

      return user != null;
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  // ✅ FIXED: SignUp now creates user in ACTUAL database
  static Future<bool> signUp(String username, String password) async {
    try {
      // Check if username already exists in database
      final existsResponse = await http.get(Uri.parse('$baseUrl/Users'));

      if (existsResponse.statusCode == 200) {
        final List<dynamic> users = jsonDecode(existsResponse.body);
        final userExists = users.any((u) => u['username'] == username);

        if (userExists) {
          throw Exception('Username already exists');
        }
      }

      // Create user in the actual database
      final createResponse = await http.post(
        Uri.parse('$baseUrl/Users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (createResponse.statusCode != 200) {
        throw Exception('Failed to create user in database');
      }

      print('✅ User "$username" created in database');
      return true;
    } catch (e) {
      print('❌ Signup error: $e');
      throw Exception('Signup failed: $e');
    }
  }

  // ✅ FIXED: Check username in actual database
  static Future<bool> checkUsernameExists(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Users'));

      if (response.statusCode != 200) {
        return false;
      }

      final List<dynamic> users = jsonDecode(response.body);
      return users.any((u) => u['username'] == username);
    } catch (e) {
      print('❌ Error checking username: $e');
      throw Exception('Failed to check username: $e');
    }
  }
}

// User Stats Model
class UserStats {
  int totalGames;
  int queuedGames;
  int clearedGames;
  int reviewedGames;

  UserStats({
    this.totalGames = 0,
    this.queuedGames = 0,
    this.clearedGames = 0,
    this.reviewedGames = 0,
  });
}

// ============================================
// FIXED USER STATS STORAGE - WITH PROPER ISOLATION
// ============================================
class UserStatsStorage {
  static final Map<String, UserStats> _userStats = {};

  // ✅ FIXED: Always fetch fresh data, clear cache first
  static Future<UserStats> getUserStats(String username) async {
    print('📊 Fetching stats for: $username');

    // Clear old cache to prevent data mixing
    _userStats.remove(username);

    // Fetch fresh from backend
    final stats = await ApiService.fetchUserStats(username);
    _userStats[username] = stats;

    print(
      '✅ Stats loaded: Total=${stats.totalGames}, Queued=${stats.queuedGames}, Cleared=${stats.clearedGames}',
    );
    return stats;
  }

  // ✅ FIXED: Force refresh from backend
  static Future<void> refreshStats(String username) async {
    print('🔄 Refreshing stats for: $username');
    _userStats.remove(username); // Clear cache
    await getUserStats(username); // Fetch fresh
  }

  // ✅ ADDED: Clear all caches on logout
  static void clearAllCaches() {
    _userStats.clear();
    print('🗑️ All stat caches cleared');
  }
}

// Auth Screen (Login/Signup)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3a3a3a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFd4a574), width: 2),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFd4a574),
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isLoading =
                      false; // Reset loading state when dialog is dismissed
                });
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF5a9a9a),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3a3a3a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF5a9a9a), width: 2),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5a9a9a),
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (!isLogin) {
                  setState(() {
                    isLogin = true;
                    isLoading = false; // Reset loading state
                    // Clear all fields when switching to login
                    usernameController.clear();
                    passwordController.clear();
                    confirmPasswordController.clear();
                    showPassword = false;
                    showConfirmPassword = false;
                  });
                }
              },
              child: Text(
                isLogin ? 'OK' : 'Login Now',
                style: const TextStyle(
                  color: Color(0xFF5a9a9a),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // UPDATED AUTH SCREEN - CLEAR CACHES ON LOGIN/LOGOUT
  // ============================================

  // In your handleAuth() method, update the login success section:
  Future<void> handleAuth() async {
    if (isLoading) return;

    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      showErrorDialog(
        '⚠️ Empty Fields',
        'Please enter both username and password.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isLogin) {
        // LOGIN LOGIC
        final isValid = await AuthService.login(username, password);

        if (!isValid) {
          final userExists = await AuthService.checkUsernameExists(username);

          if (!userExists) {
            showErrorDialog(
              '❌ Account Not Found',
              'This account doesn\'t exist yet. Please sign up first!',
            );
          } else {
            showErrorDialog(
              '❌ Incorrect Password',
              'The password you entered is incorrect. Please try again.',
            );
          }
          return;
        }

        // ✅ FIXED: Clear ALL caches before loading new user data
        UserStatsStorage.clearAllCaches();
        AchievementStorage.clearAllCaches();

        setState(() {
          isLoading = false;
        });

        // ✅ FIXED: Fetch fresh stats from backend AFTER clearing caches
        print('👤 Logging in user: $username');
        await UserStatsStorage.getUserStats(username);
        await AchievementStorage.getUserAchievements(username);

        // Navigate to main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(username: username),
          ),
        );
      } else {
        // SIGNUP LOGIC
        if (username.length < 3) {
          showErrorDialog(
            '⚠️ Invalid Username',
            'Username must be at least 3 characters long.',
          );
          return;
        }

        if (password.length < 6) {
          showErrorDialog(
            '⚠️ Weak Password',
            'Password must be at least 6 characters long.',
          );
          return;
        }

        final confirmPassword = confirmPasswordController.text;

        if (confirmPassword.isEmpty) {
          showErrorDialog(
            '⚠️ Confirm Password',
            'Please confirm your password.',
          );
          return;
        }

        if (password != confirmPassword) {
          showErrorDialog(
            '⚠️ Passwords Don\'t Match',
            'The passwords you entered don\'t match. Please try again.',
          );
          return;
        }

        // ✅ FIXED: Create user in actual database
        final isCreated = await AuthService.signUp(username, password);

        if (!isCreated) {
          showErrorDialog(
            '❌ Signup Failed',
            'Unable to create account. Please try again later.',
          );
          return;
        }

        setState(() {
          isLoading = false;
        });

        showSuccessDialog(
          '✅ Success!',
          'Your account has been created successfully! Please login with your credentials.',
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showErrorDialog(
        '❌ Error',
        'An error occurred: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2a2a2a),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 96,
                  height: 96,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    //color: const Color(0xFF3a3a3a),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🎮', style: TextStyle(fontSize: 55)),
                  ),
                ),
                Text(
                  'Playlisted',
                  style: ArcadeFontStyle.getStyle(
                    fontSize: 32,
                    color: const Color(0xFFd4a574),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track Your Quests',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 40),

                // Tab Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTabButton('LOGIN', isLogin, () {
                      if (!isLogin) {
                        setState(() {
                          isLogin = true;
                          confirmPasswordController.clear();
                          showConfirmPassword = false;
                        });
                      }
                    }),
                    const SizedBox(width: 16),
                    _buildTabButton('SIGN UP', !isLogin, () {
                      if (isLogin) {
                        setState(() {
                          isLogin = false;
                        });
                      }
                    }),
                  ],
                ),
                const SizedBox(height: 32),

                // Form Fields
                _buildTextField('Username', usernameController, false, null),
                const SizedBox(height: 24),
                _buildTextField(
                  'Password',
                  passwordController,
                  !showPassword,
                  () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
                if (!isLogin) ...[
                  const SizedBox(height: 24),
                  _buildTextField(
                    'Confirm Password',
                    confirmPasswordController,
                    !showConfirmPassword,
                    () {
                      setState(() {
                        showConfirmPassword = !showConfirmPassword;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 40),

                // Start Button with loading indicator
                isLoading
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5a9a9a),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: handleAuth,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFe89a8a), Color(0xFFd87a6a)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFFb85a4a),
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isLogin ? 'Login' : 'Sign Up',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5a9a9a) : const Color(0xFF3a3a3a),
          border: Border.all(
            color: isActive ? const Color(0xFF4a8a8a) : const Color(0xFF4a4a4a),
            width: 4,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isPassword,
    VoidCallback? onToggleVisibility,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFd4a574),
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2a2a2a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5a9a9a), width: 4),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5a9a9a), width: 4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6abaaa), width: 4),
            ),
            suffixIcon: onToggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      isPassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF5a9a9a),
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// Achievement Model
class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final String italicDescription;
  bool isUnlocked;

  Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.italicDescription,
    this.isUnlocked = false,
  });
}

// ============================================
// FIXED ACHIEVEMENT STORAGE - WITH PROPER ISOLATION
// ============================================
class AchievementStorage {
  static final Map<String, List<Achievement>> _cache = {};

  // ✅ FIXED: Always fetch fresh data
  static Future<List<Achievement>> getUserAchievements(String username) async {
    print('🏆 Fetching achievements for: $username');

    // Clear old cache to prevent data mixing
    _cache.remove(username);

    // Fetch fresh from backend
    final achievements = await ApiService.fetchUserAchievements(username);
    _cache[username] = achievements;

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    print(
      '✅ Achievements loaded: $unlockedCount/${achievements.length} unlocked',
    );

    return achievements;
  }

  static int getUnlockedCount(String username) {
    if (!_cache.containsKey(username)) return 0;
    return _cache[username]!.where((a) => a.isUnlocked).length;
  }

  // ✅ FIXED: Refresh from backend
  static Future<void> refreshAchievements(String username) async {
    print('🔄 Refreshing achievements for: $username');
    _cache.remove(username); // Clear cache
    await getUserAchievements(username); // Fetch fresh
  }

  // ✅ ADDED: Clear all caches on logout
  static void clearAllCaches() {
    _cache.clear();
    print('🗑️ All achievement caches cleared');
  }
}

// Main Screen with Bottom Navigation
class MainScreen extends StatefulWidget {
  final String username;
  const MainScreen({super.key, required this.username});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// Update the MainScreen build method to pass username to CollectionScreen
// Update the MainScreen build method
class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  List<GameReview> reviews = [
    GameReview('Danganronpa', 2010, 5, 'cleared', 'Amazing mystery game!'),
    GameReview('Fear & Hunger', 2018, 4, 'reviewed', 'Dark and challenging.'),
    GameReview('Hades', 2020, 5, 'cleared', 'Perfect roguelike!'),
  ];

  final GlobalKey<_CollectionScreenState> _collectionKey = GlobalKey();

  // Add this function
  void navigateToTab(int tabIndex) {
    setState(() {
      currentIndex = tabIndex;
    });
    if (tabIndex == 3 && _collectionKey.currentState != null) {
      _collectionKey.currentState!._loadUserGames();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(username: widget.username, reviews: reviews),
      FeatsScreen(username: widget.username),
      AddReviewScreen(
        onAdd: addReview,
        username: widget.username,
        navigateToTab: navigateToTab, // Pass the function
      ),
      CollectionScreen(key: _collectionKey, username: widget.username),
      ProfileScreen(
        username: widget.username,
        onLogout: () {
          UserStatsStorage.clearAllCaches();
          AchievementStorage.clearAllCaches();
          print('🚪 User logged out, all caches cleared');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF3a3a3a),
          border: Border(top: BorderSide(color: Color(0xFF2a2a2a), width: 4)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() => currentIndex = index);
            if (index == 3 && _collectionKey.currentState != null) {
              _collectionKey.currentState!._loadUserGames();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF3a3a3a),
          selectedItemColor: const Color(0xFFd4a574),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events),
              label: 'Feats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 40),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Collection',
            ),
            BottomNavigationBarItem(
              // ✅ CHANGED: Settings to Profile
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void addReview(GameReview review) {
    setState(() {
      reviews.insert(0, review);
    });
  }
}

// Home Screen
class HomeScreen extends StatefulWidget {
  final String username;
  final List<GameReview> reviews;
  const HomeScreen({super.key, required this.username, required this.reviews});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ApiGame> allGames = [];
  List<ApiGame> displayedGames = [];
  List<ApiGame> queuedGames = [];
  bool showingAll = false;
  bool isLoading = true;
  UserStats _userStats = UserStats(); // Initialize with empty stats

  // ADD THESE VARIABLES FOR ROULETTE
  ApiGame? _selectedRouletteGame;
  final Random _random = Random();
  bool _isSpinning = false;

  // Add this method for spinning the roulette
  void _spinRoulette() async {
    if (queuedGames.isEmpty || _isSpinning) {
      print(
        '❌ Cannot spin: ${queuedGames.isEmpty ? 'No queued games' : 'Already spinning'}',
      );

      // Show centered notification
      if (queuedGames.isEmpty) {
        NotificationService.showErrorNotification(
          context: context,
          message: 'Add games with "Queued" status first!',
        );
      }

      return;
    }

    setState(() {
      _isSpinning = true;
      _selectedRouletteGame = null;
    });

    // Show "Selecting from queue..." message
    NotificationService.showCenteredNotification(
      context: context,
      message: '🎲 Selecting from queue...',
      backgroundColor: const Color(0xFFd4a574),
    );

    // Simulate spinning animation
    await Future.delayed(const Duration(milliseconds: 1500));

    // ✅ Select from REAL queued games
    final randomIndex = _random.nextInt(queuedGames.length);
    final selectedGame = queuedGames[randomIndex];

    print('🎯 Selected game: ${selectedGame.title}');

    setState(() {
      _selectedRouletteGame = selectedGame;
      _isSpinning = false;
    });

    // Show centered notification
    NotificationService.showSuccessNotification(
      context: context,
      message: '🎯 Quest selected: ${selectedGame.title}',
    );
  }

  String _getRandomGenre() {
    final genres = [
      'RPG',
      'Action',
      'Adventure',
      'Strategy',
      'Indie',
      'Simulation',
      'Horror',
      'Platformer',
      'Puzzle',
      'Sports',
    ];
    return genres[_random.nextInt(genres.length)];
  }

  // Add this method to clear roulette selection
  void _clearRouletteSelection() {
    setState(() {
      _selectedRouletteGame = null;
    });
  }

  // Update initState to clear roulette on rebuild
  //Proper initialization order
  @override
  void initState() {
    super.initState();
    _selectedRouletteGame = null; // Clear previous selection
    _initializeScreen(); // Load data in correct order
  }

  //Initialize screen with proper async loading order
  Future<void> _initializeScreen() async {
    try {
      await _loadGames();
      await _loadUserStats();
    } catch (e) {
      print('❌ Initialization failed: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  //Load user's actual queued games from backend
  //Load user's actual queued games from backend
  Future<void> _loadUserQueuedGames() async {
    try {
      final userId = await ApiService.getUserId(widget.username);
      print('🎯 Loading queued games for user ID: $userId');

      // Fetch user's games from backend
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/UserGames?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> userGamesData = jsonDecode(response.body);

        // Filter only queued games
        final queuedGameIds = userGamesData
            .where((g) => g['status'] == 'queued')
            .map((g) => g['gameId'] as int)
            .toList();

        print(
          '📋 Found ${queuedGameIds.length} queued game IDs: $queuedGameIds',
        );

        // Fetch all games to get details
        final allGames = await ApiService.fetchAllGames();

        // Match queued game IDs with full game data
        final loadedQueuedGames = allGames
            .where((game) => queuedGameIds.contains(game.id))
            .toList();

        // ✅ FIXED: Check mounted before setState
        if (mounted) {
          setState(() {
            queuedGames = loadedQueuedGames;
          });

          print('✅ Loaded ${queuedGames.length} queued games');
          queuedGames.forEach((game) {
            print('   - ${game.title}');
          });
        }
      } else {
        throw Exception('Failed to load user games: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading queued games: $e');

      // ✅ FIXED: Check mounted before setState
      if (mounted) {
        setState(() {
          queuedGames = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange,
            content: Text('⚠️ Could not load queued games'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadUserQueuedGames,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadUserStats() async {
    final stats = await UserStatsStorage.getUserStats(widget.username);
    setState(() {
      _userStats = stats;
    });

    // ✅ FIXED: Load queued games after stats are loaded
    await _loadUserQueuedGames();
  }

  Future<void> _loadGames() async {
    try {
      final games = await ApiService.fetchAllGames();
      setState(() {
        allGames = games;
        displayedGames = allGames.take(3).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleShowAll() async {
    if (showingAll) {
      setState(() {
        showingAll = false;
        displayedGames = allGames.take(3).toList();
      });
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AllGamesScreen(games: allGames, username: widget.username),
        ),
      );
      // ✅ FIXED: Refresh queued games when returning
      if (mounted) {
        await _loadGames();
        await _loadUserStats();
        await _loadUserQueuedGames();
      }
    }
  }

  void navigateToGameDetail(ApiGame game) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ApiGameDetailScreen(game: game, username: widget.username),
      ),
    );
    // ✅ FIXED: Refresh queued games when returning
    if (mounted) {
      await _loadGames();
      await _loadUserStats();
      await _loadUserQueuedGames();
    }
  }

  // Add this method to show spinning state
  Widget _buildSpinButton() {
    if (_isSpinning) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF5a9a9a).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Spinning...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _spinRoulette,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFe89a8a), Color(0xFFd87a6a)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFb85a4a).withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.casino, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Spin the Wheel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe5ddd5),
      body: SafeArea(
        child: Column(
          children: [
            // Header - Fixed
            Container(
              color: const Color(0xFF3a3a3a),
              padding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 20,
              ),
              child: Center(
                child: Text(
                  'Playlisted',
                  style: ArcadeFontStyle.getStyle(
                    fontSize: 20,
                    color: const Color(0xFFd4a574),
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkpoint Card (Mobile compatible)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(0),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF5a9a9a), Color(0xFF3a7a7a)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2a2a2a).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  //color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '🎮',
                                  style: TextStyle(fontSize: 30),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'CHECKPOINT REACHED',
                                style: TextStyle(
                                  fontSize: 20, // Reduced for mobile
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFd4a574),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Text(
                            '${_userStats.totalGames} games and counting.',
                            style: const TextStyle(
                              fontSize: 24, // Reduced for mobile
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _caption,
                                  style: const TextStyle(
                                    fontSize: 14, // Reduced for mobile
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats - Mobile Responsive
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            _userStats.queuedGames.toString(),
                            'Queued',
                            Icons.schedule,
                            Colors.purple,
                            isMobile: MediaQuery.of(context).size.width < 600,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width < 600
                              ? 8
                              : 12,
                        ),
                        Expanded(
                          child: _buildStatCard(
                            _userStats.clearedGames.toString(),
                            'Cleared',
                            Icons.check_circle,
                            const Color(0xFF5a9a9a),
                            isMobile: MediaQuery.of(context).size.width < 600,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width < 600
                              ? 8
                              : 12,
                        ),
                        Expanded(
                          child: _buildStatCard(
                            _userStats.reviewedGames.toString(),
                            'Reviewed',
                            Icons.rate_review,
                            Colors.red,
                            isMobile: MediaQuery.of(context).size.width < 600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Game Catalog (keep existing code)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.videogame_asset, color: Colors.black54),
                            SizedBox(width: 8),
                            Text(
                              'Game Catalog',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: toggleShowAll,
                          child: const Row(
                            children: [
                              Text(
                                'See All',
                                style: TextStyle(
                                  color: Color(0xFF5a9a9a),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                color: Color(0xFF5a9a9a),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Game Catalog Grid (mobile compatible)
                    isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5a9a9a),
                            ),
                          )
                        : SizedBox(
                            height: MediaQuery.of(context).size.height * 0.35,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: displayedGames.length,
                              itemBuilder: (context, index) {
                                final game = displayedGames[index];
                                final cardWidth =
                                    MediaQuery.of(context).size.width *
                                    0.45; // 45% of screen width

                                return GestureDetector(
                                  onTap: () => navigateToGameDetail(game),
                                  child: Container(
                                    width: cardWidth,
                                    margin: const EdgeInsets.only(
                                      right: 12,
                                    ), // REDUCED from 16 to 12
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height:
                                              cardWidth *
                                              1.2, // Consistent aspect ratio
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: game.imageUrl != null
                                                ? Image.asset(
                                                    game.imageUrl!,
                                                    fit: BoxFit
                                                        .cover, // Ensures consistent image fitting
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  )
                                                : Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                                colors: [
                                                                  Color(
                                                                    0xFF666666,
                                                                  ),
                                                                  Color(
                                                                    0xFF333333,
                                                                  ),
                                                                ],
                                                              ),
                                                        ),
                                                    child: Center(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8.0,
                                                            ),
                                                        child: Text(
                                                          game.title,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Flexible(
                                          child: Text(
                                            game.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${game.releaseYear}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                    // ✅ QUEST SELECT SECTION - FIXED TO USE REAL DATA
                    const SizedBox(height: 32),

                    const Row(
                      children: [
                        Icon(Icons.casino, color: Colors.black54),
                        SizedBox(width: 8),
                        Text(
                          'Quest Select',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1a1a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF3a3a3a),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Not sure what\'s next? Roll the dice and let fate decide.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Selected Game Display or Empty State
                          if (_selectedRouletteGame != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2a2a2a),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF5a9a9a),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'YOUR NEXT QUEST',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5a9a9a),
                                      letterSpacing: 2.0,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedRouletteGame!.title,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'monospace',
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF5a9a9a,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF5a9a9a),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _getRandomGenre(),
                                          style: const TextStyle(
                                            color: Color(0xFF5a9a9a),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFd4a574,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFd4a574),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${_selectedRouletteGame!.releaseYear}',
                                          style: const TextStyle(
                                            color: Color(0xFFd4a574),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else if (queuedGames.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2a2a2a),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF3a3a3a),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.question_mark,
                                    color: Color(0xFF5a9a9a),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No quest selected',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap "Roll for New Quest" to begin',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2a2a2a),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF3a3a3a),
                                  width: 1,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.videogame_asset_outlined,
                                    color: Color(0xFF5a9a9a),
                                    size: 48,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Your quest log is empty',
                                    style: TextStyle(
                                      color: Color(0xFF5a9a9a),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add games with "Queued" status to your collection first',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),

                          Container(height: 1, color: const Color(0xFF3a3a3a)),
                          const SizedBox(height: 20),

                          // Roll Button
                          Column(
                            children: [
                              if (_isSpinning)
                                Column(
                                  children: [
                                    const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFd4a574),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Selecting from queue...', // This is already centered
                                      style: TextStyle(
                                        color: Color(0xFFd4a574),
                                        fontFamily: 'monospace',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                GestureDetector(
                                  onTap: queuedGames.isNotEmpty
                                      ? _spinRoulette
                                      : null,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: queuedGames.isNotEmpty
                                          ? const Color(0xFF5a9a9a)
                                          : const Color(0xFF3a3a3a),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: queuedGames.isNotEmpty
                                            ? const Color(0xFF4a8a8a)
                                            : const Color(0xFF4a4a4a),
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center, // Already centered
                                        children: [
                                          Icon(
                                            Icons.casino,
                                            color: queuedGames.isNotEmpty
                                                ? Colors.white
                                                : Colors.grey,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Roll for New Quest',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: queuedGames.isNotEmpty
                                                  ? Colors.white
                                                  : Colors.grey,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Center(
                                // Wrap this text in Center widget
                                child: Text(
                                  queuedGames.isNotEmpty
                                      ? 'Selecting from ${queuedGames.length} queued games'
                                      : 'Add games with "Queued" status to enable Quest Select',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update the _buildStatCard method:
  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color, {
    bool isMobile = false, // ADD THIS OPTIONAL PARAMETER
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16), // UPDATE THIS
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12), // UPDATE THIS
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: isMobile ? 6 : 8, // UPDATE THIS
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8), // UPDATE THIS
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: isMobile ? 20 : 24,
            ), // UPDATE THIS
          ),
          SizedBox(height: isMobile ? 8 : 12), // UPDATE THIS
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 22 : 28, // UPDATE THIS
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isMobile ? 2 : 4), // UPDATE THIS
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12, // UPDATE THIS
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String get _caption {
    final total = _userStats.totalGames;
    if (total == 0) return 'Start your gaming journey!';
    if (total < 5) return 'Beginning your collection!';
    if (total < 10) return 'Growing your library!';
    if (total < 25) return 'Building your legacy!';
    if (total < 50) return 'Becoming a true gamer!';
    if (total < 100) return 'Legendary collection!';
    return 'Ultimate gaming mastery!';
  }

  // Helper methods kept for future use or other parts of the app
  Color _getStatusColor(String status) {
    switch (status) {
      case 'queued':
        return Colors.purple;
      case 'cleared':
        return const Color(0xFF5a9a9a);
      case 'reviewed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'queued':
        return Icons.schedule;
      case 'cleared':
        return Icons.check_circle;
      case 'reviewed':
        return Icons.rate_review;
      default:
        return Icons.question_mark;
    }
  }
}

// All Games Screen
class AllGamesScreen extends StatefulWidget {
  final List<ApiGame> games;
  final String username; // Add username

  const AllGamesScreen({
    super.key,
    required this.games,
    required this.username,
  });

  @override
  State<AllGamesScreen> createState() => _AllGamesScreenState();
}

class _AllGamesScreenState extends State<AllGamesScreen> {
  // Track hover state for each game
  final Map<int, bool> _hoverStates = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe5ddd5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3a3a3a),
        title: const Text(
          'All Games',
          style: TextStyle(
            color: Color(0xFFd4a574),
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: widget.games.length,
        itemBuilder: (context, index) {
          final game = widget.games[index];
          final isHovered = _hoverStates[game.id] ?? false;

          return MouseRegion(
            onEnter: (_) => setState(() => _hoverStates[game.id] = true),
            onExit: (_) => setState(() => _hoverStates[game.id] = false),
            child: GestureDetector(
              onTap: () async {
                // ✅ FIXED: Pass username properly
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApiGameDetailScreen(
                      game: game,
                      username: widget.username, // ✅ FIXED: Use widget.username
                    ),
                  ),
                );
                // Refresh parent when returning
                if (mounted) {
                  setState(() {});
                }
              },

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()..scale(isHovered ? 1.05 : 1.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isHovered ? 0.4 : 0.2),
                      blurRadius: isHovered ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                    if (isHovered)
                      BoxShadow(
                        color: const Color(0xFF5a9a9a).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Game Image
                      Positioned.fill(
                        child: game.imageUrl != null
                            ? Image.asset(
                                game.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF2a2a2a),
                                      Color(0xFF1a1a1a),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    game.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                      ),

                      // Overlay gradient for better text visibility
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Game Title and Year
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isHovered
                                ? const Color(0xFF5a9a9a).withOpacity(0.9)
                                : const Color(0xFF3a3a3a).withOpacity(0.9),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${game.releaseYear}',
                                style: TextStyle(
                                  color: isHovered
                                      ? Colors.white
                                      : const Color(0xFFd4a574),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Hover overlay
                      if (isHovered)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF5a9a9a).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// API Game Detail Screen
// Replace the current ApiGameDetailScreen with this stateful version
class ApiGameDetailScreen extends StatefulWidget {
  final ApiGame game;
  final String username; // Add username parameter

  const ApiGameDetailScreen({
    super.key,
    required this.game,
    required this.username, // Add this parameter
  });

  @override
  State<ApiGameDetailScreen> createState() => _ApiGameDetailScreenState();
}

class _ApiGameDetailScreenState extends State<ApiGameDetailScreen> {
  String? currentStatus; // Track current collection status
  bool isLoading = false;

  // Mock ratings data
  Map<String, int> get _mockRatings {
    final random = Random(widget.game.id);
    return {
      '5': random.nextInt(100) + 50,
      '4': random.nextInt(80) + 30,
      '3': random.nextInt(60) + 20,
      '2': random.nextInt(40) + 10,
      '1': random.nextInt(20) + 5,
    };
  }

  double get _averageRating {
    final ratings = _mockRatings;
    int totalRatings = 0;
    int totalScore = 0;
    ratings.forEach((star, count) {
      int starValue = int.parse(star);
      totalRatings += count;
      totalScore += starValue * count;
    });
    return totalRatings > 0 ? totalScore / totalRatings : 0.0;
  }

  int get _totalRatings {
    return _mockRatings.values.fold(0, (sum, count) => sum + count);
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    try {
      final userId = await ApiService.getUserId(widget.username);

      // Fetch user's games to check if this game is already in collection
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/UserGames?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> userGames = jsonDecode(response.body);

        final gameInCollection = userGames.firstWhere(
          (userGame) => userGame['gameId'] == widget.game.id,
          orElse: () => null,
        );

        if (gameInCollection != null) {
          setState(() {
            currentStatus = gameInCollection['status'];
          });
        }
      }
    } catch (e) {
      print('Error loading current status: $e');
    }
  }

  Future<void> _addToCollection(String status) async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = await ApiService.getUserId(widget.username);

      // Check if game already exists in user's collection
      final checkResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/UserGames?userId=$userId'),
      );

      if (checkResponse.statusCode == 200) {
        final List<dynamic> userGames = jsonDecode(checkResponse.body);

        final gameExists = userGames.any(
          (userGame) => userGame['gameId'] == widget.game.id,
        );

        if (gameExists) {
          // Update existing game status
          await http.put(
            Uri.parse('${ApiService.baseUrl}/UserGames'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'gameId': widget.game.id,
              'status': status.toLowerCase(),
            }),
          );

          // Show centered notification
          NotificationService.showSuccessNotification(
            context: context,
            message: '✅ Status updated to ${status.toLowerCase()}',
          );
        } else {
          // Add new game to collection
          await http.post(
            Uri.parse('${ApiService.baseUrl}/UserGames'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'gameId': widget.game.id,
              'status': status.toLowerCase(),
            }),
          );

          // Show centered notification
          NotificationService.showSuccessNotification(
            context: context,
            message: '✅ Added to collection as ${status.toLowerCase()}',
          );
        }

        setState(() {
          currentStatus = status.toLowerCase();
          isLoading = false;
        });

        // ✅ FIXED: Pop back to previous screen to trigger refresh
        Navigator.pop(context);

        // Refresh user stats
        await UserStatsStorage.refreshStats(widget.username);
      }
    } catch (e) {
      print('❌ Error adding to collection: $e');

      setState(() {
        isLoading = false;
      });

      // Show centered error notification
      NotificationService.showErrorNotification(
        context: context,
        message: '❌ Error: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void _showAddToCollectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          title: const Text(
            'Add to Collection',
            style: TextStyle(
              color: Color(0xFFd4a574),
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption(
                'Queued',
                'Want to play',
                Icons.schedule,
                Colors.purple,
              ),
              _buildStatusOption(
                'Playing',
                'Currently playing',
                Icons.play_arrow,
                Colors.blue,
              ),
              _buildStatusOption(
                'Paused',
                'Temporarily stopped',
                Icons.pause,
                Colors.orange,
              ),
              _buildStatusOption(
                'Dropped',
                'Abandoned',
                Icons.stop,
                Colors.grey,
              ),
              _buildStatusOption(
                'Cleared',
                'Finished',
                Icons.check_circle,
                Color(0xFF5a9a9a),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(
    String status,
    String description,
    IconData icon,
    Color color,
  ) {
    // Define muted colors for each status
    final mutedColors = {
      'Queued': const Color(0xFF9370DB), // Muted Purple
      'Playing': const Color(0xFF6495ED), // Muted Blue
      'Paused': const Color(0xFFFFB347), // Muted Orange
      'Dropped': const Color(0xFFA9A9A9), // Muted Grey
      'Cleared': const Color(0xFF6AB9AA), // Muted Teal (slightly lighter)
    };

    final mutedColor = mutedColors[status] ?? color;

    return ListTile(
      onTap: () {
        Navigator.pop(context);
        _addToCollection(status.toLowerCase());
      },
      leading: Icon(icon, color: mutedColor),
      title: Text(
        status,
        style: TextStyle(
          color: mutedColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratings = _mockRatings;
    final totalRatings = _totalRatings;
    final averageRating = _averageRating;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image
              Stack(
                children: [
                  SizedBox(
                    height: 400,
                    width: double.infinity,
                    child: widget.game.imageUrl != null
                        ? Image.asset(widget.game.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFF2a2a2a),
                            child: Center(
                              child: Text(
                                widget.game.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.game.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Year
                    Text(
                      'Released: ${widget.game.releaseYear}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      widget.game.summary,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ADD TO COLLECTION BUTTON
                    if (isLoading)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5a9a9a).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Adding to collection...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (currentStatus != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(currentStatus!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getStatusIcon(currentStatus!),
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'In Collection: ${currentStatus!.toUpperCase()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _showAddToCollectionDialog,
                              child: const Text(
                                'Change',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _showAddToCollectionDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF5a9a9a), Color(0xFF3a7a7a)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5a9a9a).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Add to Collection',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Ratings Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ratings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFF5a9a9a),
                              size: 28,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              averageRating.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ... Rest of the ratings code remains the same
                    // Rating Bars
                    ...List.generate(5, (index) {
                      int star = 5 - index;
                      int count = ratings['$star'] ?? 0;
                      double percentage = totalRatings > 0
                          ? count / totalRatings
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Row(
                              children: List.generate(
                                star,
                                (i) => const Icon(
                                  Icons.star,
                                  color: Color(0xFF5a9a9a),
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2a2a2a),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percentage,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5a9a9a),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 40,
                              child: Text(
                                count.toString(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Rating Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2a2a2a),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rating Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Ratings:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                totalRatings.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Average:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                averageRating.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '5-star Ratio:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${((ratings['5'] ?? 0) / totalRatings * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Time Display
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getCurrentTime(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for status colors and icons
  Color _getStatusColor(String status) {
    switch (status) {
      case 'queued':
        return Colors.purple;
      case 'playing':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'dropped':
        return Colors.grey;
      case 'cleared':
        return const Color(0xFF5a9a9a);
      default:
        return const Color(0xFF5a9a9a);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'queued':
        return Icons.schedule;
      case 'playing':
        return Icons.play_arrow;
      case 'paused':
        return Icons.pause;
      case 'dropped':
        return Icons.stop;
      case 'cleared':
        return Icons.check_circle;
      default:
        return Icons.question_mark;
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12
        ? hour - 12
        : hour == 0
        ? 12
        : hour;
    return 'Last updated: ${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}

// Game Model for API Data
class ApiGame {
  final int id;
  final String title;
  final String summary;
  final int releaseYear;
  final bool isActive;
  final String? imageUrl; // We'll add this from local assets

  ApiGame({
    required this.id,
    required this.title,
    required this.summary,
    required this.releaseYear,
    required this.isActive,
    this.imageUrl,
  });

  factory ApiGame.fromJson(Map<String, dynamic> json) {
    return ApiGame(
      id: json['id'],
      title: json['title'],
      summary: json['summary'],
      releaseYear: json['releaseYear'],
      isActive: json['isActive'],
      imageUrl: _getImageUrl(json['title']), // Map title to local image
    );
  }

  static String? _getImageUrl(String title) {
    // Map game titles to local image asset paths
    final imageMap = {
      'Danganronpa: Trigger Happy Havoc': 'assets/games/danganronpa1.jpg',
      'Danganronpa 2: Goodbye Despair': 'assets/games/danganronpa2.jpg',
      'Danganronpa V3: Killing Harmony': 'assets/games/danganronpa3.jpg',
      'The Legend of Zelda: Breath of the Wild': 'assets/games/zelda_botw.jpg',
      'Elden Ring': 'assets/games/elden.jpg',
      'Dark Souls': 'assets/games/dark_souls.jpg',
      'Hades': 'assets/games/hades.jpg',
      'Celeste': 'assets/games/celeste.jpg',
      'Undertale': 'assets/games/undertale.jpg',
      'Stardew Valley': 'assets/games/stardew.png',
      'Persona 5 Royal': 'assets/games/persona5.jpg',
      'God of War': 'assets/games/gow.jpg',
      'Red Dead Redemption 2': 'assets/games/rdr2.jpg',
      'The Witcher 3: Wild Hunt': 'assets/games/witcher3.jpg',
      'Hollow Knight': 'assets/games/hollow.png',
      'Final Fantasy VII': 'assets/games/ff7.jpg',
      'Mass Effect 2': 'assets/games/mass2.png',
      'Disco Elysium': 'assets/games/disco.jpg',
      'Minecraft': 'assets/games/minecraft.jpg',
      'Portal 2': 'assets/games/portal2.jpg',
    };

    return imageMap[title];
  }
}

// API Service
class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  // ✅ NEW: Get User ID from username
  static Future<int> getUserId(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Users'));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch users');
      }

      final List<dynamic> users = jsonDecode(response.body);
      final user = users.firstWhere(
        (u) => u['username'] == username,
        orElse: () => throw Exception('User not found'),
      );

      return user['id'] as int;
    } catch (e) {
      throw Exception('Failed to get user ID: $e');
    }
  }

  // ✅ NEW: Fetch User Stats from Backend
  static Future<UserStats> fetchUserStats(String username) async {
    try {
      final userId = await getUserId(username);

      // Fetch user games
      final gamesResponse = await http.get(
        Uri.parse('$baseUrl/UserGames?userId=$userId'),
      );

      if (gamesResponse.statusCode != 200) {
        throw Exception('Failed to fetch user games');
      }

      final List<dynamic> userGames = jsonDecode(gamesResponse.body);

      // Fetch user reviews
      final reviewsResponse = await http.get(Uri.parse('$baseUrl/Reviews'));

      final List<dynamic> allReviews = reviewsResponse.statusCode == 200
          ? jsonDecode(reviewsResponse.body)
          : [];

      final userReviews = allReviews
          .where((r) => r['userId'] == userId)
          .toList();

      return UserStats(
        totalGames: userGames.length,
        queuedGames: userGames.where((g) => g['status'] == 'queued').length,
        clearedGames: userGames.where((g) => g['status'] == 'cleared').length,
        reviewedGames: userReviews.length,
      );
    } catch (e) {
      print('Error fetching user stats: $e');
      return UserStats(); // Return empty stats on error
    }
  }

  // ✅ NEW: Fetch User Achievements from Backend
  static Future<List<Achievement>> fetchUserAchievements(
    String username,
  ) async {
    try {
      final userId = await getUserId(username);

      // Fetch unlocked achievements
      final response = await http.get(
        Uri.parse('$baseUrl/UserAchievements?userId=$userId'),
      );

      Set<String> unlockedNames = {};
      if (response.statusCode == 200) {
        final List<dynamic> unlockedData = jsonDecode(response.body);
        unlockedNames = unlockedData.map((a) => a['name'] as String).toSet();
      }

      // Create full achievement list with unlock status
      final achievements = [
        Achievement(
          id: 'first_blood',
          emoji: '🩸',
          title: 'First Blood',
          description: 'Complete your first game',
          italicDescription: 'And so it begins…',
          isUnlocked: unlockedNames.contains('First Blood'),
        ),
        Achievement(
          id: 'praise_sun',
          emoji: '☀️',
          title: 'Praise the Sun',
          description: 'Write your first review',
          italicDescription: "You've shared your first blessing.",
          isUnlocked: unlockedNames.contains('Praise the Sun'),
        ),
        Achievement(
          id: 'stay_determined',
          emoji: '💪',
          title: 'Stay Determined',
          description: 'Complete 10 games',
          italicDescription: 'Your persistence paid off.',
          isUnlocked: unlockedNames.contains('Stay Determined'),
        ),
        Achievement(
          id: 'disappointment',
          emoji: '💀',
          title: 'The Ultimate Disappointment',
          description: 'Give a game 1 star',
          italicDescription: 'Such despair…',
          isUnlocked: unlockedNames.contains('The Ultimate Disappointment'),
        ),
        Achievement(
          id: 'actually_cooked',
          emoji: '👨‍🍳',
          title: 'They Actually Cooked',
          description: 'Give a game 5 stars',
          italicDescription: 'Absolute Perfection',
          isUnlocked: unlockedNames.contains('They Actually Cooked'),
        ),
      ];

      return achievements;
    } catch (e) {
      print('Error fetching achievements: $e');
      return _createDefaultAchievements(); // Return default locked achievements
    }
  }

  // Helper method for default achievements
  static List<Achievement> _createDefaultAchievements() {
    return [
      Achievement(
        id: 'first_blood',
        emoji: '🩸',
        title: 'First Blood',
        description: 'Complete your first game',
        italicDescription: 'And so it begins…',
        isUnlocked: false,
      ),
      Achievement(
        id: 'praise_sun',
        emoji: '☀️',
        title: 'Praise the Sun',
        description: 'Write your first review',
        italicDescription: "You've shared your first blessing.",
        isUnlocked: false,
      ),
      Achievement(
        id: 'stay_determined',
        emoji: '💪',
        title: 'Stay Determined',
        description: 'Complete 10 games',
        italicDescription: 'Your persistence paid off.',
        isUnlocked: false,
      ),
      Achievement(
        id: 'disappointment',
        emoji: '💀',
        title: 'The Ultimate Disappointment',
        description: 'Give a game 1 star',
        italicDescription: 'Such despair…',
        isUnlocked: false,
      ),
      Achievement(
        id: 'actually_cooked',
        emoji: '👨‍🍳',
        title: 'They Actually Cooked',
        description: 'Give a game 5 stars',
        italicDescription: 'Absolute Perfection',
        isUnlocked: false,
      ),
    ];
  }

  static Future<List<ApiGame>> fetchAllGames() async {
    // Simulating API call with your provided data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // In real implementation, you would use:
    // final response = await http.get(Uri.parse('$baseUrl/Games'));
    // final List<dynamic> jsonList = jsonDecode(response.body);
    // return jsonList.map((json) => ApiGame.fromJson(json)).toList();

    // For now, using your provided data:
    final jsonData = [
      {
        "id": 1,
        "title": "Danganronpa: Trigger Happy Havoc",
        "summary":
            "A group of elite students are trapped in a deadly killing game where murder is the only way to escape.",
        "releaseYear": 2010,
        "isActive": true,
      },
      {
        "id": 2,
        "title": "Danganronpa 2: Goodbye Despair",
        "summary":
            "Students are stranded on a tropical island where despair returns in an even deadlier killing game.",
        "releaseYear": 2012,
        "isActive": true,
      },
      {
        "id": 3,
        "title": "Danganronpa V3: Killing Harmony",
        "summary":
            "A new cast of students is thrust into a twisted killing game that challenges the meaning of truth and lies.",
        "releaseYear": 2017,
        "isActive": true,
      },
      {
        "id": 4,
        "title": "The Legend of Zelda: Breath of the Wild",
        "summary":
            "An open-world adventure where Link explores a vast land to defeat Calamity Ganon.",
        "releaseYear": 2017,
        "isActive": true,
      },
      {
        "id": 5,
        "title": "Elden Ring",
        "summary":
            "A vast open-world action RPG set in a dark fantasy universe created with George R. R. Martin.",
        "releaseYear": 2022,
        "isActive": true,
      },
      {
        "id": 6,
        "title": "Dark Souls",
        "summary":
            "A punishing action RPG known for its difficulty and cryptic storytelling.",
        "releaseYear": 2011,
        "isActive": true,
      },
      {
        "id": 7,
        "title": "Hades",
        "summary":
            "A rogue-like dungeon crawler where you defy the god of the dead.",
        "releaseYear": 2020,
        "isActive": true,
      },
      {
        "id": 8,
        "title": "Celeste",
        "summary":
            "A precision platformer about climbing a mountain and confronting inner struggles.",
        "releaseYear": 2018,
        "isActive": true,
      },
      {
        "id": 9,
        "title": "Undertale",
        "summary":
            "A unique RPG where players can choose non-violent solutions to conflict.",
        "releaseYear": 2015,
        "isActive": true,
      },
      {
        "id": 10,
        "title": "Stardew Valley",
        "summary":
            "A relaxing farming and life simulation game set in a small town.",
        "releaseYear": 2016,
        "isActive": true,
      },
      {
        "id": 11,
        "title": "Persona 5 Royal",
        "summary":
            "A stylish JRPG about phantom thieves changing corrupt hearts.",
        "releaseYear": 2020,
        "isActive": true,
      },
      {
        "id": 12,
        "title": "God of War",
        "summary":
            "A mythological action-adventure following Kratos and his son.",
        "releaseYear": 2018,
        "isActive": true,
      },
      {
        "id": 13,
        "title": "Red Dead Redemption 2",
        "summary": "An epic tale of life in America's unforgiving heartland.",
        "releaseYear": 2018,
        "isActive": true,
      },
      {
        "id": 14,
        "title": "The Witcher 3: Wild Hunt",
        "summary":
            "A story-driven RPG set in a visually stunning fantasy universe.",
        "releaseYear": 2015,
        "isActive": true,
      },
      {
        "id": 15,
        "title": "Hollow Knight",
        "summary":
            "A hand-drawn action-adventure set in a vast underground kingdom.",
        "releaseYear": 2017,
        "isActive": true,
      },
      {
        "id": 16,
        "title": "Final Fantasy VII",
        "summary": "A classic JRPG about eco-terrorism and identity.",
        "releaseYear": 1997,
        "isActive": true,
      },
      {
        "id": 17,
        "title": "Mass Effect 2",
        "summary":
            "A sci-fi RPG where your choices shape the fate of the galaxy.",
        "releaseYear": 2010,
        "isActive": true,
      },
      {
        "id": 18,
        "title": "Disco Elysium",
        "summary":
            "A narrative-driven RPG focused on dialogue, choice, and consequence.",
        "releaseYear": 2019,
        "isActive": true,
      },
      {
        "id": 19,
        "title": "Minecraft",
        "summary":
            "A sandbox game about creativity, survival, and exploration.",
        "releaseYear": 2011,
        "isActive": true,
      },
      {
        "id": 20,
        "title": "Portal 2",
        "summary": "A puzzle game with innovative mechanics and dark humor.",
        "releaseYear": 2011,
        "isActive": true,
      },
    ];

    return jsonData.map((json) => ApiGame.fromJson(json)).toList();
  }

  // Add this method to ApiService class
  static Future<List<Map<String, dynamic>>> getUserReviews(
    String username,
  ) async {
    try {
      final userId = await getUserId(username);

      // Fetch user reviews from backend
      final response = await http.get(Uri.parse('$baseUrl/Reviews'));

      if (response.statusCode == 200) {
        final List<dynamic> allReviews = jsonDecode(response.body);

        // Filter reviews for this user
        final userReviews = allReviews.where((review) {
          final dynamic userIdField = review['userId'];

          // Handle both int and string user IDs
          if (userIdField is int) {
            return userIdField == userId;
          } else if (userIdField is String) {
            return int.tryParse(userIdField) == userId;
          }
          return false;
        }).toList();

        // Convert to proper Map<String, dynamic>
        return userReviews.map((review) {
          final dynamic reviewUserIdField = review['userId'];
          final int reviewUserId;

          if (reviewUserIdField is int) {
            reviewUserId = reviewUserIdField;
          } else if (reviewUserIdField is String) {
            reviewUserId = int.tryParse(reviewUserIdField) ?? 0;
          } else {
            reviewUserId = 0;
          }

          return {
            'userId':
                reviewUserId, // ✅ Use the review's userId, not the local one
            'gameId': review['gameId'] is int
                ? review['gameId']
                : int.tryParse(review['gameId'].toString()) ?? 0,
            'rating': review['rating'] is double
                ? review['rating']
                : review['rating'] is int
                ? review['rating'].toDouble()
                : double.tryParse(review['rating'].toString()) ?? 0.0,
            'status': review['status'] as String? ?? 'cleared',
            'reviewText': review['reviewText'] as String?,
            'createdAt':
                review['createdAt'] as String? ??
                DateTime.now().toIso8601String(),
          };
        }).toList();
      }

      return [];
    } catch (e) {
      print('❌ Error fetching user reviews: $e');
      return [];
    }
  }
}

// Achievement API Service
class AchievementApiService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<List<Achievement>> fetchUserAchievements(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/UserAchievements?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Map API achievements to local Achievement model
        final Map<String, Achievement> achievementMap = {
          'first_blood': Achievement(
            id: 'first_blood',
            emoji: '🩸',
            title: 'First Blood',
            description: 'Complete your first game',
            italicDescription: 'And so it begins…',
            isUnlocked: false,
          ),
          'praise_sun': Achievement(
            id: 'praise_sun',
            emoji: '☀️',
            title: 'Praise the Sun',
            description: 'Write your first review',
            italicDescription: "You've shared your first blessing.",
            isUnlocked: false,
          ),
          'stay_determined': Achievement(
            id: 'stay_determined',
            emoji: '💪',
            title: 'Stay Determined',
            description: 'Complete 10 games',
            italicDescription: 'Your persistence paid off.',
            isUnlocked: false,
          ),
          'disappointment': Achievement(
            id: 'disappointment',
            emoji: '💀',
            title: 'The Ultimate Disappointment',
            description: 'Give a game 1 star',
            italicDescription: 'Such despair…',
            isUnlocked: false,
          ),
          'actually_cooked': Achievement(
            id: 'actually_cooked',
            emoji: '👨‍🍳',
            title: 'They Actually Cooked',
            description: 'Give a game 5 stars',
            italicDescription: 'Absolute Perfection',
            isUnlocked: false,
          ),
        };

        // Mark achievements as unlocked based on API response
        for (var item in data) {
          final achievementName = item['achievementName'] as String;
          final key = _mapAchievementNameToKey(achievementName);
          if (achievementMap.containsKey(key)) {
            achievementMap[key]!.isUnlocked = true;
          }
        }

        return achievementMap.values.toList();
      }

      return [];
    } catch (e) {
      print('Error fetching achievements: $e');
      return [];
    }
  }

  static String _mapAchievementNameToKey(String name) {
    switch (name) {
      case 'First Blood':
        return 'first_blood';
      case 'Praise the Sun':
        return 'praise_sun';
      case 'Stay Determined':
        return 'stay_determined';
      case 'The Ultimate Disappointment':
        return 'disappointment';
      case 'They Actually Cooked':
        return 'actually_cooked';
      default:
        return '';
    }
  }
}

// Game Model
class Game {
  final String name;
  final int year;
  final String imageUrl;
  final List<String> genres;
  final String description;
  final Map<String, int> ratings; // '5': count, '4': count, etc.

  Game({
    required this.name,
    required this.year,
    required this.imageUrl,
    required this.genres,
    required this.description,
    required this.ratings,
  });

  double get averageRating {
    int totalRatings = 0;
    int totalScore = 0;
    ratings.forEach((star, count) {
      int starValue = int.parse(star);
      totalRatings += count;
      totalScore += starValue * count;
    });
    return totalRatings > 0 ? totalScore / totalRatings : 0.0;
  }

  int get totalRatings {
    return ratings.values.fold(0, (sum, count) => sum + count);
  }
}

// Game Detail Screen
class GameDetailScreen extends StatelessWidget {
  final Game game;
  const GameDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image
              Stack(
                children: [
                  SizedBox(
                    height: 400,
                    width: double.infinity,
                    child: Image.network(
                      game.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF2a2a2a),
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 64,
                              color: Colors.white38,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Year and Genres
                    Text(
                      '${game.year} • ${game.genres.join(', ')}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      game.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Track, review button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2d5d4f),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.edit, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Track, review, and more',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Ratings Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ratings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFF5a9a9a),
                              size: 28,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              game.averageRating.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Rating Bars
                    ...List.generate(5, (index) {
                      int star = 5 - index;
                      int count = game.ratings['$star'] ?? 0;
                      int total = game.totalRatings;
                      double percentage = total > 0 ? count / total : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Row(
                              children: List.generate(
                                star,
                                (i) => const Icon(
                                  Icons.star,
                                  color: Color(0xFF5a9a9a),
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2a2a2a),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percentage,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5a9a9a),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 40,
                              child: Text(
                                count.toString(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Rating Stats
                    Row(
                      children: [
                        const Icon(
                          Icons.visibility,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(game.totalRatings * 3.5).toStringAsFixed(1)}K',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(game.totalRatings * 0.25).toStringAsFixed(1)}K',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.star_border,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(game.totalRatings * 2.8).toStringAsFixed(1)}K',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// UPDATED FEATS SCREEN - MOBILE COMPATIBLE
// ============================================
class FeatsScreen extends StatefulWidget {
  final String username;

  const FeatsScreen({super.key, required this.username});

  @override
  State<FeatsScreen> createState() => _FeatsScreenState();
}

class _FeatsScreenState extends State<FeatsScreen> {
  bool showUnlocked = true;
  List<Achievement> achievements = [];
  bool isLoading = true;
  List<Achievement> newlyUnlocked = [];

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final loadedAchievements = await AchievementStorage.getUserAchievements(
      widget.username,
    );

    // Check for newly unlocked achievements
    final List<Achievement> newlyUnlockedList = [];
    for (final achievement in loadedAchievements) {
      if (achievement.isUnlocked) {
        // Check if this achievement was previously locked
        final oldAchievement = achievements.firstWhere(
          (a) => a.id == achievement.id,
          orElse: () => achievement,
        );
        if (!oldAchievement.isUnlocked) {
          newlyUnlockedList.add(achievement);
        }
      }
    }

    setState(() {
      achievements = loadedAchievements;
      newlyUnlocked = newlyUnlockedList;
      isLoading = false;
    });

    // Show notifications for newly unlocked achievements
    if (newlyUnlocked.isNotEmpty && mounted) {
      for (final achievement in newlyUnlocked) {
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          await EnhancedNotificationService.showAchievementNotification(
            context: context,
            title: achievement.title,
            message: achievement.description,
            emoji: achievement.emoji,
            backgroundColor: const Color(0xFF5a9a9a),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFe5ddd5),
        body: SafeArea(
          child: Column(
            children: [
              // UPDATED HEADER - CENTERED LIKE OTHER SCREENS
              Container(
                color: const Color(0xFF3a3a3a),
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Center(
                  child: Text(
                    'Feats',
                    style: ArcadeFontStyle.getStyle(
                      fontSize: 20,
                      color: const Color(0xFFd4a574),
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF5a9a9a)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;

    final unlockedAchievements = achievements
        .where((a) => a.isUnlocked)
        .toList();
    final lockedAchievements = achievements
        .where((a) => !a.isUnlocked)
        .toList();

    final displayAchievements = showUnlocked
        ? unlockedAchievements
        : lockedAchievements;

    return Scaffold(
      backgroundColor: const Color(0xFFe5ddd5),
      body: SafeArea(
        child: Column(
          children: [
            // UPDATED HEADER - REMOVED PROFILE & SEARCH ICONS
            Container(
              color: const Color(0xFF3a3a3a),
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Center(
                child: Text(
                  'Feats',
                  style: ArcadeFontStyle.getStyle(
                    fontSize: 20,
                    color: const Color(0xFFd4a574),
                  ),
                ),
              ),
            ),

            // TRACKER CARD - MOBILE OPTIMIZED
            Container(
              margin: EdgeInsets.all(isMobile ? 12 : 16),
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5a9a9a), Color(0xFF3a7a7a)],
                ),
                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: isMobile ? 6 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 8 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            isMobile ? 8 : 12,
                          ),
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: isMobile ? 24 : 32,
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$unlockedCount/$totalCount',
                              style: TextStyle(
                                fontSize: isMobile ? 28 : 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'Achievements Unlocked',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Container(
                          height: isMobile ? 16 : 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: totalCount > 0
                              ? unlockedCount / totalCount
                              : 0,
                          child: Container(
                            height: isMobile ? 16 : 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFd4a574),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // TOGGLE BUTTONS - MOBILE FRIENDLY
            Container(
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: const Color(0xFF3a3a3a),
                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showUnlocked = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 16,
                        ),
                        decoration: BoxDecoration(
                          color: showUnlocked
                              ? const Color(0xFF5a9a9a)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            isMobile ? 8 : 12,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_open,
                              color: showUnlocked ? Colors.white : Colors.grey,
                              size: isMobile ? 18 : 20,
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'Unlocked',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: showUnlocked
                                    ? Colors.white
                                    : Colors.grey,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showUnlocked = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 16,
                        ),
                        decoration: BoxDecoration(
                          color: !showUnlocked
                              ? const Color(0xFF5a9a9a)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            isMobile ? 8 : 12,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              color: !showUnlocked ? Colors.white : Colors.grey,
                              size: isMobile ? 18 : 20,
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'Locked',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: !showUnlocked
                                    ? Colors.white
                                    : Colors.grey,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ACHIEVEMENTS LIST - MOBILE OPTIMIZED
            Expanded(
              child: _buildAchievementList(displayAchievements, isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementList(
    List<Achievement> displayAchievements,
    bool isMobile,
  ) {
    if (displayAchievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showUnlocked ? Icons.lock : Icons.lock_open,
              size: isMobile ? 48 : 64,
              color: Colors.grey,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              showUnlocked
                  ? 'No achievements unlocked yet'
                  : 'All achievements unlocked!',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              showUnlocked
                  ? 'Complete goals to unlock achievements'
                  : 'Amazing job! You\'ve completed everything',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 8,
      ),
      itemCount: displayAchievements.length,
      itemBuilder: (context, index) {
        final achievement = displayAchievements[index];
        return _buildAchievementCard(achievement, isMobile);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isMobile) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : const Color(0xFFd0d0d0),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(
          color: isUnlocked ? const Color(0xFF5a9a9a) : Colors.grey,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isMobile ? 3 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 50 : 60,
            height: isMobile ? 50 : 60,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF5a9a9a)
                  : Colors.grey.shade600,
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  color: isUnlocked ? Colors.white : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.black : Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: isUnlocked ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: isMobile ? 1 : 2),
                Text(
                  achievement.italicDescription,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    color: isUnlocked
                        ? const Color(0xFF5a9a9a)
                        : Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add Review Screen
class AddReviewScreen extends StatefulWidget {
  final Function(GameReview) onAdd;
  final String username;
  final Function(int)? navigateToTab;

  const AddReviewScreen({
    super.key,
    required this.onAdd,
    required this.username,
    this.navigateToTab,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  String? selectedGameTitle;
  int? selectedGameId;
  final yearController = TextEditingController();
  final reviewController = TextEditingController();
  int rating = 5;
  String status = 'queued';
  bool isLoading = false;
  bool isLoadingGames = true;
  List<Map<String, dynamic>> userGames = [];

  @override
  void initState() {
    super.initState();
    _loadUserGames();
  }

  Future<void> _loadUserGames() async {
    setState(() {
      isLoadingGames = true;
    });

    try {
      final userId = await ApiService.getUserId(widget.username);
      print('🔍 Loading games for user ID: $userId');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/UserGames?userId=$userId'),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> gamesData = jsonDecode(response.body);
        print('📚 Found ${gamesData.length} games in collection');

        final List<Map<String, dynamic>> loadedGames = [];

        // Fetch all games to get details
        final allGames = await ApiService.fetchAllGames();

        for (var userGame in gamesData) {
          final gameId = userGame['gameId'] as int?;
          final gameStatus = userGame['status'] as String? ?? 'queued';

          if (gameId == null) {
            print('⚠️ Skipping game with null gameId');
            continue;
          }

          try {
            final game = allGames.firstWhere((g) => g.id == gameId);

            loadedGames.add({
              'gameId': gameId,
              'title': game.title,
              'releaseYear': game.releaseYear,
              'status': gameStatus,
            });

            print('✅ Loaded: ${game.title} (Status: $gameStatus)');
          } catch (e) {
            print('⚠️ Game $gameId not found in catalog');
          }
        }

        setState(() {
          userGames = loadedGames;
          isLoadingGames = false;
        });

        print('✅ Successfully loaded ${loadedGames.length} games');
      } else {
        throw Exception('Failed to load games: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading user games: $e');
      setState(() {
        isLoadingGames = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Error loading games: ${e.toString()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2a2a2a),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            // In AddReviewScreen build method, update the header:
            Container(
              color: const Color(0xFF3a3a3a),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button if needed, or empty container
                  const SizedBox(width: 40), // Spacer for centering
                  Text(
                    'Add Review',
                    style: ArcadeFontStyle.getStyle(
                      fontSize: 16,
                      color: const Color(0xFFd4a574),
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Color(0xFF5a9a9a),
                      size: 24,
                    ),
                    onPressed: () {
                      _loadUserGames();
                      NotificationService.showCenteredNotification(
                        context: context,
                        message: 'Refreshing your games...',
                        backgroundColor: const Color(0xFF5a9a9a),
                        duration: const Duration(seconds: 1),
                      );
                    },
                  ),
                ],
              ),
            ),

            // LOADING STATE
            if (isLoadingGames)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF5a9a9a)),
                      SizedBox(height: 16),
                      Text(
                        'Loading your games...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GAME TITLE DROPDOWN
                      _buildLabel('Game Title *'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3a3a3a),
                          border: Border.all(
                            color: const Color(0xFF5a9a9a),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: userGames.isEmpty
                            ? GestureDetector(
                                onTap: () {
                                  if (widget.navigateToTab != null) {
                                    // Navigate to Home tab (index 0)
                                    widget.navigateToTab!(0);

                                    // Optional: Show a success message
                                    NotificationService.showSuccessNotification(
                                      context: context,
                                      message: 'Switched to Home tab',
                                    );
                                  } else {
                                    // Fallback
                                    NotificationService.showCenteredNotification(
                                      context: context,
                                      message: 'Go to Home tab to browse games',
                                      backgroundColor: const Color(0xFF5a9a9a),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF5a9a9a,
                                          ).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(
                                              0xFF5a9a9a,
                                            ).withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.videogame_asset_outlined,
                                          color: Color(0xFF5a9a9a),
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No games in collection',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to go to Home tab and add games',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF5a9a9a,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF5a9a9a),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.arrow_forward,
                                              color: Color(0xFF5a9a9a),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Go to Home Tab',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : DropdownButton<String>(
                                value: selectedGameTitle,
                                hint: const Text(
                                  'Select a game from your collection',
                                  style: TextStyle(color: Colors.white38),
                                ),
                                isExpanded: true,
                                dropdownColor: const Color(0xFF3a3a3a),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                underline: Container(),
                                items: userGames.map((game) {
                                  return DropdownMenuItem<String>(
                                    value: game['title'],
                                    child: Text(
                                      game['title'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedGameTitle = value;
                                    final game = userGames.firstWhere(
                                      (g) => g['title'] == value,
                                    );
                                    selectedGameId = game['gameId'];
                                    yearController.text = game['releaseYear']
                                        .toString();
                                    status = game['status'];
                                  });
                                },
                              ),
                      ),
                      const SizedBox(height: 16),

                      // YEAR (Auto-filled, read-only)
                      _buildLabel('Year'),
                      _buildTextField(yearController, '2024', isNumber: true),
                      const SizedBox(height: 16),

                      // RATING
                      _buildLabel('Rating: $rating/5'),
                      Slider(
                        value: rating.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        activeColor: const Color(0xFF5a9a9a),
                        onChanged: (value) {
                          setState(() => rating = value.toInt());
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          return Text(
                            index < rating ? '⭐' : '☆',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Color(0xFFd4a574),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // STATUS DROPDOWN
                      _buildLabel('Status'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3a3a3a),
                          border: Border.all(
                            color: const Color(0xFF5a9a9a),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: status,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF3a3a3a),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          underline: Container(),
                          items:
                              [
                                'queued',
                                'playing',
                                'paused',
                                'dropped',
                                'cleared',
                              ].map((s) {
                                final Color mutedColor;
                                switch (s) {
                                  case 'queued':
                                    mutedColor = const Color(0xFF9370DB);
                                    break;
                                  case 'playing':
                                    mutedColor = const Color(0xFF6495ED);
                                    break;
                                  case 'paused':
                                    mutedColor = const Color(0xFFFFB347);
                                    break;
                                  case 'dropped':
                                    mutedColor = const Color(0xFFA9A9A9);
                                    break;
                                  case 'cleared':
                                    mutedColor = const Color(0xFF6AB9AA);
                                    break;
                                  default:
                                    mutedColor = Colors.white;
                                }

                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s.toUpperCase(),
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() => status = value!);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // REVIEW TEXT (Optional)
                      _buildLabel('Review (Optional)'),
                      TextField(
                        controller: reviewController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF3a3a3a),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF5a9a9a),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF5a9a9a),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6abaaa),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SUBMIT BUTTON
                      GestureDetector(
                        onTap: isLoading || selectedGameId == null
                            ? null
                            : () async {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  final userId = await ApiService.getUserId(
                                    widget.username,
                                  );

                                  print('📝 Submitting review:');
                                  print('   User ID: $userId');
                                  print('   Game ID: $selectedGameId');
                                  print('   Rating: $rating');
                                  print('   Status: $status');

                                  // 1. Update game status in UserGames (Single Source of Truth)
                                  await http.put(
                                    Uri.parse(
                                      '${ApiService.baseUrl}/UserGames',
                                    ),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({
                                      'userId': userId,
                                      'gameId': selectedGameId,
                                      'status': status,
                                    }),
                                  );
                                  print('✅ Status updated in UserGames');

                                  // 2. Create/Update review
                                  await http.post(
                                    Uri.parse('${ApiService.baseUrl}/Reviews'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode({
                                      'userId': userId,
                                      'gameId': selectedGameId,
                                      'rating': rating.toDouble(),
                                      'status': status,
                                      'reviewText':
                                          reviewController.text.isEmpty
                                          ? null
                                          : reviewController.text,
                                    }),
                                  );
                                  print('✅ Review created');

                                  // Show centered notification
                                  NotificationService.showSuccessNotification(
                                    context: context,
                                    message: '✅ Review submitted successfully!',
                                  );
                                  print('✅ Review created');

                                  // 3. Refresh local caches
                                  await UserStatsStorage.refreshStats(
                                    widget.username,
                                  );
                                  await AchievementStorage.refreshAchievements(
                                    widget.username,
                                  );
                                  print('✅ Caches refreshed');

                                  setState(() {
                                    isLoading = false;
                                  });

                                  // Clear form after successful submission
                                  setState(() {
                                    selectedGameTitle = null;
                                    selectedGameId = null;
                                    yearController.clear();
                                    reviewController.clear();
                                    rating = 5;
                                    status = 'queued';
                                  });

                                  // Reload games to refresh status
                                  _loadUserGames();
                                } catch (e) {
                                  print('❌ Error submitting review: $e');

                                  setState(() {
                                    isLoading = false;
                                  });

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text(
                                          '❌ Error: ${e.toString()}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLoading || selectedGameId == null
                                  ? [Colors.grey, Colors.grey.shade700]
                                  : [
                                      const Color(0xFFe89a8a),
                                      const Color(0xFFd87a6a),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (selectedGameId != null && !isLoading)
                                BoxShadow(
                                  color: const Color(
                                    0xFFb85a4a,
                                  ).withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        selectedGameId == null
                                            ? 'Select a game first'
                                            : 'Submit Review',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      // Helper text
                      if (userGames.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'To write a review, first add games to your collection from the Home tab.',
                                    style: TextStyle(
                                      color: Colors.orange.shade200,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFd4a574),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      enabled: false,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white70),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF3a3a3a),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5a9a9a), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF5a9a9a).withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    yearController.dispose();
    reviewController.dispose();
    super.dispose();
  }
}

// Collection Screen
class CollectionScreen extends StatefulWidget {
  final String username;

  const CollectionScreen({super.key, required this.username});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<UserGameWithDetails> userGames = [];
  bool isLoading = true;
  Map<String, int> categoryCounts = {
    'Queued': 0,
    'Playing': 0,
    'Paused': 0,
    'Dropped': 0,
    'Cleared': 0,
  };

  // Define the 5 hardcoded categories
  final List<CollectionCategory> categories = [
    CollectionCategory(
      id: 'queued',
      name: 'Queued',
      icon: Icons.schedule,
      color: Colors.purple,
      mutedColor: Color(0xFF9370DB),
    ),
    CollectionCategory(
      id: 'playing',
      name: 'Playing',
      icon: Icons.play_arrow,
      color: Colors.blue,
      mutedColor: Color(0xFF6495ED),
    ),
    CollectionCategory(
      id: 'paused',
      name: 'Paused',
      icon: Icons.pause,
      color: Colors.orange,
      mutedColor: Color(0xFFFFB347),
    ),
    CollectionCategory(
      id: 'dropped',
      name: 'Dropped',
      icon: Icons.stop,
      color: Colors.grey,
      mutedColor: Color(0xFFA9A9A9),
    ),
    CollectionCategory(
      id: 'cleared',
      name: 'Cleared',
      icon: Icons.check_circle,
      color: Color(0xFF5a9a9a),
      mutedColor: Color(0xFF6AB9AA),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserGames();
  }

  Future<void> _loadUserGames() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = await ApiService.getUserId(widget.username);
      print('📖 Loading games for user ID: $userId');

      // Fetch user's games
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/UserGames?userId=$userId'),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> gamesData = jsonDecode(response.body);
        print('📚 Found ${gamesData.length} games in user collection');

        final List<UserGameWithDetails> loadedGames = [];

        // Fetch all games to get details
        final allGames = await ApiService.fetchAllGames();

        for (var userGame in gamesData) {
          // ✅ FIXED: Handle null values safely
          final gameId = userGame['gameId'] as int?;
          final userGameId = userGame['id'] as int? ?? 0;
          final userIdFromResponse = userGame['userId'] as int? ?? userId;
          final status = userGame['status'] as String? ?? 'queued';

          if (gameId == null) {
            print('⚠️ Skipping game with null gameId: $userGame');
            continue;
          }

          print('🎮 Processing game ID: $gameId, status: $status');

          final game = allGames.firstWhere(
            (g) => g.id == gameId,
            orElse: () => throw Exception('Game $gameId not found'),
          );

          loadedGames.add(
            UserGameWithDetails(
              userGameId: userGameId,
              gameId: gameId,
              userId: userIdFromResponse,
              status: status,
              playedAt: DateTime.parse(
                userGame['playedAt'] as String? ??
                    DateTime.now().toIso8601String(),
              ),
              updatedAt: DateTime.parse(
                userGame['updatedAt'] as String? ??
                    DateTime.now().toIso8601String(),
              ),
              title: game.title,
              releaseYear: game.releaseYear,
              imageUrl: game.imageUrl,
              summary: game.summary,
            ),
          );
        }

        // Update category counts
        final counts = {
          'Queued': loadedGames.where((g) => g.status == 'queued').length,
          'Playing': loadedGames.where((g) => g.status == 'playing').length,
          'Paused': loadedGames.where((g) => g.status == 'paused').length,
          'Dropped': loadedGames.where((g) => g.status == 'dropped').length,
          'Cleared': loadedGames.where((g) => g.status == 'cleared').length,
        };

        print('📊 Category counts: $counts');
        print('✅ Successfully loaded ${loadedGames.length} games');

        setState(() {
          userGames = loadedGames;
          categoryCounts = counts;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load user games: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading user games: $e');
      print('❌ Stack trace: $stackTrace');

      setState(() {
        isLoading = false;
      });

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Error loading collection: ${e.toString()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadUserGames,
            ),
          ),
        );
      }
    }
  }

  // Get games for a specific category
  List<UserGameWithDetails> _getGamesForCategory(String categoryId) {
    return userGames.where((game) => game.status == categoryId).toList();
  }

  void _showCategoryGames(CollectionCategory category) async {
    final categoryGames = _getGamesForCategory(category.id);

    if (categoryGames.isEmpty) {
      // Show message if category is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: category.mutedColor,
          content: Text(
            'No games in ${category.name} yet',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // ✅ FIXED: Wait for navigation to complete and refresh
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryGamesScreen(
          category: category,
          games: categoryGames,
          username: widget.username,
          onStatusChanged: _loadUserGames, // Refresh when status changes
        ),
      ),
    );

    // ✅ FIXED: Refresh when returning
    if (mounted) {
      await _loadUserGames();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe5ddd5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFF3a3a3a),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Collections',
                  style: ArcadeFontStyle.getStyle(
                    fontSize: 18,
                    color: const Color(0xFFd4a574),
                  ),
                ),
              ),
            ),

            if (isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF5a9a9a)),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categories Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.2,
                            ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final count = categoryCounts[category.name] ?? 0;
                          final hasGames = count > 0;

                          return GestureDetector(
                            onTap: () => _showCategoryGames(category),
                            child: Container(
                              decoration: BoxDecoration(
                                color: hasGames
                                    ? category.mutedColor.withOpacity(0.9)
                                    : const Color(0xFFd0d0d0),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasGames
                                      ? category.mutedColor
                                      : Colors.grey,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: hasGames
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.grey.shade600.withOpacity(
                                              0.2,
                                            ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      category.icon,
                                      color: hasGames
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Category Name
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: hasGames
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Count - Removed descriptions, only show count
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: hasGames
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Empty State Message
                      if (userGames.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 40),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFF5a9a9a),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.videogame_asset_outlined,
                                size: 64,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Your collection is empty',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Browse the Game Catalog and add games to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Model for collection category - UPDATED: Removed description field
class CollectionCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final Color mutedColor;

  CollectionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.mutedColor,
  });
}

// Model for user game with details
class UserGameWithDetails {
  final int userGameId;
  final int gameId;
  final int userId;
  final String status;
  final DateTime playedAt;
  final DateTime updatedAt;
  final String title;
  final int releaseYear;
  final String? imageUrl;
  final String summary;

  UserGameWithDetails({
    required this.userGameId,
    required this.gameId,
    required this.userId,
    required this.status,
    required this.playedAt,
    required this.updatedAt,
    required this.title,
    required this.releaseYear,
    this.imageUrl,
    required this.summary,
  });
}

// Screen for viewing games in a specific category
class CategoryGamesScreen extends StatefulWidget {
  final CollectionCategory category;
  final List<UserGameWithDetails> games;
  final String username;
  final VoidCallback onStatusChanged;

  const CategoryGamesScreen({
    super.key,
    required this.category,
    required this.games,
    required this.username,
    required this.onStatusChanged,
  });

  @override
  State<CategoryGamesScreen> createState() => _CategoryGamesScreenState();
}

class _CategoryGamesScreenState extends State<CategoryGamesScreen> {
  Future<void> _updateGameStatus(
    UserGameWithDetails game,
    String newStatus,
  ) async {
    try {
      await http.put(
        Uri.parse('${ApiService.baseUrl}/UserGames'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': game.userId,
          'gameId': game.gameId,
          'status': newStatus,
        }),
      );

      // ✅ FIXED: Refresh and pop back if moving to different category
      if (newStatus != widget.category.id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF5a9a9a),
              content: Text(
                '✅ ${game.title} moved to ${newStatus.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          // Call parent refresh
          widget.onStatusChanged();

          // Pop back to collection screen
          Navigator.pop(context);
        }
      } else {
        // Same category, just show message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF5a9a9a),
            content: Text(
              '✅ ${game.title} status unchanged',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            '❌ Error: ${e.toString()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showStatusChangeDialog(UserGameWithDetails game) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          title: Text(
            'Change Status for ${game.title}',
            style: const TextStyle(
              color: Color(0xFFd4a574),
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption('Queued', Icons.schedule, Colors.purple, game),
              _buildStatusOption(
                'Playing',
                Icons.play_arrow,
                Colors.blue,
                game,
              ),
              _buildStatusOption('Paused', Icons.pause, Colors.orange, game),
              _buildStatusOption('Dropped', Icons.stop, Colors.grey, game),
              _buildStatusOption(
                'Cleared',
                Icons.check_circle,
                Color(0xFF5a9a9a),
                game,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(
    String status,
    IconData icon,
    Color color,
    UserGameWithDetails game,
  ) {
    final mutedColors = {
      'Queued': const Color(0xFF9370DB),
      'Playing': const Color(0xFF6495ED),
      'Paused': const Color(0xFFFFB347),
      'Dropped': const Color(0xFFA9A9A9),
      'Cleared': const Color(0xFF6AB9AA),
    };

    final mutedColor = mutedColors[status] ?? color;
    final isCurrentStatus = game.status == status.toLowerCase();

    return ListTile(
      onTap: () {
        Navigator.pop(context);
        if (!isCurrentStatus) {
          _updateGameStatus(game, status.toLowerCase());
        }
      },
      leading: Icon(icon, color: isCurrentStatus ? Colors.white : mutedColor),
      title: Text(
        status,
        style: TextStyle(
          color: isCurrentStatus ? Colors.white : mutedColor,
          fontWeight: isCurrentStatus ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      tileColor: isCurrentStatus ? mutedColor.withOpacity(0.3) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe5ddd5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3a3a3a),
        title: Text(
          '${widget.category.name} (${widget.games.length})',
          style: const TextStyle(
            color: Color(0xFFd4a574),
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.games.length,
        itemBuilder: (context, index) {
          final game = widget.games[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF5a9a9a), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              onTap: () async {
                // ✅ FIXED: Wait for navigation and refresh
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApiGameDetailScreen(
                      game: ApiGame(
                        id: game.gameId,
                        title: game.title,
                        summary: game.summary,
                        releaseYear: game.releaseYear,
                        isActive: true,
                        imageUrl: game.imageUrl,
                      ),
                      username: widget.username,
                    ),
                  ),
                );
                // Trigger refresh when returning
                if (mounted) {
                  widget.onStatusChanged();
                  Navigator.pop(context); // Go back to collection screen
                }
              },

              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF5a9a9a), width: 1),
                  image: game.imageUrl != null
                      ? DecorationImage(
                          image: AssetImage(game.imageUrl!),
                          fit: BoxFit
                              .cover, // Changed to cover for better fitting
                        )
                      : null,
                  color: const Color(0xFF2a2a2a),
                ),
                child: game.imageUrl == null
                    ? Center(
                        child: Text(
                          game.title.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              title: Text(
                game.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${game.releaseYear} • ${game.summary.substring(0, min(50, game.summary.length))}...',
                style: const TextStyle(fontSize: 12),
              ),
              // REMOVED: The three dots menu since it's not needed anymore
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// UPDATED PROFILE SCREEN - FIXED HEADER AND POLISHED UI
// ============================================
// ============================================
// UPDATED PROFILE SCREEN - WITH EDIT/DELETE FOR REVIEWS
// ============================================
class ProfileScreen extends StatefulWidget {
  final String username;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserStats _userStats;
  List<Map<String, dynamic>> _recentReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('📊 Loading profile data for: ${widget.username}');

      // Load user stats
      _userStats = await UserStatsStorage.getUserStats(widget.username);
      print('✅ User stats loaded for ${widget.username}');

      // Load recent reviews
      await _loadRecentReviews();

      print('✅ Profile data loaded successfully');
    } catch (e) {
      print('❌ Error loading profile data: $e');

      // Set empty data on error
      _userStats = UserStats();
      _recentReviews = [];

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Could not load profile data'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRecentReviews() async {
    try {
      print('🔄 Loading recent reviews for: ${widget.username}');

      // Get user ID
      final userId = await ApiService.getUserId(widget.username);
      print('📋 User ID: $userId');

      // Fetch all reviews
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/Reviews'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> allReviews = jsonDecode(response.body);
        print('📚 Total reviews in database: ${allReviews.length}');

        // Filter reviews for this user
        final userReviews = allReviews.where((r) {
          final dynamic userIdField = r['userId'];
          final int reviewUserId;

          if (userIdField is int) {
            reviewUserId = userIdField;
          } else if (userIdField is String) {
            reviewUserId = int.tryParse(userIdField) ?? 0;
          } else {
            reviewUserId = 0;
          }

          return reviewUserId == userId;
        }).toList();

        print('👤 User reviews found: ${userReviews.length}');

        // Fetch all games for details
        final allGames = await ApiService.fetchAllGames();
        print('🎮 Total games available: ${allGames.length}');

        // Process reviews with game details
        final List<Map<String, dynamic>> processedReviews = [];

        for (var review in userReviews) {
          try {
            final dynamic gameIdField = review['gameId'];
            final int gameId;

            if (gameIdField is int) {
              gameId = gameIdField;
            } else if (gameIdField is String) {
              gameId = int.tryParse(gameIdField) ?? 0;
            } else {
              print('⚠️ Invalid gameId type: ${gameIdField.runtimeType}');
              continue;
            }

            if (gameId == 0) {
              print('⚠️ Skipping review with invalid gameId: $review');
              continue;
            }

            // Find the game
            final game = allGames.firstWhere(
              (g) => g.id == gameId,
              orElse: () => ApiGame(
                id: 0,
                title: 'Unknown Game',
                summary: '',
                releaseYear: 0,
                isActive: false,
              ),
            );

            if (game.id == 0) {
              print('⚠️ Game $gameId not found in catalog');
              continue;
            }

            final dynamic ratingField = review['rating'];
            double rating;

            if (ratingField is double) {
              rating = ratingField;
            } else if (ratingField is int) {
              rating = ratingField.toDouble();
            } else if (ratingField is String) {
              rating = double.tryParse(ratingField) ?? 0.0;
            } else {
              print('⚠️ Invalid rating type: ${ratingField.runtimeType}');
              rating = 0.0;
            }

            final status = review['status']?.toString() ?? 'cleared';
            final reviewText = review['reviewText']?.toString() ?? '';

            final dynamic createdAtField = review['createdAt'];
            String createdAt;

            if (createdAtField is int) {
              createdAt = DateTime.fromMillisecondsSinceEpoch(
                createdAtField,
              ).toIso8601String();
            } else if (createdAtField is String) {
              createdAt = createdAtField;
            } else {
              createdAt = DateTime.now().toIso8601String();
            }

            // ✅ NEW: Get review ID from backend
            final dynamic reviewIdField = review['id'];
            int? reviewId;

            if (reviewIdField is int) {
              reviewId = reviewIdField;
            } else if (reviewIdField is String) {
              reviewId = int.tryParse(reviewIdField);
            }

            processedReviews.add({
              'reviewId': reviewId, // ✅ NEW: Store review ID
              'gameId': gameId,
              'gameTitle': game.title,
              'releaseYear': game.releaseYear,
              'rating': rating,
              'status': status,
              'reviewText': reviewText,
              'createdAt': createdAt,
              'gameImage': game.imageUrl,
            });

            print(
              '✅ Processed review: ${game.title} (Rating: $rating, Status: $status)',
            );
          } catch (e) {
            print('❌ Error processing review: $e');
            print('❌ Review data: $review');
          }
        }

        // Sort by date (newest first) and take latest 5
        processedReviews.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['createdAt'] as String);
            final dateB = DateTime.parse(b['createdAt'] as String);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });

        setState(() {
          _recentReviews = processedReviews.take(5).toList();
        });

        print('✅ Recent reviews loaded: ${_recentReviews.length}');
      } else {
        print('❌ Failed to fetch reviews: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading recent reviews: $e');
      print('❌ Stack trace: $stackTrace');

      setState(() {
        _recentReviews = [];
      });
    }
  }

  // ✅ NEW: Show edit/delete options menu
  void _showReviewOptionsMenu(
    BuildContext context,
    Map<String, dynamic> review,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2a2a2a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  review['gameTitle'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Divider(color: Color(0xFF3a3a3a)),

              // Edit Option
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF5a9a9a)),
                title: const Text(
                  'Edit Review',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditReviewDialog(review);
                },
              ),

              // Delete Option
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Review',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(review);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ✅ NEW: Show edit review dialog
  void _showEditReviewDialog(Map<String, dynamic> review) {
    final reviewTextController = TextEditingController(
      text: review['reviewText'] as String? ?? '',
    );
    double currentRating = (review['rating'] as double?) ?? 5.0;
    String currentStatus = (review['status'] as String?) ?? 'cleared';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2a2a2a),
              title: Text(
                'Edit Review: ${review['gameTitle']}',
                style: const TextStyle(
                  color: Color(0xFFd4a574),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating Slider
                    const Text(
                      'Rating',
                      style: TextStyle(
                        color: Color(0xFFd4a574),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: currentRating,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: const Color(0xFF5a9a9a),
                      onChanged: (value) {
                        setDialogState(() {
                          currentRating = value;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (index) {
                        return Text(
                          index < currentRating.floor() ? '⭐' : '☆',
                          style: const TextStyle(fontSize: 20),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
                    const Text(
                      'Status',
                      style: TextStyle(
                        color: Color(0xFFd4a574),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3a3a3a),
                        border: Border.all(
                          color: const Color(0xFF5a9a9a),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: currentStatus,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF3a3a3a),
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        items:
                            [
                              'queued',
                              'playing',
                              'paused',
                              'dropped',
                              'cleared',
                            ].map((s) {
                              final Color mutedColor;
                              switch (s) {
                                case 'queued':
                                  mutedColor = const Color(0xFF9370DB);
                                  break;
                                case 'playing':
                                  mutedColor = const Color(0xFF6495ED);
                                  break;
                                case 'paused':
                                  mutedColor = const Color(0xFFFFB347);
                                  break;
                                case 'dropped':
                                  mutedColor = const Color(0xFFA9A9A9);
                                  break;
                                case 'cleared':
                                  mutedColor = const Color(0xFF6AB9AA);
                                  break;
                                default:
                                  mutedColor = Colors.white;
                              }

                              return DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.toUpperCase(),
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            currentStatus = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Review Text
                    const Text(
                      'Review Text',
                      style: TextStyle(
                        color: Color(0xFFd4a574),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewTextController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF3a3a3a),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF5a9a9a),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF5a9a9a),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6abaaa),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateReview(
                      review,
                      currentRating,
                      currentStatus,
                      reviewTextController.text,
                    );
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFF5a9a9a),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ NEW: Update review in backend
  Future<void> _updateReview(
    Map<String, dynamic> review,
    double newRating,
    String newStatus,
    String newReviewText,
  ) async {
    try {
      final reviewId = review['reviewId'] as int?;

      if (reviewId == null) {
        throw Exception('Review ID not found');
      }

      // Update review via API
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/Reviews/$reviewId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rating': newRating,
          'status': newStatus,
          'reviewText': newReviewText.isEmpty ? null : newReviewText,
        }),
      );

      if (response.statusCode == 200) {
        // Show success notification
        if (mounted) {
          NotificationService.showSuccessNotification(
            context: context,
            message: '✅ Review updated successfully',
          );

          // Reload reviews
          await _loadRecentReviews();

          // Refresh stats
          await UserStatsStorage.refreshStats(widget.username);
        }
      } else {
        throw Exception('Failed to update review: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating review: $e');

      if (mounted) {
        NotificationService.showErrorNotification(
          context: context,
          message: '❌ Failed to update review',
        );
      }
    }
  }

  // ✅ NEW: Show delete confirmation dialog
  void _showDeleteConfirmation(Map<String, dynamic> review) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          title: const Text(
            'Delete Review?',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete your review for "${review['gameTitle']}"? This action cannot be undone.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteReview(review);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ NEW: Delete review from backend
  Future<void> _deleteReview(Map<String, dynamic> review) async {
    try {
      final reviewId = review['reviewId'] as int?;

      if (reviewId == null) {
        throw Exception('Review ID not found');
      }

      // Delete review via API
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/Reviews/$reviewId'),
      );

      if (response.statusCode == 200) {
        // Show success notification
        if (mounted) {
          NotificationService.showSuccessNotification(
            context: context,
            message: '✅ Review deleted successfully',
          );

          // Reload reviews
          await _loadRecentReviews();

          // Refresh stats
          await UserStatsStorage.refreshStats(widget.username);
        }
      } else {
        throw Exception('Failed to delete review: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting review: $e');

      if (mounted) {
        NotificationService.showErrorNotification(
          context: context,
          message: '❌ Failed to delete review',
        );
      }
    }
  }

  // Get user initials for profile picture
  String _getUserInitials() {
    if (widget.username.isEmpty) return '?';
    final parts = widget.username.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.username
        .substring(0, min(2, widget.username.length))
        .toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'queued':
        return Colors.purple;
      case 'playing':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'dropped':
        return Colors.grey;
      case 'cleared':
        return const Color(0xFF5a9a9a);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'queued':
        return 'Queued';
      case 'playing':
        return 'Playing';
      case 'paused':
        return 'Paused';
      case 'dropped':
        return 'Dropped';
      case 'cleared':
        return 'Cleared';
      default:
        return status;
    }
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          color: const Color(0xFFd4a574),
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe5ddd5),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Container(
              color: const Color(0xFF3a3a3a),
              padding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 20,
              ),
              child: Center(
                child: Text(
                  'Profile',
                  style: ArcadeFontStyle.getStyle(
                    fontSize: 20,
                    color: const Color(0xFFd4a574),
                  ),
                ),
              ),
            ),

            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF5a9a9a)),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFd4a574),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Profile Picture
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFd4a574),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFd4a574,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _getUserInitials(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Username
                            Text(
                              '@${widget.username}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3a3a3a),
                                fontFamily: 'monospace',
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildProfileStat(
                                  _userStats.reviewedGames.toString(),
                                  'Reviews',
                                  Icons.rate_review,
                                ),
                                _buildProfileStat(
                                  _userStats.totalGames.toString(),
                                  'Listed',
                                  Icons.list,
                                ),
                                _buildProfileStat(
                                  _userStats.clearedGames.toString(),
                                  'Played',
                                  Icons.check_circle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Recent Reviews Section
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Reviews',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3a3a3a),
                                  ),
                                ),
                                if (_recentReviews.isNotEmpty)
                                  Text(
                                    '(${_recentReviews.length})',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (_recentReviews.isEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(24),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFd4a574),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.reviews,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No reviews yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Write your first review to see it here!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._recentReviews.map((review) {
                                return _buildReviewCard(review);
                              }).toList(),
                          ],
                        ),
                      ),

                      // Logout Button
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: widget.onLogout,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFd87a6a),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFd87a6a).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Log Out',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ UPDATED: Review card with three dots menu
  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFd4a574), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFd4a574), width: 1),
            image: review['gameImage'] != null
                ? DecorationImage(
                    image: AssetImage(review['gameImage']!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: const Color(0xFF2a2a2a),
          ),
          child: review['gameImage'] == null
              ? Center(
                  child: Text(
                    (review['gameTitle'] as String).substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        title: Text(
          review['gameTitle'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${review['releaseYear']} • ',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      review['status'] as String,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStatusColor(review['status'] as String),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(review['status'] as String),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(review['status'] as String),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStarRating(review['rating'] as double),
                const SizedBox(width: 4),
                Text(
                  '${review['rating']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFd4a574),
                  ),
                ),
              ],
            ),
            if ((review['reviewText'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  review['reviewText'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        // ✅ NEW: Three dots menu button
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF3a3a3a)),
          onPressed: () => _showReviewOptionsMenu(context, review),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFd4a574).withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFd4a574), width: 2),
          ),
          child: Icon(icon, color: const Color(0xFFd4a574), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3a3a3a),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// ============================================
// ENHANCED NOTIFICATION SERVICE WITH SOUND
// ============================================
class EnhancedNotificationService {
  static Future<void> showAchievementNotification({
    required BuildContext context,
    required String title,
    required String message,
    required String emoji,
    Color backgroundColor = const Color(0xFF5a9a9a),
    Duration duration = const Duration(seconds: 3),
  }) async {
    try {
      // Use built-in Flutter haptic feedback (no package needed)
      try {
        // Different vibration intensities available:
        // For achievement notifications, use medium or heavy impact
        await HapticFeedback.mediumImpact();
      } catch (e) {
        // Fallback in case haptics aren't available
        print('Haptic feedback not available: $e');
      }

      // Show centered notification
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.1,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Achievement emoji
                  Text(emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),

                  // Progress indicator
                  const SizedBox(height: 16),
                  Container(
                    height: 4,
                    width: MediaQuery.of(context).size.width * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Stack(
                      children: [
                        // Animated progress bar
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: duration,
                          builder: (context, value, child) {
                            return FractionallySizedBox(
                              widthFactor: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      overlay.insert(overlayEntry);

      // Remove after duration
      Future.delayed(duration, () {
        overlayEntry.remove();
      });
    } catch (e) {
      print('Error showing notification: $e');
      // Fallback to simpler notification
      NotificationService.showSuccessNotification(
        context: context,
        message: '$emoji $title: $message',
      );
    }
  }
}

class ArcadeFontStyle {
  static TextStyle getStyle({
    required double fontSize,
    Color color = const Color(0xFFd4a574),
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: 'PressStart2P',
      letterSpacing: 1.5,
      height: 1.2,
    );
  }
}

// Models
class GameReview {
  final String game;
  final int year;
  final int rating;
  final String status;
  final String review;

  GameReview(this.game, this.year, this.rating, this.status, this.review);
}

class GameCollection {
  final String name;
  final int count;

  GameCollection(this.name, this.count);
}
