/// Result of the pre-request variables editor sheet.
sealed class PreRequestVariablesOutcome {}

/// User tapped Apply; [linesText] is the raw editor contents.
final class PreRequestVariablesApplied extends PreRequestVariablesOutcome {
  PreRequestVariablesApplied(this.linesText);
  final String linesText;
}

/// User tapped Clear in the title row.
final class PreRequestVariablesCleared extends PreRequestVariablesOutcome {}
