import 'dart:html';

/// Web implementation to get the number of logical processors (CPU cores) available for worker tasks.
/// Uses the browser's `navigator.hardwareConcurrency` API to determine the count.
///
/// The implementation reserves one core for the main thread by returning
/// `hardwareConcurrency - 1` when multiple cores are available. This ensures
/// the main thread has dedicated resources for UI and other critical operations.
///
/// Returns:
///   * Number of logical processors minus 1 if multiple cores are available
///   * 1 if only a single core is available or if hardwareConcurrency is not supported
///
/// This matches the behavior of the IO implementation which also reserves one core
/// for the main thread.
int get numberOfProcessors {
  // Check if multiple cores are available and subtract one for the main thread
  if (window.navigator.hardwareConcurrency != null &&
      window.navigator.hardwareConcurrency! > 1) {
    return window.navigator.hardwareConcurrency! - 1;
  }
  // Return 1 if single core or API not supported
  return 1;
}
