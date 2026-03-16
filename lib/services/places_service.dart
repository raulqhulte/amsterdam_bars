import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String placeId;
  final String description;

  PlaceSuggestion({required this.placeId, required this.description});
}

class PlaceDetails {
  final String placeId;
  final String name;
  final double lat;
  final double lng;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
  });
}

class PlacesService {
  // ✅ Put the SAME key you used in AndroidManifest.xml
  // (Later we’ll hide it better; for now this is fine for a private app.)
  static const String apiKey = 'AIzaSyA0tmCJ5iD7p2sWCoOMC0MgqN4TxX5T_TE';

  // Autocomplete suggestions while typing
  Future<List<PlaceSuggestion>> autocomplete({
    required String input,
    String? sessionToken,
  }) async {
    if (input.trim().isEmpty) return [];

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': apiKey,
        'sessiontoken': sessionToken ?? '',
        // Bias results to Amsterdam area
        'location': '52.3676,4.9041',
        'radius': '15000',
        // Bars only
        'type': 'bar',
        'language': 'en',
      },
    );

    final resp = await http.get(uri);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    final status = data['status'] as String?;
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final msg = data['error_message'] ?? status;
      throw Exception('Places autocomplete failed: $msg');
    }

    final preds = (data['predictions'] as List<dynamic>? ?? []);
    return preds.map((p) {
      final m = p as Map<String, dynamic>;
      return PlaceSuggestion(
        placeId: m['place_id'] as String,
        description: m['description'] as String,
      );
    }).toList();
  }

  // Fetch lat/lng (and name) for a chosen place
  Future<PlaceDetails> details({
    required String placeId,
    String? sessionToken,
  }) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'key': apiKey,
        'sessiontoken': sessionToken ?? '',
        // Only request what we need (cheaper + faster)
        'fields': 'place_id,name,geometry/location',
        'language': 'en',
      },
    );

    final resp = await http.get(uri);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    final status = data['status'] as String?;
    if (status != 'OK') {
      final msg = data['error_message'] ?? status;
      throw Exception('Places details failed: $msg');
    }

    final result = data['result'] as Map<String, dynamic>;
    final name = result['name'] as String;
    final loc = (result['geometry'] as Map<String, dynamic>)['location']
        as Map<String, dynamic>;

    return PlaceDetails(
      placeId: result['place_id'] as String,
      name: name,
      lat: (loc['lat'] as num).toDouble(),
      lng: (loc['lng'] as num).toDouble(),
    );
  }
}
