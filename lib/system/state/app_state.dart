import 'package:flutter/foundation.dart';

enum AppStatus { idle, loading, success, failure }

class AppState extends ChangeNotifier {
  AppStatus status = AppStatus.idle;
  String? errorMessage;
  Map<String, dynamic> userData = {};

  void setLoading() {
    status = AppStatus.loading;
    errorMessage = null;
    notifyListeners();
  }

  void setSuccess(Map<String, dynamic> data) {
    status = AppStatus.success;
    userData = data;
    errorMessage = null;
    notifyListeners();
  }

  void setFailure(String message) {
    status = AppStatus.failure;
    errorMessage = message;
    notifyListeners();
  }
}
