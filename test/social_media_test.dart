import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tesoro_navigation_app/demo_auth.dart';
import 'package:tesoro_navigation_app/main_screen.dart';
import 'package:tesoro_navigation_app/social_media/create_post_sheet.dart';
import 'package:tesoro_navigation_app/social_media/social_media.dart';

void main() {
  setUp(() {
    DemoAuth.registeredUsername = null;
    DemoAuth.registeredPassword = null;
    DemoAuth.currentUsername = null;
  });

  testWidgets('Test 1 & 2: Log in using default admin account opens MainScreen and Social Media shows sample posts', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    DemoAuth.login('admin', 'admin123');

    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify MainScreen opened on Home
    expect(find.text('Welcome, Student!'), findsOneWidget);

    // Switch to Social Media tab (index 3)
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();

    // Verify sample posts appear
    expect(find.text('JohnDoe'), findsOneWidget);
    expect(find.text('Enjoying the sunny weather!'), findsOneWidget);
    expect(find.text('JaneSmith'), findsOneWidget);
    expect(find.text('Just finished a great book!'), findsOneWidget);
  });

  testWidgets('Test 3: Submit a post with empty fields shows validation SnackBar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CreatePostSheet(username: 'admin'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap submit with empty fields
    await tester.tap(find.text('Submit Post'));
    await tester.pump();

    expect(find.text('Complete both fields before submitting!'), findsOneWidget);
  });

  testWidgets('Test 4: Submit a post with an invalid URL shows URL validation SnackBar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CreatePostSheet(username: 'admin'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Caption'), 'Test Caption');
    await tester.enterText(find.widgetWithText(TextField, 'Image URL'), 'not_a_valid_url');
    await tester.tap(find.text('Submit Post'));
    await tester.pump();

    expect(find.text('Enter a valid HTTP or HTTPS image URL.'), findsOneWidget);
  });

  testWidgets('Test 5: Submit a valid post appears at top with username', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SocialMediaPage(username: 'admin'),
      ),
    );
    await tester.pumpAndSettle();

    // Tap FAB to open sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Fill form
    await tester.enterText(find.widgetWithText(TextField, 'Caption'), 'My new test post');
    await tester.enterText(find.widgetWithText(TextField, 'Image URL'), 'https://picsum.photos/id/10/400/300');
    await tester.tap(find.text('Submit Post'));
    await tester.pumpAndSettle();

    // Verify new post appears at the top
    expect(find.text('My new test post'), findsOneWidget);
    expect(find.text('admin'), findsOneWidget);
  });

  testWidgets('Test 6: Tap Like twice toggles Liked and Like', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SocialMediaPage(username: 'admin'),
      ),
    );
    await tester.pumpAndSettle();

    final likeButton = find.widgetWithText(TextButton, 'Like').first;
    expect(find.text('Like'), findsWidgets);

    // Tap Like once
    await tester.tap(likeButton);
    await tester.pumpAndSettle();
    expect(find.text('Liked'), findsOneWidget);

    // Tap Liked again
    final likedButton = find.widgetWithText(TextButton, 'Liked').first;
    await tester.tap(likedButton);
    await tester.pumpAndSettle();
    expect(find.text('Liked'), findsNothing);
  });

  testWidgets('Test 7 & 8: Add comment increases count; blank comment is ignored', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SocialMediaPage(username: 'admin'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 Comments'), findsWidgets);

    // Try submitting blank comment
    final sendButton = find.byIcon(Icons.send).first;
    await tester.tap(sendButton);
    await tester.pumpAndSettle();
    expect(find.text('0 Comments'), findsWidgets);

    // Enter a valid comment
    final commentField = find.byType(TextField).first;
    await tester.enterText(commentField, 'Awesome photo!');
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.text('1 Comments'), findsOneWidget);
    expect(find.text('Awesome photo!'), findsOneWidget);
  });

  testWidgets('Test 9: Like a sample post, then create another post; original keeps liked state', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: SocialMediaPage(username: 'admin'),
      ),
    );
    await tester.pumpAndSettle();

    // Like first sample post (JohnDoe)
    await tester.tap(find.widgetWithText(TextButton, 'Like').first);
    await tester.pumpAndSettle();
    expect(find.text('Liked'), findsOneWidget);

    // Create a new post
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Caption'), 'New Post Ahead');
    await tester.enterText(find.widgetWithText(TextField, 'Image URL'), 'https://picsum.photos/id/30/400/300');
    await tester.tap(find.text('Submit Post'));
    await tester.pumpAndSettle();

    // Verify new post is added
    expect(find.text('New Post Ahead'), findsOneWidget);
    expect(find.text('Liked'), findsOneWidget);
  });

  testWidgets('Test 10: Switch to Home and return preserves posts and state', (tester) async {
    DemoAuth.login('admin', 'admin123');

    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Social Media
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();

    // Like first post
    await tester.tap(find.widgetWithText(TextButton, 'Like').first);
    await tester.pumpAndSettle();
    expect(find.text('Liked'), findsOneWidget);

    // Switch to Home tab
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Student!'), findsOneWidget);

    // Switch back to Social Media tab
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();

    // Verify Liked state is preserved
    expect(find.text('Liked'), findsOneWidget);
  });

  testWidgets('Test 11: Logout, register, and login with new account creates post with new username', (tester) async {
    // 1. Initial admin login
    DemoAuth.login('admin', 'admin123');
    expect(DemoAuth.currentUsername, 'admin');

    // 2. Logout
    DemoAuth.logout();
    expect(DemoAuth.currentUsername, isNull);

    // 3. Register
    DemoAuth.register('student_maria', 'pass1234');

    // 4. Login with registered user
    final success = DemoAuth.login('student_maria', 'pass1234');
    expect(success, isTrue);
    expect(DemoAuth.currentUsername, 'student_maria');

    // 5. Open MainScreen with student_maria
    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Open Social Media tab
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();

    // Create post
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Caption'), 'Hello from Maria!');
    await tester.enterText(find.widgetWithText(TextField, 'Image URL'), 'https://picsum.photos/id/50/400/300');
    await tester.tap(find.text('Submit Post'));
    await tester.pumpAndSettle();

    // Check post username
    expect(find.text('Hello from Maria!'), findsOneWidget);
    expect(find.text('student_maria'), findsOneWidget);
  });
}
