/// Placeholder for Google Maps / location APIs.
///
/// Keep these simple types until you add the real `google_maps_flutter` types.
class MapsService {
  const MapsService();

  /// A lightweight lat/lng container.
  ///
  /// Using `double` keeps it Dart-only (no extra dependencies).
  static Map<String, double> latLng(double lat, double lng) =>
      {'lat': lat, 'lng': lng};

  Future<List<Map<String, double>>?> geocode(String query) async {
    // TODO: call geocoding endpoint.
    return null;
  }

  /// Decode an encoded polyline string into points.
  Future<List<Map<String, double>>?> decodePolyline(String encoded) async {
    // TODO: implement polyline decode or call an API.
    return null;
  }

  /// Get route polyline between two points.
  Future<List<Map<String, double>>?> getRoutePolyline({
    required Map<String, double> from,
    required Map<String, double> to,
  }) async {
    // TODO: call directions API.
    return null;
  }
}

