import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:aun_reqstudio/app/platform.dart';
import 'package:aun_reqstudio/core/constants/app_constants.dart';
import 'package:aun_reqstudio/features/collections/providers/collections_provider.dart';
import 'package:aun_reqstudio/features/environments/providers/environments_provider.dart';
import 'package:aun_reqstudio/features/history/providers/history_provider.dart';
import 'package:aun_reqstudio/features/settings/providers/app_settings_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

enum AuthBootstrapStatus { initializing, ready, setupError }

enum AuthAction { google, apple, signOut }

@immutable
class AppAuthState {
  const AppAuthState({
    this.status = AuthBootstrapStatus.initializing,
    this.user,
    this.isBusy = false,
    this.errorMessage,
    this.backendSessionToken,
    this.activeAction,
    this.hasSignedInBefore = false,
  });

  final AuthBootstrapStatus status;
  final User? user;
  final bool isBusy;
  final String? errorMessage;
  final String? backendSessionToken;
  final AuthAction? activeAction;
  final bool hasSignedInBefore;

  bool get isAuthenticated => user != null;

  bool get hasFatalSetupError => status == AuthBootstrapStatus.setupError;

  AppAuthState copyWith({
    AuthBootstrapStatus? status,
    User? user,
    bool clearUser = false,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    String? backendSessionToken,
    bool clearBackendSession = false,
    AuthAction? activeAction,
    bool clearActiveAction = false,
    bool? hasSignedInBefore,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      backendSessionToken: clearBackendSession
          ? null
          : (backendSessionToken ?? this.backendSessionToken),
      activeAction: clearActiveAction
          ? null
          : (activeAction ?? this.activeAction),
      hasSignedInBefore: hasSignedInBefore ?? this.hasSignedInBefore,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AppAuthState>((ref) {
      return AuthController(ref);
    });

final authStateChangesProvider = StreamProvider<User?>((_) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthController extends StateNotifier<AppAuthState> {
  AuthController(this._ref) : super(const AppAuthState()) {
    _bootstrap();
  }

  final Ref _ref;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  StreamSubscription<User?>? _authSubscription;

  Future<void> _bootstrap() async {
    try {
      final token = await _secureStorage.read(
        key: StorageKeys.backendSessionToken,
      );
      final hasSignedInBefore =
          await _secureStorage.read(key: StorageKeys.hasSignedInBefore) ==
          'true';
      state = state.copyWith(
        backendSessionToken: token,
        hasSignedInBefore: hasSignedInBefore,
        clearError: true,
      );
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        _onFirebaseUserChanged,
        onError: (Object error, StackTrace stackTrace) {
          state = state.copyWith(
            status: AuthBootstrapStatus.setupError,
            errorMessage: 'Auth listener failed: $error',
          );
        },
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthBootstrapStatus.setupError,
        errorMessage:
            'Firebase Auth is not fully configured. Complete Firebase setup and restart the app.',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    await _runBusyAction(
      action: AuthAction.google,
      run: () async {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize();
        final account = await googleSignIn.authenticate();
        final authentication = account.authentication;
        final idToken = authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw const AuthFailure('Google did not return an ID token.');
        }
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await _signInOrLinkWithCredential(
          credential: credential,
          providerId: GoogleAuthProvider.PROVIDER_ID,
        );
      },
    );
  }

  Future<void> signInWithApple() async {
    if (!AppPlatform.isIOS) {
      state = state.copyWith(
        errorMessage: 'Apple sign-in is available only on iOS.',
      );
      return;
    }
    await _runBusyAction(
      action: AuthAction.apple,
      run: () async {
        final isAvailable = await SignInWithApple.isAvailable();
        if (!isAvailable) {
          throw const AuthFailure(
            'Apple sign-in is not available on this device right now. Make sure Sign in with Apple is enabled for the app and the device is signed in to an Apple ID.',
          );
        }
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: const [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );
        final identityToken = appleCredential.identityToken;
        if (identityToken == null || identityToken.isEmpty) {
          throw const AuthFailure(
            'Apple sign-in did not return a valid identity token. Try again from a physical iPhone or rebuild after enabling the Apple capability in Xcode.',
          );
        }
        final oauthCredential = OAuthProvider(
          'apple.com',
        ).credential(idToken: identityToken, rawNonce: rawNonce);
        await _signInOrLinkWithCredential(
          credential: oauthCredential,
          providerId: 'apple.com',
        );
      },
    );
  }

  Future<void> signOut() async {
    await _runBusyAction(
      action: AuthAction.signOut,
      run: () async {
        await _revokeBackendSession();
        await _secureStorage.delete(key: StorageKeys.backendSessionToken);
        await _secureStorage.delete(key: StorageKeys.backendSessionIssuedAt);
        await FirebaseAuth.instance.signOut();
        try {
          await GoogleSignIn.instance.disconnect();
        } catch (_) {
          await GoogleSignIn.instance.signOut();
        }
        await _ref
            .read(appSettingsProvider.notifier)
            .resetAdPreferencesToDefaults();

        state = state.copyWith(clearBackendSession: true, clearError: true);
        _ref.invalidate(collectionsProvider);
        _ref.invalidate(environmentsProvider);
        _ref.invalidate(historyProvider);
      },
    );
  }

  Future<void> clearError() async {
    state = state.copyWith(clearError: true);
  }

  Future<void> _onFirebaseUserChanged(User? user) async {
    if (user == null) {
      state = state.copyWith(
        status: AuthBootstrapStatus.ready,
        clearUser: true,
        clearBackendSession: true,
        clearError: true,
      );
      return;
    }
    final backendSession = await _exchangeTokenWithBackend(user);
    await _secureStorage.write(
      key: StorageKeys.hasSignedInBefore,
      value: 'true',
    );
    state = state.copyWith(
      status: AuthBootstrapStatus.ready,
      user: user,
      backendSessionToken: backendSession,
      hasSignedInBefore: true,
      clearError: true,
    );
  }

  Future<void> _runBusyAction({
    required AuthAction action,
    required Future<void> Function() run,
  }) async {
    state = state.copyWith(
      isBusy: true,
      activeAction: action,
      clearError: true,
    );
    try {
      await run();
    } on AuthFailure catch (error) {
      state = state.copyWith(errorMessage: error.message);
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(errorMessage: _mapFirebaseError(error));
    } on PlatformException catch (error) {
      state = state.copyWith(errorMessage: _mapPlatformError(error));
    } catch (error) {
      state = state.copyWith(errorMessage: _mapUnknownAuthError(error));
    } finally {
      state = state.copyWith(isBusy: false, clearActiveAction: true);
    }
  }

  Future<void> _signInOrLinkWithCredential({
    required AuthCredential credential,
    required String providerId,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      return;
    } on FirebaseAuthException catch (error) {
      if (error.code != 'account-exists-with-different-credential') {
        rethrow;
      }
      final pendingCredential = error.credential;
      if (pendingCredential == null) {
        rethrow;
      }
      if (providerId != GoogleAuthProvider.PROVIDER_ID) {
        await signInWithGoogle();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.linkWithCredential(pendingCredential);
        }
        return;
      }
      throw const AuthFailure(
        'This email already exists with a different provider. Sign in with Google first, then retry.',
      );
    }
  }

  Future<String> _exchangeTokenWithBackend(User user) async {
    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw const AuthFailure(
        'Unable to create a session. Missing Firebase token.',
      );
    }
    // Placeholder production contract:
    // POST /session/exchange with Firebase ID token -> returns backend session JWT.
    // This keeps your backend as the source of truth and enables future cross-platform sync.
    final fallbackSession = base64Url.encode(
      utf8.encode('${user.uid}:${DateTime.now().millisecondsSinceEpoch}'),
    );
    await _secureStorage.write(
      key: StorageKeys.backendSessionToken,
      value: fallbackSession,
    );
    await _secureStorage.write(
      key: StorageKeys.backendSessionIssuedAt,
      value: DateTime.now().toUtc().toIso8601String(),
    );
    return fallbackSession;
  }

  Future<void> _revokeBackendSession() async {
    // Placeholder for future server revocation API call. Local revocation remains immediate.
    await Future<void>.value();
  }

  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return 'Network unavailable. Check connection and retry.';
      case 'invalid-credential':
        return 'Credential is invalid or expired. Please sign in again.';
      case 'missing-or-invalid-nonce':
        return 'Apple sign-in could not be verified. Rebuild the iOS app and try again.';
      case 'user-disabled':
        return 'This account is disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again shortly.';
      case 'sign_in_canceled':
      case 'sign_in_cancelled':
        return 'Sign-in cancelled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase yet.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method. Use the original provider first, then retry.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  String _mapPlatformError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = error.message?.toLowerCase() ?? '';
    final details = error.details?.toString().toLowerCase() ?? '';
    final combined = '$code $message $details';

    if (combined.contains('canceled') || combined.contains('cancelled')) {
      return 'Sign-in cancelled.';
    }
    if (combined.contains('network')) {
      return 'Network unavailable. Check connection and retry.';
    }
    if (combined.contains('authorizationerrorcode') ||
        combined.contains('authorization-error') ||
        combined.contains('1000')) {
      return 'Apple sign-in could not complete. Verify the Apple capability, provisioning profile, and Firebase Apple provider configuration, then try again.';
    }
    if (combined.contains('notavailable') || combined.contains('unavailable')) {
      return 'Sign-in is unavailable on this device right now. Check device account setup and native app capabilities.';
    }
    if (combined.contains('invalid') ||
        combined.contains('missing') ||
        combined.contains('credential')) {
      return 'Credential is invalid or incomplete. Please try again after restarting the app.';
    }
    if (combined.contains('channel-error')) {
      return 'Sign-in service is not ready. Fully restart the app and try again.';
    }
    return error.message ?? 'Authentication failed. Please retry.';
  }

  String _mapUnknownAuthError(Object error) {
    final value = error.toString().toLowerCase();
    if (value.contains('canceled') || value.contains('cancelled')) {
      return 'Sign-in cancelled.';
    }
    if (value.contains('network')) {
      return 'Network unavailable. Check connection and retry.';
    }
    return 'Something went wrong. Please retry.';
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}
