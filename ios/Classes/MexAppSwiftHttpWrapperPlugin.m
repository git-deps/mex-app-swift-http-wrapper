#import "MexAppSwiftHttpWrapperPlugin.h"
#if __has_include(<MexAppSwiftHttpWrapper/MexAppSwiftHttpWrapper-Swift.h>)
#import <MexAppSwiftHttpWrapper/MexAppSwiftHttpWrapper-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "MexAppSwiftHttpWrapper-Swift.h"
#endif

@implementation MexAppSwiftHttpWrapperPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMexAppSwiftHttpWrapperPlugin registerWithRegistrar:registrar];
}
@end
