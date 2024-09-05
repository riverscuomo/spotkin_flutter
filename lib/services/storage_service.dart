// import 'dart:convert';
// import 'dart:html' as html;
import 'package:spotkin_flutter/app_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // static const String _storageKey = 'jobs';

// Create secure storage instance
  final secureStorage = const FlutterSecureStorage();

// Store the auth token securely
  Future<void> storeAuthToken(String token) async {
    await secureStorage.write(key: 'spotify_auth_token', value: token);
  }

  Future<void> storeAuthUrl(String token) async {
    await secureStorage.write(key: 'spotify_auth_url', value: token);
  }

// Retrieve the auth token securely
  Future<String?> retrieveAuthToken() async {
    return await secureStorage.read(key: 'spotify_auth_token');
  }

  Future<String?> retrieveAuthUrl() async {
    return await secureStorage.read(key: 'spotify_auth_url');
  }

// Clear the auth token securely
  Future<void> clearAuthToken() async {
    await secureStorage.delete(key: 'spotify_auth_token');
  }
}
