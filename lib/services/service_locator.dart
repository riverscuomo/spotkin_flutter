// In service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:spotkin_flutter/app_core.dart';
import 'openai_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator({required Map<String, dynamic> config}) {
  getIt.registerLazySingleton<SpotifyService>(() => SpotifyService(
        clientId: config['SPOTIFY_CLIENT_ID']!,
        clientSecret: config['SPOTIFY_CLIENT_SECRET']!,
        redirectUri: config['SPOTIFY_REDIRECT_URI']!,
        scope: config['SPOTIFY_SCOPE']!,
      ));

  getIt.registerLazySingleton<StorageService>(() => StorageService());

  getIt.registerLazySingleton<BackendService>(() => BackendService(
        backendUrl: config['BACKEND_URL']!,
      ));

  // Register OpenAIService with the same backend URL
  getIt.registerLazySingleton<OpenAIService>(() => OpenAIService(
        backendUrl: config['BACKEND_URL']!,
      ));
}
