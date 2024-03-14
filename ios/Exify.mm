/*
 *
 * Created by Jovanni Lo (@lodev09)
 * Copyright 2024
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(Exify, NSObject)

RCT_EXTERN_METHOD(readAsync:(NSString*)uri
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(writeAsync:(NSString*)uri
                 withExif:(NSDictionary*)exif
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
