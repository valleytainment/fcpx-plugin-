#import <CoreMedia/CoreMedia.h>
#import "FCPXObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface FCPXSequence : FCPXObject
@property (nonatomic, readonly) CMTime duration;
@property (nonatomic, readonly) CMTime startTime;
@property (nonatomic, readonly) CMTime frameDuration;
@property (nonatomic, readonly) NSInteger timecodeFormat;
@end

NS_ASSUME_NONNULL_END
