import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class GooglePlaceSuggestion {
  const GooglePlaceSuggestion({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;
}

class GoogleRoutePlan {
  const GoogleRoutePlan({
    required this.polyline,
    required this.waypointOrder,
    required this.routeLocations,
    required this.distanceText,
    required this.durationText,
  });

  final List<Map<String, double>> polyline;
  final List<int> waypointOrder;
  final List<Map<String, double>> routeLocations;
  final String distanceText;
  final String durationText;
}

class MapsApiException implements Exception {
  const MapsApiException(this.status, [this.message]);

  final String status;
  final String? message;

  @override
  String toString() {
    final details = message?.trim();
    if (details == null || details.isEmpty) {
      return status;
    }
    return '$status: $details';
  }
}

class MapsService {
  const MapsService({http.Client? client}) : _client = client;

  static const googleMapsApiKey = 'AIzaSyBGsEqb6Fs9co0yGP6syLKZNF9eyC4LAO4';
  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const _placesAutocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static final http.Client _sharedClient = http.Client();

  final http.Client? _client;

  http.Client get _httpClient => _client ?? _sharedClient;

  static Map<String, double> latLng(double lat, double lng) => {
    'lat': lat,
    'lng': lng,
  };

  Future<List<GooglePlaceSuggestion>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return const [];
    }

    final uri = Uri.parse(_placesAutocompleteUrl).replace(
      queryParameters: {
        'input': trimmed,
        'key': googleMapsApiKey,
        'language': 'en',
        'location': '47.9189,106.9176',
        'radius': '70000',
      },
    );
    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      return const [];
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (payload['status'] != 'OK' && payload['status'] != 'ZERO_RESULTS') {
      return const [];
    }

    final predictions = payload['predictions'] as List<dynamic>? ?? const [];
    return predictions
        .whereType<Map<String, dynamic>>()
        .map((prediction) {
          final formatting =
              prediction['structured_formatting'] as Map<String, dynamic>?;
          return GooglePlaceSuggestion(
            placeId: prediction['place_id'] as String? ?? '',
            description: prediction['description'] as String? ?? '',
            mainText: formatting?['main_text'] as String?,
            secondaryText: formatting?['secondary_text'] as String?,
          );
        })
        .where((suggestion) {
          return suggestion.placeId.isNotEmpty &&
              suggestion.description.trim().isNotEmpty;
        })
        .toList();
  }

  Future<List<Map<String, double>>?> geocode(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      _geocodeUrl,
    ).replace(queryParameters: {'address': trimmed, 'key': googleMapsApiKey});
    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      return null;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (payload['status'] != 'OK') {
      return null;
    }

    final results = payload['results'] as List<dynamic>? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((result) {
          final geometry = result['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;
          final lat = (location?['lat'] as num?)?.toDouble();
          final lng = (location?['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) {
            return null;
          }
          return latLng(lat, lng);
        })
        .whereType<Map<String, double>>()
        .toList();
  }

  Future<List<Map<String, double>>?> decodePolyline(String encoded) async {
    return _decodePolyline(encoded);
  }

  Future<List<Map<String, double>>?> getRoutePolyline({
    required Map<String, double> from,
    required Map<String, double> to,
  }) async {
    final uri = Uri.parse(_directionsUrl).replace(
      queryParameters: {
        'origin': '${from['lat']},${from['lng']}',
        'destination': '${to['lat']},${to['lng']}',
        'key': googleMapsApiKey,
      },
    );
    return _directionsPolyline(uri);
  }

  Future<List<Map<String, double>>?> getOptimizedRoutePolyline({
    required String origin,
    required String destination,
    List<String> waypoints = const [],
  }) async {
    final plan = await getOptimizedRoutePlan(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
    );
    return plan?.polyline;
  }

  Future<GoogleRoutePlan?> getOptimizedRoutePlan({
    required String origin,
    required String destination,
    List<String> waypoints = const [],
  }) async {
    final queryParameters = <String, String>{
      'origin': origin,
      'destination': destination,
      'mode': 'driving',
      'region': 'mn',
      'departure_time': 'now',
      'traffic_model': 'best_guess',
      'key': googleMapsApiKey,
    };
    final cleanWaypoints = waypoints
        .map((point) => point.trim())
        .where((point) => point.isNotEmpty)
        .toList();
    if (cleanWaypoints.isNotEmpty) {
      queryParameters['waypoints'] =
          'optimize:true|${cleanWaypoints.join('|')}';
    }

    final uri = Uri.parse(
      _directionsUrl,
    ).replace(queryParameters: queryParameters);
    return _directionsPlan(uri);
  }

  Future<List<Map<String, double>>?> _directionsPolyline(Uri uri) async {
    final plan = await _directionsPlan(uri);
    return plan?.polyline;
  }

  Future<GoogleRoutePlan?> _directionsPlan(Uri uri) async {
    final http.Response response;
    try {
      response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 12));
    } on SocketException catch (error) {
      throw MapsApiException('NETWORK_ERROR', error.message);
    } on http.ClientException catch (error) {
      throw MapsApiException('NETWORK_ERROR', error.message);
    } on TimeoutException {
      throw const MapsApiException(
        'NETWORK_TIMEOUT',
        'Google Maps request timed out.',
      );
    }
    if (response.statusCode != 200) {
      throw MapsApiException('HTTP_${response.statusCode}');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final status = payload['status'] as String? ?? 'UNKNOWN_ERROR';
    if (status != 'OK') {
      throw MapsApiException(status, payload['error_message'] as String?);
    }

    final routes = payload['routes'] as List<dynamic>? ?? const [];
    final firstRoute = routes.whereType<Map<String, dynamic>>().firstOrNull;
    final overviewPolyline =
        firstRoute?['overview_polyline'] as Map<String, dynamic>?;
    final points = overviewPolyline?['points'] as String?;
    if (points == null || points.isEmpty) {
      return null;
    }

    final legs = firstRoute?['legs'] as List<dynamic>? ?? const [];
    var distanceMeters = 0;
    var durationSeconds = 0;
    final routeLocations = <Map<String, double>>[];
    for (final leg in legs.whereType<Map<String, dynamic>>()) {
      final distance = leg['distance'] as Map<String, dynamic>?;
      final duration = leg['duration'] as Map<String, dynamic>?;
      distanceMeters += (distance?['value'] as num?)?.round() ?? 0;
      durationSeconds += (duration?['value'] as num?)?.round() ?? 0;

      final startLocation = _locationFromJson(leg['start_location']);
      final endLocation = _locationFromJson(leg['end_location']);
      if (routeLocations.isEmpty && startLocation != null) {
        routeLocations.add(startLocation);
      }
      if (endLocation != null) {
        routeLocations.add(endLocation);
      }
    }

    final waypointOrder =
        (firstRoute?['waypoint_order'] as List<dynamic>? ?? [])
            .whereType<num>()
            .map((index) => index.toInt())
            .toList();

    return GoogleRoutePlan(
      polyline: _decodePolyline(points),
      waypointOrder: waypointOrder,
      routeLocations: routeLocations,
      distanceText: _formatDistance(distanceMeters),
      durationText: _formatDuration(durationSeconds),
    );
  }

  Map<String, double>? _locationFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final lat = (value['lat'] as num?)?.toDouble();
    final lng = (value['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      return null;
    }
    return latLng(lat, lng);
  }

  String _formatDistance(int meters) {
    if (meters <= 0) {
      return '--';
    }
    if (meters < 1000) {
      return '$meters m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) {
      return '--';
    }
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $remainingMinutes min';
  }

  List<Map<String, double>> _decodePolyline(String encoded) {
    var index = 0;
    var lat = 0;
    var lng = 0;
    final coordinates = <Map<String, double>>[];

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      coordinates.add(latLng(lat / 1e5, lng / 1e5));
    }

    return coordinates;
  }
}
