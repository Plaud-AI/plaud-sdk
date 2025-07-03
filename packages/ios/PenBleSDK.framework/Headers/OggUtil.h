//
//  OggUtil.h
//  PenBleSDK
//
//  Created by Tiannuotai on 2019/10/22.
//  Copyright © 2019 Tiannuotai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OggUtil : NSObject

+ (instancetype)shared;

/// Generate sound wave
/// @param oggPath original file path
/// @param channels number of channels
/// @param callback callback, one decibel value per second
- (void)generateSoundWave:(NSString *)oggPath
                 channels:(int)channels
                 callback:(void(^)(int second, int secVolume, int progress))callback;

/// Cancel generate sound wave task
- (void)generateSoundWaveCancel;


///  Package ogg
/// @param avcPath  opus compressed file path
/// @param oggPath  target ogg file path
/// @param cutOut   whether to cut out? (iFlytek's offline recognition claims 5 hours, but it seems to only handle 4 hours 59 minutes 50 seconds)
/// @param channels number of channels (source data channels)
/// @param targetChannels target channels (mono or stereo? stereo can only get mono, speech recognition generally only supports mono; stereo convert to stereo has some issues, poor sound quality)
/// @param ns_agc do noise reduction, gain
/// @param callback  callback
- (void)convertAvc:(NSString *)avcPath
             toOgg:(NSString *)oggPath
            cutOut:(BOOL)cutOut
          channels:(int32_t)channels
    targetChannels:(int32_t)targetChannels
            ns_agc:(BOOL)ns_agc
          callback:(void(^)(int64_t curPos))callback;

/// Cancel transcode task
- (void)convertCancel;

/// Extract pcm pure data
- (void)convertOgg:(NSString *)oggPath
            toOpus:(NSString *)opusPath
          channels:(int32_t)channels
          callback:(void(^)(Boolean completed))callback;

/// Single, dual channel ogg convert to mono ogg
/// @param originPath stereo ogg (must be directly obtained from recording pen, other formats not supported)
/// @param singlePath target mono ogg
/// @param callback progress callback
- (void)convertOgg:(NSString *)originPath
          toSingle:(NSString *)singlePath
          channels:(int32_t)channels
          callback:(void(^)(int64_t curPos))callback;


/// Quad channel ogg convert to mono ogg
/// @param originPath quad channel ogg (must be directly obtained from recording pen, other formats not supported)
/// @param singlePath target mono ogg
/// @param callback progress callback
- (void)convertFourChannelOgg:(NSString *)originPath
                     toSingle:(NSString *)singlePath
                     callback:(void(^)(int64_t curPos))callback;



@end

NS_ASSUME_NONNULL_END
