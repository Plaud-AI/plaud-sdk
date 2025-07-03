//
//  JXAvcFilePlayer.h
//  PenBleSDK
//
//  Created by TianNuoTai on 2019/5/21.
//  Copyright © 2019 TianNuoTai. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JXAvcFilePlayerDelegate <NSObject>
/// Playback state changed
- (void)onStateChanged:(BOOL)isPlaying;
/// Playback progress (seconds)
- (void)onPlayLocation:(double)seconds;

@end

/// avc/opus file player
/// @deprecated Deprecated, please use JXOggPlayer
@interface JXAvcFilePlayer : NSObject

@property (nonatomic, weak) id<JXAvcFilePlayerDelegate>    delegate;
@property (nonatomic, assign) BOOL isPrepared;
@property (nonatomic, strong) NSString *filePath;   // File path
@property (nonatomic, assign) NSInteger fileSize;   // File size
@property (nonatomic, assign) NSInteger curOffset;  // Current playback file offset

+ (instancetype)shared;
/// Enable noise reduction and gain
- (void)openNsAgc:(BOOL)open;

/// Enable SoundPlus noise reduction
- (void)openSoundPlusNs:(BOOL)open;

/// Set avc file path
- (void)setAudioPath:(NSString *)avcPath numerOfChannel:(int)channels;

/// Start playback
- (void)play;
/// Playback rate
- (void)setPlayRate:(Float32)rate;
/// Seek to position
- (void)seekTo:(NSTimeInterval)seconds;
/// Pause playback
- (void)pause;
/// Stop playback
- (void)stop;
/// Is playing
- (BOOL)isPlaying;
/// Current millisecond value
- (NSInteger)curMillisec;
/// Total duration
- (double)duration;

@end
