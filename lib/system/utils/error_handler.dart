import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/api_client.dart';

class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is UnauthorizedException) {
      return 'Please login again';
    }
    if (error is ApiException) {
      return error.message;
    }
    if (error is SocketException) {
      return 'No internet connection';
    }
    if (error is TimeoutException) {
      return 'Request timeout';
    }
    return 'Something went wrong';
  }

  static Future<void> handleError(BuildContext context, Object error) async {
    final message = getErrorMessage(error);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
