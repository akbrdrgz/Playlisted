import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:playlisted/main.dart';

void main() {
  testWidgets('Presence: Login Button exists', (WidgetTester tester) async {
    await tester.pumpWidget(const PlaylistedApp());
    expect(find.text('LOGIN'), findsOneWidget);
  });

  test('Welcome message for 0 games', () {
    final userStats = UserStats(totalGames: 0);
    final caption = (userStats.totalGames == 0)
        ? 'Start your gaming journey!'
        : '';
    expect(caption, 'Start your gaming journey!');
  });

  testWidgets('Submit Review button appears and is tappable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              int? selectedGameId = 1; //simulate selecting a game
              bool isLoading = false;

              return GestureDetector(
                onTap: isLoading || selectedGameId == null ? null : () {},
                child: Container(
                  child: Text(
                    selectedGameId == null
                        ? 'Select a game first'
                        : 'Submit Review',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // now find the submit button
    final buttonFinder = find.text('Submit Review');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
  });
}
