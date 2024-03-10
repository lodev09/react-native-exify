#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(Exify, NSObject)

RCT_EXTERN_METHOD(writeAsync:(NSString*)uri
                 withExif:(NSDictionary*)exif
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
