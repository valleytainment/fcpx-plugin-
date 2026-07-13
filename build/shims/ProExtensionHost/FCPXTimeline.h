#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

@class FCPXHost;
@class FCPXSequence;

NS_ASSUME_NONNULL_BEGIN

@protocol FCPXTimelineObserver <NSObject>
@optional
- (void)activeSequenceChanged;
- (void)playheadTimeChanged;
- (void)sequenceTimeRangeChanged;
@end

@interface FCPXTimeline : NSObject
@property (nonatomic, readonly) FCPXHost *host;
@property (nonatomic, readonly, nullable) FCPXSequence *activeSequence;
@property (nonatomic, readonly) CMTimeRange sequenceTimeRange;

- (instancetype)initWithHost:(FCPXHost *)host;
- (void)movePlayheadTo:(CMTime)time;
- (CMTime)playheadTime;
- (void)addTimelineObserver:(id<FCPXTimelineObserver>)observer;
- (void)removeTimelineObserver:(id<FCPXTimelineObserver>)observer;
@end

NS_ASSUME_NONNULL_END
