//
//  JXOggPlayer.h
//  PenBleSDK
//
//  Created by TNT on 2021/5/31.
//  Copyright © 2021 TianNuoTai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JXOggPlayerDelegate <NSObject>

/// Playback status change
- (void)onStateChanged:(BOOL)isPlaying;
/// Playback progress (seconds)
- (void)onPlayingLocation:(double)seconds;

@end

/// Class for directly playing recorder ogg files
@interface JXOggPlayer : NSObject

@property (nonatomic, weak) id<JXOggPlayerDelegate>    delegate;
@property (nonatomic, assign, readonly) BOOL isPrepared;
/// File path, do not operate directly
@property (nonatomic, strong, readonly) NSString *filePath;
/// Total file size
@property (nonatomic, assign, readonly) NSInteger fileSize;
/// Total recording duration (in milliseconds)
@property (nonatomic, assign, readonly) NSInteger totalMillsec;
/// Current recording playback progress (in milliseconds)
@property (nonatomic, assign, readonly) NSInteger curMillsec;

+ (instancetype)shared;

/// Set ogg file path and audio channels
/// @param oggPath ogg file path
/// @param channel number of channels
- (void)setOggPath:(NSString *)oggPath withChannel:(int)channel;

/// Set opus file path and audio channels
/// @param opusPath opus pure audio undecoded data file path
/// @param channel number of channels
- (void)setOpusPath:(NSString *)opusPath withChannel:(int)channel;

/// Set pcm file path and audio channels
/// @param pcmPath pcm data file path
/// @param channel number of channels
- (void)setPCMPath:(NSString *)pcmPath withChannel:(int)channel;

/// Whether to enable noise reduction and gain (mono only)
- (void)openNsAgc:(BOOL)open;

/// Whether to enable Soundplus noise reduction
- (void)openSoundPlusNs:(BOOL)open;

/// Set far field or near field
- (void)setSoundPlusAppProcess:(int)sceneFlag;

/// Set Soundplus noise reduction amount
- (void)setSoundPlusNoiseReduction: (int)gain;

/// Set noise reduction gain
- (void)setSoundPlusPreGain: (float)gain;

/// Start playback
- (void)play;

/// Set playback speed
/// @param rate playback rate
- (void)setPlayRate:(Float32)rate;
/// Jump to certain position; since it will clear audio queue, need to manually resume playback after jumping
/// @param seconds unit: seconds
- (void)seekTo:(NSTimeInterval)seconds;

/// Jump to certain position; since it will clear audio queue, need to manually resume playback after jumping
/// @param millSec unit: milliseconds
- (void)seekToMillSec:(NSTimeInterval)millSec;

/// Pause playback
- (void)pause;
/// Stop playback
- (void)stop;
/// Whether currently playing
- (BOOL)isPlaying;


@end

NS_ASSUME_NONNULL_END
