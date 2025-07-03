//
//  Mp3Convert.h
//  PenBleSDK
//
//  Created by Tiannuotai on 2019/8/16.
//  Copyright © 2019 Tiannuotai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Mp3Convert : NSObject

+ (instancetype)shared;

//+ (void)jx_swap:(int *)a :(int *)b;
/// Generate sound wave
/// @param avcPath Original file path
/// @param channels Number of channels
/// @param callback Callback with decibel value per second
- (void)generateSoundWave:(NSString *)avcPath
                 channels:(int)channels
                 callback:(void(^)(int second, int secVolume))callback;

/// Generate sound wave for wav file in music mode
/// @param wavPath wav file
/// @param channels Number of channels
/// @param simpleRate Sample rate
/// @param callback Callback with decibel value per second
- (void)generateSoundWave:(NSString *)wavPath
                 channels:(int)channels
               simpleRate:(int)simpleRate
                 callback:(void(^)(int second, int secVolume))callback;

/// Cancel sound wave generation task
- (void)generateSoundWaveCancel;

/// Convert avc to pcm
/// @param avcPath Original file path
/// @param pcmPath Target file path
/// @param channels Number of channels
/// @param ns_agc Whether to apply noise reduction and gain
/// @param callback Progress callback
- (void)convertAvc:(NSString *)avcPath
             toPcm:(NSString *)pcmPath
          channels:(int)channels
            ns_agc:(BOOL)ns_agc
          callback:(void(^)(int64_t curPos))callback;

/// Convert pcm to mp3
/// @param pcmPath pcm file path
/// @param mp3Path mp3 file path
/// @param quality Audio quality (default 7) 2 near-best quality, not too slow; 5 good quality, fast; 7 ok quality, really fast
/// @param channels Number of channels
/// @param callback Progress callback
- (void)convertPcm:(NSString *)pcmPath
             toMp3:(NSString *)mp3Path
           quality:(int)quality
          channels:(int)channels
          callback:(void(^)(int64_t curPos))callback;


/// Convert avc to mp3
/// @param avcPath Original undecoded file path
/// @param mp3Path mp3 file path
/// @param quality mp3 audio quality 2 near-best quality, not too slow; 5 good quality, fast; 7 ok quality, really fast (default 7)
/// @param channels Number of channels
/// @param ns_agc Whether to apply noise reduction and gain (if done on device, no need to do in app)
/// @param callback Progress callback (processed file offset)
- (void)convertAvc:(NSString *)avcPath
             toMp3:(NSString *)mp3Path
           quality:(int)quality
          channels:(int)channels
            ns_agc:(BOOL)ns_agc
          callback:(void(^)(int64_t curPos))callback;

/// Convert ogg to mp3
/// @param oggPath ogg file path
/// @param mp3Path mp3 file path to be generated
/// @param quality mp3 audio quality 2 near-best quality, not too slow; 5 good quality, fast; 7 ok quality, really fast (default 7)
/// @param channels ogg channel count
/// @param ns_agc Whether to apply noise reduction and gain (@see BleDevice)
/// @param callback Progress callback (processed file offset)
- (void)convertOgg:(NSString *)oggPath
             toMp3:(NSString *)mp3Path
           quality:(int)quality
          channals:(int)channels
            ns_agc:(BOOL)ns_agc
          callback:(void(^)(int64_t curPos))callback;


/// Convert avc to wave
/// @param avcPath Original undecoded file path
/// @param wavePath wave file path
/// @param channels Number of channels
/// @param simpleRate Sample rate, 16000 (16k), 48000 (48k)
/// @param ns_agc Whether to apply noise reduction and gain (if done on device, no need to do in app)
/// @param callback Progress callback (processed file offset)
- (void)convertAvc:(NSString *)avcPath
            toWave:(NSString *)wavePath
          channels:(int)channels
        simpleRate:(uint32_t)simpleRate
            ns_agc:(BOOL)ns_agc
          callback:(void(^)(int64_t curPos))callback;

/// Convert avc to noise reduction wave
/// @param avcPath Original undecoded file path
/// @param wavePath wave file path
/// @param channels Number of channels
/// @param simpleRate Sample rate, 16000 (16k), 48000 (48k)
/// @param soundPlus Whether to apply noise reduction and gain (if done on device, no need to do in app)
/// @param callback Progress callback (processed file offset)
- (void)convertAvc:(NSString *)avcPath
            toNoiseReductionWave:(NSString *)wavePath
          channels:(int)channels
        simpleRate:(uint32_t)simpleRate
         soundPlus:(BOOL)soundPlus
noiseReductionGain:(int)gain
          callback:(void(^)(int64_t curPos))callback;


/// Cancel avcToPcm task
- (void)convertAvcToPcmCancel;
/// Cancel PcmToMp3 compression task
- (void)convertPcmToMp3Cancel;
/// Cancel AvcToMp3 compression task
- (void)convertAvcToMp3Cancel;
/// Cancel ogg to mp3 conversion task
- (void)convertOggToMp3Cancel;
/// Cancel AvcToWav compression task
- (void)convertAvcToWavCancel;
/// Cancel AvcToNoiseReductionWav compression task
- (void)convertAvcToNoiseReductionWavCancel;
@end

NS_ASSUME_NONNULL_END
