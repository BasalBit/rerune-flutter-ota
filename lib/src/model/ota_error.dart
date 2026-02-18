enum ReRuneErrorType { network, parse, storage, checksum, invalidManifest }

class ReRuneError {
  const ReRuneError({
    required this.type,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final ReRuneErrorType type;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
}
