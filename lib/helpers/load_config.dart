import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<Map<String, dynamic>> loadConfig() async {
  String configString = await rootBundle.loadString('assets/config.json');
  Map<String, dynamic> config = jsonDecode(configString);
  return config;
}

Future<void> loadDevConfig() async {}
