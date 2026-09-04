import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cracha_app/main.dart';
import 'package:cracha_app/services/badge_form_controller.dart';
import 'package:cracha_app/services/badge_manager.dart';
import 'package:cracha_app/services/theme_notifier.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = MockHttpOverrides();
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-key',
    );
  });

  testWidgets('App boots with multi-provider structure', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BadgeManager()),
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          Provider<BadgeFormController>(create: (_) => BadgeFormController()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(MyApp), findsOneWidget);
  });
}

// Intercepta requisições HTTP em testes para evitar erros de rede
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return Future.value(MockHttpClientRequest());
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl("get", url);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() {
    return Future.value(MockHttpClientResponse());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static final List<int> _imgBytes = [
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
    0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84,
    120, 94, 99, 96, 96, 96, 0, 0, 0, 5, 0, 1, 165, 246, 69, 122, 0, 0, 0, 0,
    73, 69, 78, 68, 174, 66, 96, 130
  ];

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _imgBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_imgBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}
