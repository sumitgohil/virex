typedef VirexLogListener =
    void Function(String event, {Map<String, Object?> data});

final class VirexLogger {
  VirexLogger._();

  static final VirexLogger instance = VirexLogger._();

  bool enabled = false;
  VirexLogListener? listener;

  void log(
    String event, {
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    if (!enabled || listener == null) {
      return;
    }
    listener!(event, data: data);
  }
}
