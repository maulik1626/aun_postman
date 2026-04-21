import 'dart:convert';

import 'package:aun_reqstudio/core/constants/ad_config.dart';
import 'package:aun_reqstudio/core/constants/app_constants.dart';
import 'package:aun_reqstudio/domain/models/key_value_pair.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_provider.g.dart';

class AppSettingsState {
  const AppSettingsState({
    this.timeoutSeconds = AppConstants.defaultTimeoutSeconds,
    this.followRedirects = true,
    this.verifySsl = true,
    this.httpProxy = '',
    this.wsAutoReconnect = false,
    this.requestAutoSave = true,
    this.icloudAutoBackup = false,
    this.defaultHeaders = const [],
    this.collectionsAdInterval = AdConfig.defaultCollectionsInlineAdInterval,
    this.historyAdInterval = AdConfig.defaultHistoryInlineAdInterval,
    this.environmentsAdInterval = AdConfig.defaultEnvironmentsInlineAdInterval,
  });

  final int timeoutSeconds;
  final bool followRedirects;

  /// When false, invalid TLS certificates are accepted (mobile/desktop IO only).
  final bool verifySsl;

  /// `host:port` or `http://host:port` — IO only; empty disables proxy.
  final String httpProxy;

  /// When true, WebSocket reconnects after an unexpected disconnect.
  final bool wsAutoReconnect;

  /// When true, unsaved request edits are written to local storage and restored after relaunch.
  final bool requestAutoSave;

  /// When true (iOS), a full JSON backup is written to iCloud shortly after the app backgrounds.
  final bool icloudAutoBackup;

  /// Sent on every HTTP request before request-specific headers (request wins on same name).
  final List<RequestHeader> defaultHeaders;

  /// User-configurable inline ad interval for Collections.
  final int collectionsAdInterval;

  /// User-configurable inline ad interval for History.
  final int historyAdInterval;

  /// User-configurable inline ad interval for Environments.
  final int environmentsAdInterval;

  AppSettingsState copyWith({
    int? timeoutSeconds,
    bool? followRedirects,
    bool? verifySsl,
    String? httpProxy,
    bool? wsAutoReconnect,
    bool? requestAutoSave,
    bool? icloudAutoBackup,
    List<RequestHeader>? defaultHeaders,
    int? collectionsAdInterval,
    int? historyAdInterval,
    int? environmentsAdInterval,
  }) => AppSettingsState(
    timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    followRedirects: followRedirects ?? this.followRedirects,
    verifySsl: verifySsl ?? this.verifySsl,
    httpProxy: httpProxy ?? this.httpProxy,
    wsAutoReconnect: wsAutoReconnect ?? this.wsAutoReconnect,
    requestAutoSave: requestAutoSave ?? this.requestAutoSave,
    icloudAutoBackup: icloudAutoBackup ?? this.icloudAutoBackup,
    defaultHeaders: defaultHeaders ?? this.defaultHeaders,
    collectionsAdInterval: collectionsAdInterval ?? this.collectionsAdInterval,
    historyAdInterval: historyAdInterval ?? this.historyAdInterval,
    environmentsAdInterval:
        environmentsAdInterval ?? this.environmentsAdInterval,
  );
}

@Riverpod(keepAlive: true)
class AppSettings extends _$AppSettings {
  static const _storage = FlutterSecureStorage();

  @override
  AppSettingsState build() {
    _load();
    return const AppSettingsState();
  }

  Future<void> _load() async {
    final timeoutStr = await _storage.read(key: StorageKeys.defaultTimeout);
    final followStr = await _storage.read(key: StorageKeys.followRedirects);
    final sslStr = await _storage.read(key: StorageKeys.sslVerification);
    final headersRaw = await _storage.read(key: StorageKeys.defaultHeaders);
    final proxyRaw = await _storage.read(key: StorageKeys.httpProxy);
    final wsReStr = await _storage.read(key: StorageKeys.wsAutoReconnect);
    final autoSaveStr = await _storage.read(key: StorageKeys.requestAutoSave);
    final icloudStr = await _storage.read(key: StorageKeys.icloudAutoBackup);
    final collectionsAdStr = await _storage.read(
      key: StorageKeys.adsCollectionsInterval,
    );
    final historyAdStr = await _storage.read(
      key: StorageKeys.adsHistoryInterval,
    );
    final environmentsAdStr = await _storage.read(
      key: StorageKeys.adsEnvironmentsInterval,
    );
    state = AppSettingsState(
      timeoutSeconds:
          (timeoutStr != null
                  ? int.tryParse(timeoutStr) ??
                        AppConstants.defaultTimeoutSeconds
                  : AppConstants.defaultTimeoutSeconds)
              .clamp(5, 300),
      followRedirects: followStr != 'false',
      verifySsl: sslStr != 'false',
      httpProxy: proxyRaw ?? '',
      wsAutoReconnect: wsReStr == 'true',
      requestAutoSave: autoSaveStr != 'false',
      icloudAutoBackup: icloudStr == 'true',
      defaultHeaders: _decodeDefaultHeaders(headersRaw),
      collectionsAdInterval: _decodeAdInterval(
        collectionsAdStr,
        AdConfig.collections.insertEvery,
      ),
      historyAdInterval: _decodeAdInterval(
        historyAdStr,
        AdConfig.history.insertEvery,
      ),
      environmentsAdInterval: _decodeAdInterval(
        environmentsAdStr,
        AdConfig.environments.insertEvery,
      ),
    );
  }

