import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tesoro_navigation_app/demo_auth.dart';
import 'package:tesoro_navigation_app/login_screen.dart';
import 'package:tesoro_navigation_app/register_screen.dart';
import 'package:tesoro_navigation_app/main_screen.dart';

final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
]);

class MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => MockHttpClientRequest();
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => MockHttpClientResponse();
}

class MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => MockHttpClient();
}

Future<void> loadFonts() async {
  final fontDir = r'C:\Users\Luis James - 554-639\Downloads\flutter\flutter\bin\cache\artifacts\material_fonts';
  
  final robotoFile = File('$fontDir\\roboto-regular.ttf');
  if (await robotoFile.exists()) {
    final robotoData = await robotoFile.readAsBytes();
    final fontLoader = FontLoader('Roboto');
    fontLoader.addFont(Future.value(ByteData.view(robotoData.buffer)));
    await fontLoader.load();
  }

  final iconsFile = File('$fontDir\\materialicons-regular.otf');
  if (await iconsFile.exists()) {
    final iconsData = await iconsFile.readAsBytes();
    final iconLoader = FontLoader('MaterialIcons');
    iconLoader.addFont(Future.value(ByteData.view(iconsData.buffer)));
    await iconLoader.load();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = TestHttpOverrides();
    await loadFonts();
  });

  testWidgets('Capture screenshots of all screens and social media features', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(480, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Login Screen screenshot
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('screenshots/00_login_screen.png'),
    );

    // 2. Register Screen screenshot
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const RegisterScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RegisterScreen),
      matchesGoldenFile('screenshots/00_register_screen.png'),
    );

    // Login as admin for main screen
    DemoAuth.login('admin', 'admin123');

    // Main App with Navigation Bar
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 3. Home Page screenshot
    await expectLater(
      find.byType(MainScreen),
      matchesGoldenFile('screenshots/01_home_page.png'),
    );

    // 4. Calculator Page screenshot
    await tester.tap(find.byIcon(Icons.calculate_outlined));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MainScreen),
      matchesGoldenFile('screenshots/02_calculator_page.png'),
    );

    // 5. Profile Page screenshot (with Logout button)
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MainScreen),
      matchesGoldenFile('screenshots/03_profile_page.png'),
    );

    // 6. Social Media Page screenshot
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MainScreen),
      matchesGoldenFile('screenshots/04_social_media_page.png'),
    );

    // 7. Open Create Post sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/05_create_post_sheet.png'),
    );

    // Enter post caption and image URL
    await tester.enterText(
      find.widgetWithText(TextField, 'Caption'),
      'My first Flutter social media post!',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Image URL'),
      'https://picsum.photos/id/20/600/400',
    );
    await tester.pumpAndSettle();

    // Submit post
    await tester.tap(find.text('Submit Post'));
    await tester.pumpAndSettle();

    // 8. Like the new post
    final likeButtons = find.widgetWithText(TextButton, 'Like');
    expect(likeButtons, findsWidgets);
    await tester.tap(likeButtons.first);
    await tester.pumpAndSettle();

    // Add a comment
    final commentInputs = find.byType(TextField);
    await tester.enterText(commentInputs.first, 'Great first post!');
    final sendButtons = find.byIcon(Icons.send);
    await tester.tap(sendButtons.first);
    await tester.pumpAndSettle();

    // 9. Post with Like and Comment screenshot
    await expectLater(
      find.byType(MainScreen),
      matchesGoldenFile('screenshots/06_post_with_like_and_comment.png'),
    );
  });
}
