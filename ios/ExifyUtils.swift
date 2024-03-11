import Photos

func getAssetBy(id: String?) -> PHAsset? {
  if let id {
    return getAssetsBy(assetIds: [id]).firstObject
  }

  return nil
}

func getAssetsBy(assetIds: [String]) -> PHFetchResult<PHAsset> {
  let options = PHFetchOptions()

  options.includeHiddenAssets = true
  options.includeAllBurstAssets = true
  options.fetchLimit = assetIds.count

  return PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: options)
}

func updateExif(metadata: NSDictionary, with additionalExif: [String: Any]) -> NSMutableDictionary {
  let mutableMetadata = NSMutableDictionary(dictionary: metadata)
  mutableMetadata.addEntries(from: additionalExif)

  if let gps = mutableMetadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
    for (gpsKey, gpsValue) in gps {
      mutableMetadata["GPS" + gpsKey] = gpsValue
    }
  }

  return mutableMetadata
}

func getUpdatedData(from image: UIImage, with metadata: [String: Any], quality: Float) -> Data? {
  guard let sourceCGImageRef = image.cgImage,
  let sourceData = image.jpegData(compressionQuality: 1.0) as CFData?,
  let sourceCGImageSourceRef = CGImageSourceCreateWithData(sourceData, nil),
    let sourceMetadata = CGImageSourceCopyPropertiesAtIndex(sourceCGImageSourceRef, 0, nil) else {
    return nil
  }

  let updatedMetadata = NSMutableDictionary(dictionary: sourceMetadata)

  for (key, value) in metadata {
    updatedMetadata[key] = value
  }

  updatedMetadata.setObject(NSNumber(value: quality), forKey: kCGImageDestinationLossyCompressionQuality as NSString)
  let processedImageData = NSMutableData()

  guard let sourceType = CGImageSourceGetType(sourceCGImageSourceRef) else {
    return nil
  }

  guard let destinationCGImageRef =
    CGImageDestinationCreateWithData(processedImageData, sourceType, 1, nil) else {
    return nil
  }

  CGImageDestinationAddImage(destinationCGImageRef, sourceCGImageRef, updatedMetadata)

  if CGImageDestinationFinalize(destinationCGImageRef) {
    return processedImageData as Data
  }

  CGImageDestinationAddImage(destinationCGImageRef, sourceCGImageRef, updatedMetadata as CFDictionary)
  return CGImageDestinationFinalize(destinationCGImageRef) ? processedImageData as Data : nil
}
