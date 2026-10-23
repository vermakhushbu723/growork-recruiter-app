import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/account_type.dart';
import '../../../shared/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final RecruiterUser? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    RecruiterUser? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Session against the backend. Methods throw [ApiException] with a
/// user-readable message; screens show it in a snackbar.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _ready = _restoreSession();
  }

  /// Resolves once the stored session has been checked. Splash awaits it.
  late final Future<void> _ready;
  Future<void> get ready => _ready;

  Future<void> _restoreSession() async {
    try {
      await api.loadToken();
      if (!api.hasToken) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
      await refresh();
    } on ApiException catch (e) {
      // Expired token → log in again; network down → still offline-unauth.
      if (e.isUnauthorized) await api.setToken(null);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Re-reads the signed-in account (and company) from the server.
  Future<void> refresh() async {
    final me = await api.get('/auth/me');
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: RecruiterUser.fromJson(jMap(me)),
    );
  }

  Future<void> _startSession(Object? data) async {
    final d = jMap(data);
    await api.setToken(jStr(d['token']));
    state = AuthState(
      status: AuthStatus.authenticated,
      user: RecruiterUser.fromJson(jMap(d['user'])),
    );
  }

  Future<T> _busy<T>(Future<T> Function() run) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final r = await run();
      state = state.copyWith(isLoading: false);
      return r;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) =>
      _busy(() async {
        await _startSession(
          await api.post('/auth/login', {
            'app': kApp,
            'email': email,
            'password': password,
          }),
        );
      });

  Future<void> signup({
    required String name,
    required String email,
    required String company,
    required String password,
    String phone = '',
  }) => _busy(() async {
    await _startSession(
      await api.post('/auth/register', {
        'app': kApp,
        'name': name,
        'email': email,
        'company': company,
        'password': password,
        'phone': phone,
      }),
    );
  });

  /// Sends a 4-digit code. Returns the code in dev mode (server
  /// `OTP_DEV_MODE=true`), otherwise null.
  Future<String?> sendOtp(String target, {required bool reset}) async {
    final d = jMap(
      await api.post('/auth/otp/send', {
        'target': target,
        'purpose': reset ? 'reset' : 'login',
      }),
    );
    return d['devOtp'] as String?;
  }

  Future<void> verifyLoginOtp(String target, String code) => _busy(() async {
    await _startSession(
      await api.post('/auth/otp/verify', {
        'target': target,
        'purpose': 'login',
        'code': code,
        'app': kApp,
      }),
    );
  });

  /// Verifies a reset code and sets the new password.
  Future<void> resetPassword(String target, String code, String password) =>
      _busy(() async {
        final d = jMap(
          await api.post('/auth/otp/verify', {
            'target': target,
            'purpose': 'reset',
            'code': code,
          }),
        );
        await api.post('/auth/reset-password', {
          'resetToken': d['resetToken'],
          'password': password,
        });
      });

  Future<void> logout() async {
    await api.setToken(null);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> deleteAccount() async {
    await api.delete('/auth/me');
    await logout();
  }

  Future<void> _patchMe(Map<String, dynamic> body) async {
    final me = await api.patch('/auth/me', body);
    state = state.copyWith(user: RecruiterUser.fromJson(jMap(me)));
  }

  Future<void> setAccountType(AccountType type) =>
      _patchMe({'accountType': type.name});

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? designation,
  }) => _patchMe({
    'name': ?name,
    'email': ?email,
    'phone': ?phone,
    'designation': ?designation,
  });

  Future<void> updateCompany(CompanyModel company) async {
    await api.patch('/company', company.toJson());
    await refresh();
  }

  Future<void> inviteMember(String email, String role) async {
    await api.post('/company/members', {'email': email, 'role': role});
    await refresh();
  }

  Future<void> setMemberRole(String memberId, String role) async {
    await api.patch('/company/members/$memberId', {'role': role});
    await refresh();
  }

  Future<void> removeMember(String memberId) async {
    await api.delete('/company/members/$memberId');
    await refresh();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

/// Changes only when a different account signs in or out. Data providers
/// watch this so they reload (and never leak) across accounts.
final sessionUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authProvider.select((s) => s.user?.id)),
);
