#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ProExtensionHostBase <NSObject>
+ (instancetype)defaultHost;
+ (NSString *)implementationVersion;
- (void)observeHostNotification:(NSString *)notification object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;
@end

@interface ProExtensionHostBase : NSRunningApplication <ProExtensionHostBase>
@end

NS_ASSUME_NONNULL_END
