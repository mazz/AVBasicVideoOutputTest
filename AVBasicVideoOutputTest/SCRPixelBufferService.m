//
//  SCRPixelBufferService.m
//  AVBasicVideoOutputTest
//
//  Created by Michael Hanna on 2015-08-02.
//  Copyright (c) 2015 ILS. All rights reserved.
//

#import "SCRPixelBufferService.h"

# define ONE_FRAME_DURATION 0.03

@interface SCRPixelBufferService()
@property (weak, nonatomic, nonnull) id <SCRPixelBufferServiceDelegate> delegate;
@property (strong, nonatomic, nonnull) AVPlayer *player;
@property (strong, nonatomic, nonnull) dispatch_queue_t myVideoOutputQueue;
@property (strong, nonatomic, nonnull) AVPlayerItemVideoOutput *videoOutput;
@property (strong, nonatomic, nonnull) CADisplayLink *displayLink;
- (void)displayLinkCallback:(CADisplayLink *)sender;
@end

@implementation SCRPixelBufferService
- (nonnull instancetype)initWithPlayer:(nonnull AVPlayer *)player delegate:(nonnull id <SCRPixelBufferServiceDelegate>)delegate
{
    if ((self = [super init]))
    {
        self.player = player;
        self.delegate = delegate;
        
        // Setup CADisplayLink which will callback displayPixelBuffer: at every vsync.
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        [[self displayLink] addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[self displayLink] setPaused:YES];
        
        // Setup AVPlayerItemVideoOutput with the required pixelbuffer attributes.
        NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
        self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
        self.myVideoOutputQueue = dispatch_queue_create("myVideoOutputQueue", DISPATCH_QUEUE_SERIAL);
        [[self videoOutput] setDelegate:self queue:self.myVideoOutputQueue];

        /*
         Sets up player item and adds video output to it.
         The tracks property of an asset is loaded via asynchronous key value loading, to access the preferred transform of a video track used to orientate the video while rendering.
         After adding the video output, we request a notification of media change in order to restart the CADisplayLink.
         */
        
        // Remove video output from old item, if any.
        [[self.player currentItem] removeOutput:self.videoOutput];
        
        AVAsset *asset = [[self.player currentItem] asset];
        
        [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
            NSLog(@"[asset tracksWithMediaType:AVMediaTypeVideo]: %@", [asset tracksWithMediaType:AVMediaTypeVideo]);
            NSLog(@"[asset tracksWithMediaType:AVMediaTypeAudio]: %@", [asset tracksWithMediaType:AVMediaTypeAudio]);
            NSLog(@"[asset statusOfValueForKey:tracks error:nil]: %lu", (long)[asset statusOfValueForKey:@"tracks" error:nil]);
            if ([asset statusOfValueForKey:@"tracks" error:nil] == AVKeyValueStatusLoaded) {
                NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
                if ([tracks count] > 0) {
                    // Choose the first video track.
                    AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
                    [videoTrack loadValuesAsynchronouslyForKeys:@[@"preferredTransform"] completionHandler:^{
                        
                        if ([videoTrack statusOfValueForKey:@"preferredTransform" error:nil] == AVKeyValueStatusLoaded) {
//                            CGAffineTransform preferredTransform = [videoTrack preferredTransform];
                            
                            /*
                             The orientation of the camera while recording affects the orientation of the images received from an AVPlayerItemVideoOutput. Here we compute a rotation that is used to correctly orientate the video.
                             */
//                            self.playerView.preferredRotation = -1 * atan2(preferredTransform.b, preferredTransform.a);
                            
//                            [self addDidPlayToEndTimeNotificationForPlayerItem:item];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[self.player currentItem] addOutput:self.videoOutput];
//                                [self.player replaceCurrentItemWithPlayerItem:item];
                                [self.videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
//                                [self.player play];
                            });
                            
                        }
                        
                    }];
                }
            }
            
        }];

    }
    
    
    return self;
}

#pragma mark - CADisplayLink Callback

- (void)displayLinkCallback:(CADisplayLink *)sender
{
    /*
     The callback gets called once every Vsync.
     Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, and copy the pixel buffer for that time
     This pixel buffer can then be processed and later rendered on screen.
     */
    CMTime outputItemTime = kCMTimeInvalid;
    
    // Calculate the nextVsync time which is when the screen will be refreshed next.
    CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
    
    outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
    
    if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
        CVPixelBufferRef pixelBuffer = NULL;
        pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(serviceGeneratedPixelBuffer:player:)])
        {
            [self.delegate serviceGeneratedPixelBuffer:pixelBuffer player:self.player];
        }
//        [[self playerView] displayPixelBuffer:pixelBuffer];
    }
}

#pragma mark - AVPlayerItemOutputPullDelegate

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
    // Restart display link.
    [[self displayLink] setPaused:NO];
}

@end
