// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$environmentsHash() => r'5cd0b9be27991c7a741b69ebd9d5420f04bebbab';

/// See also [Environments].
@ProviderFor(Environments)
final environmentsProvider =
    NotifierProvider<Environments, List<Environment>>.internal(
      Environments.new,
      name: r'environmentsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$environmentsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Environments = Notifier<List<Environment>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
