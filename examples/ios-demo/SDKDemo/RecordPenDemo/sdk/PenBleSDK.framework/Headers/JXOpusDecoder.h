//
//  JXOpusDecoder.h
//  PenBleSDK
//
//  Created by Tiannuotai on 2019/8/15.
//  Copyright © 2019 Tiannuotai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JXOpusDecoder : NSObject

/// Initialize decoder
/// @param channels number of channels: 1, 2, 4
- (instancetype)initWithChannels:(int)channels;

/// Decode data
/// @param avcData data, mono packet size is 80, stereo packet size is 160, quad channel is 320
- (nullable NSData *)decode:(NSData *)avcData;

@end

NS_ASSUME_NONNULL_END
