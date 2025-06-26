import 'package:flutter/material.dart';

Future<T> executeWithRetry<T>(
  Future<T> Function() operation, {
  required int maxRetries,
  required Duration retryDelay,
}) async {
  int retryCount = 0;
  while (retryCount < maxRetries) {
    try {
      return await operation();
    } catch (e) {
      retryCount++;
      if (retryCount == maxRetries) {
        debugPrint('Operation failed after $maxRetries attempts: $e');
        rethrow;
      }
      await Future.delayed(retryDelay * retryCount);
    }
  }
  throw Exception('Operation failed after $maxRetries attempts');
}
