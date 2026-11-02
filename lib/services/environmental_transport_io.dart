import 'package:http/http.dart' as http;

class EnvironmentalHttpResponse {
  const EnvironmentalHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

Future<EnvironmentalHttpResponse> fetchEnvironmental(
  Uri uri,
  http.Client client,
) async {
  final response = await client.get(uri);
  return EnvironmentalHttpResponse(response.statusCode, response.body);
}
