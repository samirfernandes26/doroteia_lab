import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('GET /', () {
    test('responds with the API status.', () async {
      final context = _MockRequestContext();
      final response = route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        jsonDecode(await response.body()),
        equals({
          'message': 'Doroteia Lab API está online',
          'version': '0.0.1',
        }),
      );
    });
  });
}
