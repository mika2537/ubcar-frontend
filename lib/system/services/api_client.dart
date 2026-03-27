/// Minimal API client placeholder for your future HTTP/Supabase integration.
class ApiClient {
  const ApiClient();

  /// Generic GET that optionally converts JSON into a Dart model.
  Future<T?> get<T>(String path, {T Function(Object? json)? fromJson}) async {
    // TODO: implement HTTP call.
    return null;
  }

  /// Generic POST that optionally converts JSON into a Dart model.
  Future<T?> post<T>(
    String path, {
    Object? body,
    T Function(Object? json)? fromJson,
  }) async {
    // TODO: implement HTTP call.
    return null;
  }

  /// Generic PUT that optionally converts JSON into a Dart model.
  Future<T?> put<T>(
    String path, {
    Object? body,
    T Function(Object? json)? fromJson,
  }) async {
    // TODO: implement HTTP call.
    return null;
  }

  /// Generic DELETE.
  Future<void> delete(String path) async {
    // TODO: implement HTTP call.
  }
}

