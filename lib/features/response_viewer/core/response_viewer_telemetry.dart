class ResponseViewerTelemetryEvent {
  const ResponseViewerTelemetryEvent({
    required this.name,
    required this.durationMs,
    this.metadata = const {},
  });

  final String name;
  final int durationMs;
  final Map<String, Object?> metadata;
}

abstract class ResponseViewerTelemetry {
  const ResponseViewerTelemetry();

  void record(ResponseViewerTelemetryEvent event);
}

class NoopResponseViewerTelemetry extends ResponseViewerTelemetry {
  const NoopResponseViewerTelemetry();

  @override
  void record(ResponseViewerTelemetryEvent event) {}
}
