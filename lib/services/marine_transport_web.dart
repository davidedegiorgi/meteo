import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

class MarineHttpResponse {
  const MarineHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

Future<MarineHttpResponse> fetchMarine(Uri uri, http.Client client) async {
  final response = await web.window.fetch(uri.toString().toJS).toDart;
  final body = (await response.text().toDart).toDart;
  return MarineHttpResponse(response.status, body);
}
