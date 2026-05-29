import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Central provider for loading and caching FragmentPrograms (Shaders)
final woodShaderProvider = FutureProvider<FragmentProgram>((ref) async {
  try {
    return await FragmentProgram.fromAsset('assets/shaders/card_wood.frag');
  } catch (e) {
    debugPrint('🚨 Error loading wood shader: $e');
    rethrow;
  }
});

final metalShaderProvider = FutureProvider<FragmentProgram>((ref) async {
  try {
    return await FragmentProgram.fromAsset('assets/shaders/card_metal.frag');
  } catch (e) {
    debugPrint('🚨 Error loading metal shader: $e');
    rethrow;
  }
});

final rubyShaderProvider = FutureProvider<FragmentProgram>((ref) async {
  try {
    return await FragmentProgram.fromAsset('assets/shaders/card_ruby.frag');
  } catch (e) {
    debugPrint('🚨 Error loading ruby shader: $e');
    rethrow;
  }
});

final emeraldShaderProvider = FutureProvider<FragmentProgram>((ref) async {
  try {
    return await FragmentProgram.fromAsset('assets/shaders/card_emerald.frag');
  } catch (e) {
    debugPrint('🚨 Error loading emerald shader: $e');
    rethrow;
  }
});

final diamondShaderProvider = FutureProvider<FragmentProgram>((ref) async {
  try {
    return await FragmentProgram.fromAsset('assets/shaders/card_diamond.frag');
  } catch (e) {
    debugPrint('🚨 Error loading diamond shader: $e');
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
