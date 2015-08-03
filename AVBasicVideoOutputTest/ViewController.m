//
//  ViewController.m
//  AVBasicVideoOutputTest
//
//  Created by Michael Hanna on 2015-08-02.
//  Copyright (c) 2015 ILS. All rights reserved.
//

#import "ViewController.h"
#import "SCRPixelBufferService.h"
#import "APLEAGLView.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <SCRPixelBufferServiceDelegate>
@property (strong, nonatomic, nonnull) NSArray *pixelBufferServices;
@property (strong, nonatomic, nonnull) NSArray *assets;
@property (strong, nonatomic, nonnull) NSArray *playerItems;
@property (strong, nonatomic, nonnull) NSArray *players;
@property (weak, nonatomic, nonnull) IBOutlet APLEAGLView *playerView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [[self playerView] setupGL];

    [self setupPlayers];
}

- (void)setupPlayers
{
    NSMutableArray *assets = [NSMutableArray array];
    NSMutableArray *playerItems = [NSMutableArray array];
    NSMutableArray *players = [NSMutableArray array];
    NSMutableArray *pbServices = [NSMutableArray array];
    
    // create the AVURLAssets from the thumbnails
    
    [assets addObject:[AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"01-bodypositionflow-350" ofType:@"m4v"]]]]; // NEVER use URLWithString: will result in AVKeyValueStatusFailed
    
    self.assets = assets;
    
    for (AVURLAsset *asset in self.assets)
    {
        AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:asset];
        [playerItems addObject:item];
        if (item != nil)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerItemDidReachEnd:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:item];
        }
        AVQueuePlayer *p = [AVQueuePlayer queuePlayerWithItems:[NSArray arrayWithObject:item]];
        [players addObject:p];
        
        if ([p respondsToSelector:@selector(setAllowsExternalPlayback:)])
        {
            [p setAllowsExternalPlayback:NO];
        }
        if ([p respondsToSelector:@selector(setUsesExternalPlaybackWhileExternalScreenIsActive:)])
        {
            [p setUsesExternalPlaybackWhileExternalScreenIsActive:NO];
        }
        
        if (p != nil)
        {
            [p setActionAtItemEnd:AVPlayerActionAtItemEndNone];
        }
        [p seekToTime:kCMTimeZero];
        [p play];
        
        [pbServices addObject:[[SCRPixelBufferService alloc] initWithPlayer:p delegate:self]];
    }
    self.playerItems = playerItems;
    self.players = players;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)serviceGeneratedPixelBuffer:(nonnull CVPixelBufferRef)buffer player:(nonnull AVPlayer *)player
{
    //    NSLog(@"buffer: %@ for player: %@", buffer, player);
    NSLog(@"player rate: %f", player.rate);
    [self.playerView displayPixelBuffer:buffer];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    if ([self.playerItems indexOfObjectIdenticalTo:[notification object]] != NSNotFound)
    {
        AVQueuePlayer *qp = [self.players objectAtIndex:[self.playerItems indexOfObjectIdenticalTo:[notification object]]];
        [qp removeAllItems];
        
        AVPlayerItem *p = [notification object];
        [p seekToTime:kCMTimeZero];
        
        [qp insertItem:p afterItem:nil];
    }
}

@end
