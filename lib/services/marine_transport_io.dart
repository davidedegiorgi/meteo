import 'package:http/http.dart' as http;

class MarineHttpResponse {
  const MarineHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

Future<MarineHttpResponse> fetchMarine(Uri uri, http.Client client) async {
  final response = await client.get(uri);
  return MarineHttpResponse(response.statusCode, response.body);
}
