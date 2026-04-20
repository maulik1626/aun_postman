// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$webSocketSessionNotifierHash() =>
    r'8ce2eb9627799e177a8a876a4343e3b8db3b36ce';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$WebSocketSessionNotifier
    extends BuildlessNotifier<WebSocketState> {
  late final String sessionId;

  WebSocketState build(String sessionId);
}

/// See also [WebSocketSessionNotifier].
@ProviderFor(WebSocketSessionNotifier)
const webSocketSessionNotifierProvider = WebSocketSessionNotifierFamily();

/// See also [WebSocketSessionNotifier].
class WebSocketSessionNotifierFamily extends Family<WebSocketState> {
  /// See also [WebSocketSessionNotifier].
  const WebSocketSessionNotifierFamily();

  /// See also [WebSocketSessionNotifier].
  WebSocketSessionNotifierProvider call(String sessionId) {
    return WebSocketSessionNotifierProvider(sessionId);
  }

  @override
  WebSocketSessionNotifierProvider getProviderOverride(
    covariant WebSocketSessionNotifierProvider provider,
  ) {
    return call(provider.sessionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'webSocketSessionNotifierProvider';
}

/// See also [WebSocketSessionNotifier].
class WebSocketSessionNotifierProvider
    extends NotifierProviderImpl<WebSocketSessionNotifier, WebSocketState> {
  /// See also [WebSocketSessionNotifier].
  WebSocketSessionNotifierProvider(String sessionId)
    : this._internal(
        () => WebSocketSessionNotifier()..sessionId = sessionId,
        from: webSocketSessionNotifierProvider,
        name: r'webSocketSessionNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$webSocketSessionNotifierHash,
        dependencies: WebSocketSessionNotifierFamily._dependencies,
        allTransitiveDependencies:
            WebSocketSessionNotifierFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  WebSocketSessionNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sessionId,
  }) : super.internal();

  final String sessionId;

  @override
  WebSocketState runNotifierBuild(covariant WebSocketSessionNotifier notifier) {
    return notifier.build(sessionId);
  }

  @override
  Override overrideWith(WebSocketSessionNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: WebSocketSessionNotifierProvider._internal(
        () => create()..sessionId = sessionId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sessionId: sessionId,
      ),
    );
  }

  @override
  NotifierProviderElement<WebSocketSessionNotifier, WebSocketState>
  createElement() {
    return _WebSocketSessionNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WebSocketSessionNotifierProvider &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WebSocketSessionNotifierRef on NotifierProviderRef<WebSocketState> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _WebSocketSessionNotifierProviderElement
    extends NotifierProviderElement<WebSocketSessionNotifier, WebSocketState>
    with WebSocketSessionNotifierRef {
  _WebSocketSessionNotifierProviderElement(super.provider);

  @override
  String get sessionId =>
      (origin as WebSocketSessionNotifierProvider).sessionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
