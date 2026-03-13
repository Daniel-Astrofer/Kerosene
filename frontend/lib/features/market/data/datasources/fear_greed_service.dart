import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FearAndGreedService {
  static const String _url = 'https://api.alternative.me/fng/';

  Future<Map<String, dynamic>> getFearAndGreed() async {
    try {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          return data['data'][0];
        }
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching Fear & Greed: $e');
      return {};
    }
  }
}
