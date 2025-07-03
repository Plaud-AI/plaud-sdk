//
//  SoundPlusTool.h
//  PenBleSDK
//
//  Created by Kai Lv on 2023/7/13.
//  Copyright © 2023 NiceBuild. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SoundPlusTool : NSObject

-(instancetype) initSounplusGain:(int)gain;

+ (instancetype)shared;

/// Set far field or near field
- (void)setAppProcess:(int)sceneFlag;

/// Set noise reduction amount
- (void) setNoiseFloor:(int)noiseFloor;

/// Set gain
- (void)setPregain:(float)gain;

- (void)processingInt16:(int16_t *)input length:(int)length;

- (NSData*)procressInt16:(int16_t *)input length:(int)length;

- (NSData*)procress:(NSData *)input length:(int)length;

// Process audio file
// Parameters:
//      inputPath: input wav audio file path
//      outputPath: output wav audio file path
- (BOOL)processWavFile:(NSString *)inputPath outputPathinput:(NSString *)outputPath progress:(void (^)(float progress))progressCallback;

@end

NS_ASSUME_NONNULL_END
