#import <Foundation/Foundation.h>
#import "ProExtensionHostBase.h"
#import "FCPXTimeline.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FCPXHost <NSObject>
@property (nonatomic, readonly) FCPXTimeline *timeline;
@property (nonatomic, readonly) NSString *versionString;
@property (nonatomic, readonly) NSString *bundleIdentifier;
@property (nonatomic, readonly) NSString *name;
@end

@interface FCPXHost : ProExtensionHostBase <FCPXHost>
@property (nonatomic, readonly) BOOL objectsHaveEssentialProperties;
@property (nonatomic, readonly) FCPXTimeline *timeline;

+ (instancetype)defaultHost;
+ (instancetype)connectedHost;
@end

NS_ASSUME_NONNULL_END
