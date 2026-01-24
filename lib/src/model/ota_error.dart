enum OtaErrorType { network, parse, storage, checksum, invalidManifest }

class OtaError {
  const OtaError({
    required this.type,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final OtaErrorType type;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
}
