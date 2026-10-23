import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/_middleware.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('CORS middleware', () {
    test('answers OPTIONS preflight without invoking the route', () async {
      final context = _contextFor(HttpMethod.options);
      var routeWasCalled = false;
      final handler = middleware((_) {
        routeWasCalled = true;
        return Response();
      });

      final response = await handler(context);

      expect(response.statusCode, HttpStatus.noContent);
      expect(routeWasCalled, isFalse);
      _expectCorsHeaders(response);
    });

    test('adds CORS headers to regular route responses', () async {
      final context = _contextFor(HttpMethod.post);
      final handler = middleware(
        (_) => Response.json(
          headers: const {'x-api-header': 'preserved'},
          body: const {'success': true},
        ),
      );

      final response = await handler(context);

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers['x-api-header'], 'preserved');
      _expectCorsHeaders(response);
    });
  });
}

RequestContext _contextFor(HttpMethod method) {
  final context = _MockRequestContext();
  when(() => context.request).thenReturn(
    Request(method.value, Uri.parse('http://localhost/auth/login')),
  );
  return context;
}

void _expectCorsHeaders(Response response) {
  expect(response.headers['access-control-allow-origin'], '*');
  expect(
    response.headers['access-control-allow-methods'],
    'GET, POST, PUT, DELETE, OPTIONS',
  );
  expect(
    response.headers['access-control-allow-headers'],
    'Origin, Content-Type, Authorization',
  );
}
