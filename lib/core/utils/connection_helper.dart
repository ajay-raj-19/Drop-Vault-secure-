import 'dart:io';
import 'package:flutter/foundation.dart';

/// Checks if the device has an active internet connection.
Future<bool> checkInternetConnection() async {
  if (kIsWeb) {
    return true; // Assume online on Web, or let network requests handle error
  }
  try {
    final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
