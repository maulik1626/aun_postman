// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_environment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeEnvironmentHash() => r'01c5912b5e373ec86ea2a1c58c689d11be4a17c6';

/// See also [ActiveEnvironment].
@ProviderFor(ActiveEnvironment)
final activeEnvironmentProvider =
    NotifierProvider<ActiveEnvironment, Environment?>.internal(
      ActiveEnvironment.new,
      name: r'activeEnvironmentProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeEnvironmentHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveEnvironment = Notifier<Environment?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
