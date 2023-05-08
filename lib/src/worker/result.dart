class Result {}

class ResultSuccess<R> extends Result {
  final R value;

  ResultSuccess(this.value);
}

class ResultError extends Result {
  final Object error;
  final StackTrace stackTrace;

  ResultError(this.error, this.stackTrace);
}
