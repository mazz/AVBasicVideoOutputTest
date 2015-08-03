//
//  SCRPixelBufferService.h
//  AVBasicVideoOutputTest
//
//  Created by Michael Hanna on 2015-08-02.
//  Copyright (c) 2015 ILS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol SCRPixelBufferServiceDelegate <NSObject>
- (void)serviceGeneratedPixelBuffer:(nonnull CVPixelBufferRef)buffer player:(nonnull AVPlayer *)player;
@end

@interface SCRPixelBufferService : NSObject <AVPlayerItemOutputPullDelegate>
- (nonnull instancetype)initWithPlayer:(nonnull AVPlayer *)player delegate:(nonnull id <SCRPixelBufferServiceDelegate>)delegate;
@end
