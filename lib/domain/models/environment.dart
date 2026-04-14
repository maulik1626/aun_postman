import 'package:aun_reqstudio/domain/models/environment_variable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'environment.freezed.dart';
part 'environment.g.dart';

@freezed
class Environment with _$Environment {
  const factory Environment({
    required String uid,
    required String name,
    @Default(false) bool isActive,
    @Default([]) List<EnvironmentVariable> variables,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Environment;

  const Environment._();

  Map<String, String> get variableMap => {
        for (final v in variables.where((v) => v.isEnabled)) v.key: v.value,
      };

  factory Environment.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentFromJson(json);
}
