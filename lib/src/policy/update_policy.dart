class OtaUpdatePolicy {
  const OtaUpdatePolicy({this.checkOnStart = true, this.periodicInterval});

  final bool checkOnStart;
  final Duration? periodicInterval;
}
