import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/logger_service.dart';
import 'models/ai_cache_entry.dart';
import 'models/ai_response.dart';

final aiCacheProvider = Provider<AiCache>((ref) {
  return AiCache();
});

class AiCache {
  final Map<String, AiCacheEntry> _memoryCache = {};
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Returns the cached response if it exists and is not expired.
  Future<AiResponse?> get(String key) async {
    // 1. Check memory cache
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired) {
        AppLogger.d('[AiCache] Memory Hit: $key');
        return entry.response;
      } else {
        _memoryCache.remove(key);
      }
    }

    // 2. Check disk cache
    await init();
    final jsonStr = _prefs!.getString('ai_cache_$key');
    if (jsonStr != null) {
      try {
        final entry = AiCacheEntry.fromJson(jsonStr);
        if (!entry.isExpired) {
          // Bring to memory cache
          _memoryCache[key] = entry;
          AppLogger.d('[AiCache] Disk Hit: $key');
          return entry.response;
        } else {
          await _prefs!.remove('ai_cache_$key');
        }
      } catch (e) {
        AppLogger.e('[AiCache] Error parsing disk cache', error: e);
        await _prefs!.remove('ai_cache_$key');
      }
    }

    AppLogger.d('[AiCache] Miss: $key');
    return null;
  }

  /// Saves the response to both memory and disk cache.
  Future<void> save(String key, AiResponse response, {Duration ttl = const Duration(hours: 1)}) async {
    final entry = AiCacheEntry(
      key: key,
      response: response,
      expiresAt: DateTime.now().add(ttl),
    );

    // Save to memory
    _memoryCache[key] = entry;

    // Save to disk
    await init();
    try {
      await _prefs!.setString('ai_cache_$key', entry.toJson());
      AppLogger.d('[AiCache] Saved to cache: $key');
    } catch (e) {
      AppLogger.e('[AiCache] Error saving to disk cache', error: e);
    }
  }

  /// Invalidates a specific key in both caches.
  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    await init();
    await _prefs!.remove('ai_cache_$key');
    AppLogger.d('[AiCache] Invalidated: $key');
  }

  /// Clears all AI caches.
  Future<void> clearAll() async {
    _memoryCache.clear();
    await init();
    final keys = _prefs!.getKeys().where((k) => k.startsWith('ai_cache_'));
    for (final k in keys) {
      await _prefs!.remove(k);
    }
    AppLogger.i('[AiCache] Cleared all caches.');
  }
}
