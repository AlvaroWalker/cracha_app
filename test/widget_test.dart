import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cracha_app/main.dart';
import 'package:cracha_app/services/badge_manager.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('App opens and shows main title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => BadgeManager(),
        child: const MyApp(),
      ),
    );

    // Permitir inicialização assíncrona dos crachás
    await tester.pumpAndSettle();

    // Verificar se o título "CAMPO VERDE" é exibido no cabeçalho
    expect(find.text('CAMPO VERDE'), findsOneWidget);
  });
}

// Intercepta requisições de imagem em ambiente de testes para evitar erros de rede 400
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
