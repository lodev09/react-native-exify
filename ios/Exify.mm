#import "Exify.h"

#pragma mark - Helpers

static PHAsset *getAssetById(NSString *assetId) {
  PHFetchOptions *options = [PHFetchOptions new];
  options.includeHiddenAssets = YES;
  options.includeAllBurstAssets = YES;
  options.fetchLimit = 1;

  PHFetchResult<PHAsset *> *result =
      [PHAsset fetchAssetsWithLocalIdentifiers:@[ assetId ] options:options];
  return result.firstObject;
}

static void addTagEntries(CFStringRef dictionary, NSDictionary *metadata,
                          NSMutableDictionary *tags) {
  NSDictionary *entries = metadata[(__bridge NSString *)dictionary];
  if (entries) {
    [tags addEntriesFromDictionary:entries];
  }
}

static NSDictionary *getExifTags(NSDictionary *metadata) {
  NSMutableDictionary *tags = [NSMutableDictionary new];

  NSString *compressionKey =
      (__bridge NSString *)kCGImageDestinationLossyCompressionQuality;
  for (NSString *key in metadata) {
    id value = metadata[key];
    if (![value isKindOfClass:[NSDictionary class]] &&
        ![key isEqualToString:compressionKey]) {
      tags[key] = value;
    }
  }

  addTagEntries(kCGImagePropertyExifDictionary, metadata, tags);
  addTagEntries(kCGImagePropertyTIFFDictionary, metadata, tags);
  addTagEntries(kCGImagePropertyPNGDictionary, metadata, tags);

  if (@available(iOS 13.0, *)) {
    addTagEntries(kCGImagePropertyHEICSDictionary, metadata, tags);
  }

  // Prefix GPS keys with "GPS"
  NSDictionary *gps =
      metadata[(__bridge NSString *)kCGImagePropertyGPSDictionary];
  if (gps) {
    for (NSString *key in gps) {
      tags[[@"GPS" stringByAppendingString:key]] = gps[key];
    }
  }

  return [tags copy];
}

static NSDictionary *readExifTags(NSURL *url) {
  if (!url)
    return nil;

  CGImageSourceRef source =
      CGImageSourceCreateWithURL((__bridge CFURLRef)url, nil);
  if (!source)
    return nil;

  NSDictionary *metadata =
      (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(
          source, 0, nil);
  CFRelease(source);

  if (!metadata)
    return nil;

  return getExifTags(metadata);
}

/// Returns @{@"metadata": NSDictionary, @"data": NSData} or nil on failure.
static NSDictionary *updateMetadata(NSURL *url, NSDictionary *tags) {
  CGImageSourceRef imageSource =
      CGImageSourceCreateWithURL((__bridge CFURLRef)url, nil);
  if (!imageSource)
    return nil;

  CFStringRef sourceType = CGImageSourceGetType(imageSource);
  if (!sourceType) {
    CFRelease(imageSource);
    return nil;
  }

  CFDictionaryRef props =
      CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil);
  NSMutableDictionary *metadata =
      props ? [NSMutableDictionary
                  dictionaryWithDictionary:(__bridge_transfer NSDictionary *)
                                               props]
            : [NSMutableDictionary new];

  // Merge into Exif dict (filter out GPS-prefixed keys)
  NSMutableDictionary *exifDict = [NSMutableDictionary
      dictionaryWithDictionary:metadata[(__bridge NSString *)
                                            kCGImagePropertyExifDictionary]
                                   ?: @{}];
  for (NSString *key in tags) {
    if (![key hasPrefix:@"GPS"]) {
      exifDict[key] = tags[key];
    }
  }
  metadata[(__bridge NSString *)kCGImagePropertyExifDictionary] = exifDict;

  // Handle GPS tags
  NSMutableDictionary *gpsDict = [NSMutableDictionary
      dictionaryWithDictionary:metadata[(__bridge NSString *)
                                            kCGImagePropertyGPSDictionary]
                                   ?: @{}];

  NSNumber *latitude = tags[@"GPSLatitude"];
  if (latitude) {
    double lat = latitude.doubleValue;
    gpsDict[(__bridge NSString *)kCGImagePropertyGPSLatitude] = @(fabs(lat));
    gpsDict[(__bridge NSString *)kCGImagePropertyGPSLatitudeRef] =
        lat >= 0 ? @"N" : @"S";
  }

  NSNumber *longitude = tags[@"GPSLongitude"];
  if (longitude) {
    double lng = longitude.doubleValue;
    gpsDict[(__bridge NSString *)kCGImagePropertyGPSLongitude] = @(fabs(lng));
    gpsDict[(__bridge NSString *)kCGImagePropertyGPSLongitudeRef] =
        lng >= 0 ? @"E" : @"W";
  }

  NSNumber *altitude = tags[@"GPSAltitude"];
  if (altitude) {
    double alt = altitude.doubleValue;
    gpsDict[(__bridge NSString *)kCGImagePropertyGPSAltitude] = @(fabs(alt));
    gpsDict[(__bridge NSString *)kCGImagePropertyGPSAltitudeRef] =
        @(alt >= 0 ? 0 : 1);
  }

  NSString *gpsDate = tags[@"GPSDateStamp"];
  if (gpsDate) {
    gpsDict[(__bridge NSString *)kCGImagePropertyGPSDateStamp] = gpsDate;
  }

  NSString *gpsTime = tags[@"GPSTimeStamp"];
  if (gpsTime) {
    gpsDict[(__bridge NSString *)kCGImagePropertyGPSTimeStamp] = gpsTime;
  }

  metadata[(__bridge NSString *)kCGImagePropertyGPSDictionary] = gpsDict;
  metadata[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] =
      @(1);

  // Write image with updated metadata
  CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
  if (!cgImage) {
    CFRelease(imageSource);
    return nil;
  }

  NSMutableData *destinationData = [NSMutableData new];
  CGImageDestinationRef destination = CGImageDestinationCreateWithData(
      (__bridge CFMutableDataRef)destinationData, sourceType, 1, nil);

  if (!destination) {
    CGImageRelease(cgImage);
    CFRelease(imageSource);
    return nil;
  }

  CGImageDestinationAddImage(destination, cgImage,
                             (__bridge CFDictionaryRef)metadata);
  CGImageDestinationFinalize(destination);

  CFRelease(destination);
  CGImageRelease(cgImage);
  CFRelease(imageSource);

  return @{@"metadata" : metadata, @"data" : destinationData};
}

