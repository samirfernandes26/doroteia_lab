import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'message': 'Doroteia Lab API está online',
      'version': '0.0.1',
    },
  );
}
