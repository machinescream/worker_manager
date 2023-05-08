sealed class Result {}

final class ResultSuccess<R> extends Result {
  final R value;

  ResultSuccess(this.value);
}

final class ResultError extends Result {
  final Object error;
  final StackTrace stackTrace;

  ResultError(this.error, this.stackTrace);
}
