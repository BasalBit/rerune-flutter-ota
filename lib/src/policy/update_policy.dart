class ReRuneUpdatePolicy {
  const ReRuneUpdatePolicy({this.checkOnStart = true, this.periodicInterval});

  final bool checkOnStart;
  final Duration? periodicInterval;
}
