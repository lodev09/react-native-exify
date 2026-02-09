#import "Exify.h"

static NSSet *tiffKeys;

__attribute__((constructor)) static void initTiffKeys(void) {
  tiffKeys = [NSSet
      setWithObjects:@"Make", @"Model", @"Software", @"DateTime", @"Artist",
                     @"Copyright", @"ImageDescription", @"Orientation",
                     @"XResolution", @"YResolution", @"ResolutionUnit",
                     @"Compression", @"PhotometricInterpretation",
                     @"TransferFunction", @"WhitePoint",
                     @"PrimaryChromaticities", @"HostComputer", nil];
}

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

  // Route tags into the correct sub-dictionaries
  NSMutableDictionary *exifDict = [NSMutableDictionary
      dictionaryWithDictionary:metadata[(__bridge NSString *)
                                            kCGImagePropertyExifDictionary]
                                   ?: @{}];
  NSMutableDictionary *tiffDict = [NSMutableDictionary
      dictionaryWithDictionary:metadata[(__bridge NSString *)
                                            kCGImagePropertyTIFFDictionary]
                                   ?: @{}];
  NSMutableDictionary *gpsDict = [NSMutableDictionary
      dictionaryWithDictionary:metadata[(__bridge NSString *)
                                            kCGImagePropertyGPSDictionary]
                                   ?: @{}];

  // Pre-read explicit GPS ref values so coordinate handlers can use them
  NSString *latRef = tags[@"GPSLatitudeRef"];
  NSString *lngRef = tags[@"GPSLongitudeRef"];
  NSNumber *altRef = tags[@"GPSAltitudeRef"];

  for (NSString *key in tags) {
    id value = tags[key];

    if ([key isEqualToString:@"GPSLatitude"]) {
      double lat = [value doubleValue];
      gpsDict[(__bridge NSString *)kCGImagePropertyGPSLatitude] = @(fabs(lat));
      gpsDict[(__bridge NSString *)kCGImagePropertyGPSLatitudeRef] =
          latRef ?: (lat >= 0 ? @"N" : @"S");
    } else if ([key isEqualToString:@"GPSLongitude"]) {
      double lng = [value doubleValue];
      gpsDict[(__bridge NSString *)kCGImagePropertyGPSLongitude] = @(fabs(lng));
      gpsDict[(__bridge NSString *)kCGImagePropertyGPSLongitudeRef] =
          lngRef ?: (lng >= 0 ? @"E" : @"W");
    } else if ([key isEqualToString:@"GPSAltitude"]) {
      double alt = [value doubleValue];
      gpsDict[(__bridge NSString *)kCGImagePropertyGPSAltitude] = @(fabs(alt));
      gpsDict[(__bridge NSString *)kCGImagePropertyGPSAltitudeRef] =
          altRef ?: @(alt >= 0 ? 0 : 1);
    } else if ([key isEqualToString:@"GPSLatitudeRef"] ||
               [key isEqualToString:@"GPSLongitudeRef"] ||
               [key isEqualToString:@"GPSAltitudeRef"]) {
      // Already handled above
    } else if ([key hasPrefix:@"GPS"]) {
      gpsDict[[key substringFromIndex:3]] = value;
    } else if ([tiffKeys containsObject:key]) {
      tiffDict[key] = value;
    } else {
      exifDict[key] = value;
    }
  }

  metadata[(__bridge NSString *)kCGImagePropertyExifDictionary] = exifDict;
  metadata[(__bridge NSString *)kCGImagePropertyTIFFDictionary] = tiffDict;
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
    if ([uri hasPrefix:@"/"] || ![uri containsString:@"://"]) {
      RCTLogWarn(@"Exify: URI must include a scheme (e.g. file://): %@", uri);
      reject(@"Error",
             [NSString stringWithFormat:@"URI must include a scheme (e.g. "
                                        @"file://): %@",
                                        uri],
             nil);
      return;
    }

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
    if ([uri hasPrefix:@"/"] || ![uri containsString:@"://"]) {
      RCTLogWarn(@"Exify: URI must include a scheme (e.g. file://): %@", uri);
      reject(@"Error",
             [NSString stringWithFormat:@"URI must include a scheme (e.g. "
                                        @"file://): %@",
                                        uri],
             nil);
      return;
    }

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
