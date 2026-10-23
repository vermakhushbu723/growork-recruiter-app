import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Account preferences stored on the server (`GET/PATCH /settings`):
/// notification switches, privacy toggles and language.
class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  SettingsNotifier({bool autoLoad = true}) : super(const {}) {
    if (autoLoad) load();
  }

  Future<void> load() async {
    try {
      final d = jMap(await api.get('/settings'));
      if (mounted) state = d;
    } on ApiException catch (_) {}
  }

  bool flag(String key, {bool fallback = true}) => jBool(state[key], fallback);

  String get language => jStr(state['language'], 'English');

  /// Updates one setting optimistically; rolls back if the server refuses.
  Future<void> set(String key, Object value) async {
    final before = state;
    state = {...state, key: value};
    try {
      final d = jMap(await api.patch('/settings', {key: value}));
      if (mounted) state = d;
    } on ApiException {
      if (mounted) state = before;
      rethrow;
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
      final userId = ref.watch(sessionUserIdProvider);
      return SettingsNotifier(autoLoad: userId != null);
    });