  static int _decodeAdInterval(String? raw, int fallback) {
    final parsed = raw != null ? int.tryParse(raw) : null;
    return (parsed ?? fallback).clamp(
      AdConfig.minInlineAdInterval,
      AdConfig.maxInlineAdInterval,
    );
  }

  static List<RequestHeader> _decodeDefaultHeaders(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => RequestHeader.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> setTimeoutSeconds(int seconds) async {
    final clamped = seconds.clamp(5, 300);
    state = state.copyWith(timeoutSeconds: clamped);
    await _storage.write(
      key: StorageKeys.defaultTimeout,
      value: clamped.toString(),
    );
  }

  Future<void> setFollowRedirects(bool value) async {
    state = state.copyWith(followRedirects: value);
    await _storage.write(
      key: StorageKeys.followRedirects,
      value: value.toString(),
    );
  }

  Future<void> setVerifySsl(bool value) async {
    state = state.copyWith(verifySsl: value);
    await _storage.write(
      key: StorageKeys.sslVerification,
      value: value.toString(),
    );
  }

  Future<void> setDefaultHeaders(List<RequestHeader> headers) async {
    state = state.copyWith(defaultHeaders: headers);
    final encoded = jsonEncode(headers.map((h) => h.toJson()).toList());
    await _storage.write(key: StorageKeys.defaultHeaders, value: encoded);
  }

  Future<void> setHttpProxy(String value) async {
    final v = value.trim();
    state = state.copyWith(httpProxy: v);
    if (v.isEmpty) {
      await _storage.delete(key: StorageKeys.httpProxy);
    } else {
      await _storage.write(key: StorageKeys.httpProxy, value: v);
    }
  }

  Future<void> setWsAutoReconnect(bool value) async {
    state = state.copyWith(wsAutoReconnect: value);
    await _storage.write(
      key: StorageKeys.wsAutoReconnect,
      value: value.toString(),
    );
  }

  Future<void> setRequestAutoSave(bool value) async {
    state = state.copyWith(requestAutoSave: value);
    await _storage.write(
      key: StorageKeys.requestAutoSave,
      value: value.toString(),
    );
  }

  Future<void> setIcloudAutoBackup(bool value) async {
    state = state.copyWith(icloudAutoBackup: value);
    await _storage.write(
      key: StorageKeys.icloudAutoBackup,
      value: value.toString(),
    );
  }

  Future<void> setCollectionsAdInterval(int value) async {
    final next = value.clamp(
      AdConfig.minInlineAdInterval,
      AdConfig.maxInlineAdInterval,
    );
    state = state.copyWith(collectionsAdInterval: next);
    await _storage.write(
      key: StorageKeys.adsCollectionsInterval,
      value: next.toString(),
    );
  }

  Future<void> setHistoryAdInterval(int value) async {
    final next = value.clamp(
      AdConfig.minInlineAdInterval,
      AdConfig.maxInlineAdInterval,
    );
    state = state.copyWith(historyAdInterval: next);
    await _storage.write(
      key: StorageKeys.adsHistoryInterval,
      value: next.toString(),
    );
  }

  Future<void> setEnvironmentsAdInterval(int value) async {
    final next = value.clamp(
      AdConfig.minInlineAdInterval,
      AdConfig.maxInlineAdInterval,
    );
    state = state.copyWith(environmentsAdInterval: next);
    await _storage.write(
      key: StorageKeys.adsEnvironmentsInterval,
      value: next.toString(),
    );
  }

  Future<void> resetAdPreferencesToDefaults() async {
    state = state.copyWith(
      collectionsAdInterval: AdConfig.collections.insertEvery,
      historyAdInterval: AdConfig.history.insertEvery,
      environmentsAdInterval: AdConfig.environments.insertEvery,
    );
    await _storage.delete(key: StorageKeys.adsCollectionsInterval);
    await _storage.delete(key: StorageKeys.adsHistoryInterval);
    await _storage.delete(key: StorageKeys.adsEnvironmentsInterval);
  }
}
