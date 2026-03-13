import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Central provider for loading and caching FragmentPrograms (Shaders)
final metalShaderProvider = FutureProvider<FragmentProgram>((ref) async {
  try {
    return await FragmentProgram.fromAsset('assets/shaders/metallic_hologram.frag');
  } catch (e) {
    debugPrint('🚨 Error loading metal shader: $e');
    rethrow;
  }
});

/// A convenience provider for other shaders if needed
final bitcoinShaderProvider = FutureProvider<FragmentProgram>((ref) async {
  try {
    return await FragmentProgram.fromAsset('assets/shaders/bitcoin_hodl.frag');
  } catch (e) {
    debugPrint('🚨 Error loading bitcoin shader: $e');
    rethrow;
  }
});
