// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$historyHash() => r'7a7bbb865838b9a85855b51478581d0a2e718923';

/// See also [History].
@ProviderFor(History)
final historyProvider = NotifierProvider<History, List<HistoryEntry>>.internal(
  History.new,
  name: r'historyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$historyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$History = Notifier<List<HistoryEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
