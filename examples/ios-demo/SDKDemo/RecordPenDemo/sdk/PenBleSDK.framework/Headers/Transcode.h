//
//  Transcode.h
//  PenBleSDK
//
//  Created by Tiannuotai on 2018/11/12.
//  Copyright © 2018 Tiannuotai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Transcode : NSObject

@property (nonatomic, assign) BOOL isProjectJT;

+ (instancetype _Nonnull)shared;


+ (double)volume:(NSData *)pcmData buff:(short [80*4])buff;
+ (double)volume:(NSData *)pcmData;


/// pcm convert to wav
+ (void)translatePcmFile:(NSString *)pcmPath toWavFile:(NSString *)wavPath withChannels:(uint32_t)channels simpleRate:(uint32_t)simpleRate;

/// Generate wav header information
+ (NSData *)generateWavHeaderWithPcmLen:(uint32_t)pcmLen channels:(uint32_t)channels sampleRate:(uint32_t)sampleRate;

/// Get file crc
+ (uint16_t)getCrc:(NSString *)filePath;
/// Check file crc
+ (BOOL)checkCrc:(uint16_t)crc withFile:(NSString *)filePath;

/**
 Separate dual channel wave file into left and right channel files

 @param wavePath wave file path
 @param leftPath left channel file path
 @param rightPath right channel file path
 @param handle block callback
 */
+ (void)divide:(NSString *)wavePath toLeft:(NSString *)leftPath andRight:(NSString *)rightPath handle:(void(^_Nullable)(void))handle;

/// Get offset address
long calculate(void);


@end

NS_ASSUME_NONNULL_END

