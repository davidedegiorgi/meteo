import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

class EnvironmentalHttpResponse {
  const EnvironmentalHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

Future<EnvironmentalHttpResponse> fetchEnvironmental(
  Uri uri,
  http.Client client,
) async {
  final response = await web.window.fetch(uri.toString().toJS).toDart;
  final body = (await response.text().toDart).toDart;
  return EnvironmentalHttpResponse(response.status, body);
}
