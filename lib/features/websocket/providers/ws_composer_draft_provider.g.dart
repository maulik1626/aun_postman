// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_composer_draft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$wsComposerDraftHash() => r'ef1852df209b68241f8d3a2fa14bf362c96e1796';

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

abstract class _$WsComposerDraft extends BuildlessNotifier<String> {
  late final String sessionId;

  String build(String sessionId);
}

/// Latest composer text per WebSocket tab (for global actions e.g. Save from sheet).
///
/// Copied from [WsComposerDraft].
@ProviderFor(WsComposerDraft)
const wsComposerDraftProvider = WsComposerDraftFamily();

/// Latest composer text per WebSocket tab (for global actions e.g. Save from sheet).
///
/// Copied from [WsComposerDraft].
class WsComposerDraftFamily extends Family<String> {
  /// Latest composer text per WebSocket tab (for global actions e.g. Save from sheet).
  ///
  /// Copied from [WsComposerDraft].
  const WsComposerDraftFamily();

  /// Latest composer text per WebSocket tab (for global actions e.g. Save from sheet).
  ///
  /// Copied from [WsComposerDraft].
  WsComposerDraftProvider call(String sessionId) {
    return WsComposerDraftProvider(sessionId);
  }

  @override
  WsComposerDraftProvider getProviderOverride(
    covariant WsComposerDraftProvider provider,
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
  String? get name => r'wsComposerDraftProvider';
}

/// Latest composer text per WebSocket tab (for global actions e.g. Save from sheet).
///
/// Copied from [WsComposerDraft].
class WsComposerDraftProvider
    extends NotifierProviderImpl<WsComposerDraft, String> {
  /// Latest composer text per WebSocket tab (for global actions e.g. Save from sheet).
  ///
  /// Copied from [WsComposerDraft].
  WsComposerDraftProvider(String sessionId)
    : this._internal(
        () => WsComposerDraft()..sessionId = sessionId,
        from: wsComposerDraftProvider,
        name: r'wsComposerDraftProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$wsComposerDraftHash,
        dependencies: WsComposerDraftFamily._dependencies,
        allTransitiveDependencies:
            WsComposerDraftFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  WsComposerDraftProvider._internal(
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
  String runNotifierBuild(covariant WsComposerDraft notifier) {
    return notifier.build(sessionId);
  }

  @override
  Override overrideWith(WsComposerDraft Function() create) {
    return ProviderOverride(
      origin: this,
      override: WsComposerDraftProvider._internal(
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
  NotifierProviderElement<WsComposerDraft, String> createElement() {
    return _WsComposerDraftProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WsComposerDraftProvider && other.sessionId == sessionId;
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
mixin WsComposerDraftRef on NotifierProviderRef<String> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _WsComposerDraftProviderElement
    extends NotifierProviderElement<WsComposerDraft, String>
    with WsComposerDraftRef {
  _WsComposerDraftProviderElement(super.provider);

  @override
  String get sessionId => (origin as WsComposerDraftProvider).sessionId;
}

String _$wsComposerFormatLiveHash() =>
    r'a39c2b4dfe208b3b19cf90cf9b5f483706a6d59a';

abstract class _$WsComposerFormatLive
    extends BuildlessNotifier<WsComposerFormat> {
  late final String sessionId;

  WsComposerFormat build(String sessionId);
}

/// Selected composer format per tab (mirrors panel state for bookmark Save).
///
/// Copied from [WsComposerFormatLive].
@ProviderFor(WsComposerFormatLive)
const wsComposerFormatLiveProvider = WsComposerFormatLiveFamily();

/// Selected composer format per tab (mirrors panel state for bookmark Save).
///
/// Copied from [WsComposerFormatLive].
class WsComposerFormatLiveFamily extends Family<WsComposerFormat> {
  /// Selected composer format per tab (mirrors panel state for bookmark Save).
  ///
  /// Copied from [WsComposerFormatLive].
  const WsComposerFormatLiveFamily();

  /// Selected composer format per tab (mirrors panel state for bookmark Save).
  ///
  /// Copied from [WsComposerFormatLive].
  WsComposerFormatLiveProvider call(String sessionId) {
    return WsComposerFormatLiveProvider(sessionId);
  }

  @override
  WsComposerFormatLiveProvider getProviderOverride(
    covariant WsComposerFormatLiveProvider provider,
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
  String? get name => r'wsComposerFormatLiveProvider';
}

/// Selected composer format per tab (mirrors panel state for bookmark Save).
///
/// Copied from [WsComposerFormatLive].
class WsComposerFormatLiveProvider
    extends NotifierProviderImpl<WsComposerFormatLive, WsComposerFormat> {
  /// Selected composer format per tab (mirrors panel state for bookmark Save).
  ///
  /// Copied from [WsComposerFormatLive].
  WsComposerFormatLiveProvider(String sessionId)
    : this._internal(
        () => WsComposerFormatLive()..sessionId = sessionId,
        from: wsComposerFormatLiveProvider,
        name: r'wsComposerFormatLiveProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$wsComposerFormatLiveHash,
        dependencies: WsComposerFormatLiveFamily._dependencies,
        allTransitiveDependencies:
            WsComposerFormatLiveFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  WsComposerFormatLiveProvider._internal(
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
  WsComposerFormat runNotifierBuild(covariant WsComposerFormatLive notifier) {
    return notifier.build(sessionId);
  }

  @override
  Override overrideWith(WsComposerFormatLive Function() create) {
    return ProviderOverride(
      origin: this,
      override: WsComposerFormatLiveProvider._internal(
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
  NotifierProviderElement<WsComposerFormatLive, WsComposerFormat>
  createElement() {
    return _WsComposerFormatLiveProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WsComposerFormatLiveProvider &&
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
mixin WsComposerFormatLiveRef on NotifierProviderRef<WsComposerFormat> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _WsComposerFormatLiveProviderElement
    extends NotifierProviderElement<WsComposerFormatLive, WsComposerFormat>
    with WsComposerFormatLiveRef {
  _WsComposerFormatLiveProviderElement(super.provider);

  @override
  String get sessionId => (origin as WsComposerFormatLiveProvider).sessionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
