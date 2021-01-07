#import "WorkerManagerPlugin.h"
#if __has_include(<worker_manager/worker_manager-Swift.h>)
#import <worker_manager/worker_manager-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "worker_manager-Swift.h"
#endif

@implementation WorkerManagerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftWorkerManagerPlugin registerWithRegistrar:registrar];
}
@end