#pragma mark - Exify Module

@implementation Exify

- (void)read:(NSString *)uri
     resolve:(RCTPromiseResolveBlock)resolve
      reject:(RCTPromiseRejectBlock)reject {
  if ([uri hasPrefix:@"ph://"]) {
    NSString *assetId = [uri substringFromIndex:5];
    PHAsset *asset = getAssetById(assetId);
    if (!asset) {
      RCTLogWarn(@"Exify: Could not retrieve asset");
      reject(@"Error", @"Could not retrieve asset", nil);
      return;
    }

    PHContentEditingInputRequestOptions *options =
        [PHContentEditingInputRequestOptions new];
    options.networkAccessAllowed = YES;

    [asset requestContentEditingInputWithOptions:options
                               completionHandler:^(
                                   PHContentEditingInput *contentInput,
                                   NSDictionary *info) {
                                 if (!contentInput ||
                                     !contentInput.fullSizeImageURL) {
                                   RCTLogWarn(@"Exify: Could not read asset "
                                               "content");
                                   reject(@"Error",
                                          @"Could not read asset content", nil);
                                   return;
                                 }

                                 NSDictionary *tags = readExifTags(
                                     contentInput.fullSizeImageURL);
                                 if (!tags) {
                                   RCTLogWarn(@"Exify: Could not read metadata "
                                               "from asset");
                                   reject(@"Error",
                                          @"Could not read metadata from asset",
                                          nil);
                                   return;
                                 }

                                 resolve(tags);
                               }];
  } else {
    NSURL *url = [NSURL URLWithString:uri];
    if (!url) {
      RCTLogWarn(@"Exify: Invalid URI: %@", uri);
      reject(@"Error", [NSString stringWithFormat:@"Invalid URI: %@", uri],
             nil);
      return;
    }

    NSDictionary *tags = readExifTags(url);
    if (!tags) {
      RCTLogWarn(@"Exify: Could not read metadata from: %@", uri);
      reject(
          @"Error",
          [NSString stringWithFormat:@"Could not read metadata from: %@", uri],
          nil);
      return;
    }

    resolve(tags);
  }
}

- (void)write:(NSString *)uri
         tags:(NSDictionary *)tags
      resolve:(RCTPromiseResolveBlock)resolve
       reject:(RCTPromiseRejectBlock)reject {
  if ([uri hasPrefix:@"ph://"]) {
    NSString *assetId = [uri substringFromIndex:5];
    PHAsset *asset = getAssetById(assetId);
    if (!asset) {
      reject(@"Error", @"Cannot retrieve asset.", nil);
      return;
    }

    PHContentEditingInputRequestOptions *options =
        [PHContentEditingInputRequestOptions new];
    options.networkAccessAllowed = YES;

    [asset
        requestContentEditingInputWithOptions:options
                            completionHandler:^(
                                PHContentEditingInput *contentInput,
                                NSDictionary *info) {
                              if (!contentInput ||
                                  !contentInput.fullSizeImageURL) {
                                reject(@"Error",
                                       @"Unable to read metadata from asset",
                                       nil);
                                return;
                              }

                              NSDictionary *result = updateMetadata(
                                  contentInput.fullSizeImageURL, tags);
                              if (!result) {
                                reject(@"Error", @"Could not update metadata",
                                       nil);
                                return;
                              }

                              __block NSString *newAssetId = nil;
                              NSError *error = nil;
                              [[PHPhotoLibrary sharedPhotoLibrary]
                                  performChangesAndWait:^{
                                    PHAssetCreationRequest *request =
                                        [PHAssetCreationRequest
                                            creationRequestForAsset];
                                    [request addResourceWithType:
                                                 PHAssetResourceTypePhoto
                                                            data:result[@"data"]
                                                         options:nil];
                                    request.creationDate = [NSDate date];
                                    newAssetId =
                                        request.placeholderForCreatedAsset
                                            .localIdentifier;
                                  }
                                                  error:&error];

                              if (error) {
                                reject(@"Error",
                                       @"Could not save to image file", error);
                                return;
                              }

                              resolve(@{
                                @"uri" : [NSString
                                    stringWithFormat:@"ph://%@", newAssetId],
                                @"assetId" : newAssetId ?: @"",
                                @"tags" : getExifTags(result[@"metadata"]),
                              });
                            }];
  } else {
    NSURL *url = [NSURL URLWithString:uri];
    if (!url) {
      reject(@"Error", @"Invalid URL", nil);
      return;
    }

    NSDictionary *result = updateMetadata(url, tags);
    if (!result) {
      reject(@"Error", @"Could not update metadata", nil);
      return;
    }

    NSError *error = nil;
    [result[@"data"] writeToURL:url options:NSDataWritingAtomic error:&error];
    if (error) {
      reject(@"Error", @"Could not save to image file", error);
      return;
    }

    resolve(@{
      @"uri" : uri,
      @"tags" : getExifTags(result[@"metadata"]),
    });
  }
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeExifySpecJSI>(params);
}

+ (NSString *)moduleName {
  return @"Exify";
}

@end
