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

func getMetadata(from url: URL?) -> [String: Any]? {
  guard let url, let sourceImage = CGImageSourceCreateWithURL(url as CFURL, nil),
        let metadata = CGImageSourceCopyPropertiesAtIndex(sourceImage, 0, nil) as? [String: Any] else {
    return nil
  }
  
  return metadata
}

func getMutableExif(metadata: NSDictionary) -> NSMutableDictionary {
  let mutableMetadata = NSMutableDictionary(dictionary: metadata)

  if let gps = mutableMetadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
    for (gpsKey, gpsValue) in gps {
      mutableMetadata["GPS" + gpsKey] = gpsValue
    }
  }

  return mutableMetadata
}

func getOrientation(from orientation: UIImage.Orientation) -> Int {
  switch orientation {
  case .left:
    return 90
  case .right:
    return -90
  case .down:
    return 180
  default:
    return 0
  }
}

func updateMetadata(url: URL?, exif: [String: Any], completionHandler: @escaping ([String: Any]?, Data?) -> Void) -> Void {
  guard let url,
        let uiImage = UIImage(contentsOfFile: url.path),
        var metadata = getMetadata(from: url),
        let exifDict = metadata[kCGImagePropertyExifDictionary as String] as? NSDictionary,
        let sourceCGImageRef = uiImage.cgImage,
        let sourceData = uiImage.jpegData(compressionQuality: 1.0) as CFData?,
        let sourceCGImageSourceRef = CGImageSourceCreateWithData(sourceData, nil),
        let sourceMetadata = CGImageSourceCopyPropertiesAtIndex(sourceCGImageSourceRef, 0, nil) else {
    return
  }
  
  // Create mutable exif metadata
  let mutableExif = getMutableExif(metadata: exifDict)
  mutableExif.addEntries(from: ["Orientation": getOrientation(from: uiImage.imageOrientation)])
  
  // Append exif data
  mutableExif.addEntries(from: exif)
  
  // Update GPS exif data
  var gpsDict = [String: Any]()

  if let latitude = exif["GPSLatitude"] as? Double {
    gpsDict[kCGImagePropertyGPSLatitude as String] = abs(latitude)
    gpsDict[kCGImagePropertyGPSLatitudeRef as String] = latitude >= 0 ? "N" : "S"
  }

  if let longitude = exif["GPSLongitude"] as? Double {
    gpsDict[kCGImagePropertyGPSLongitude as String] = abs(longitude)
    gpsDict[kCGImagePropertyGPSLongitudeRef as String] = longitude >= 0 ? "E" : "W"
  }

  if let altitude = exif["GPSAltitude"] as? Double {
    gpsDict[kCGImagePropertyGPSAltitude as String] = abs(altitude)
    gpsDict[kCGImagePropertyGPSAltitudeRef as String] = altitude >= 0 ? 0 : 1
  }

  if metadata[kCGImagePropertyGPSDictionary as String] == nil {
    metadata[kCGImagePropertyGPSDictionary as String] = gpsDict
  } else {
    if let metadataGpsDict = metadata[kCGImagePropertyGPSDictionary as String] as? NSMutableDictionary {
      metadataGpsDict.addEntries(from: gpsDict)
    }
  }
  
  metadata[kCGImagePropertyExifDictionary as String] = mutableExif
  
  let updatedMetadata = NSMutableDictionary(dictionary: sourceMetadata)

  for (key, value) in metadata {
    updatedMetadata[key] = value
  }

  updatedMetadata.setObject(NSNumber(value: 1), forKey: kCGImageDestinationLossyCompressionQuality as NSString)
  let processedImageData = NSMutableData()

  guard let sourceType = CGImageSourceGetType(sourceCGImageSourceRef) else {
    return
  }

  guard let destinationCGImageRef =
    CGImageDestinationCreateWithData(processedImageData, sourceType, 1, nil) else {
    return
  }

  CGImageDestinationAddImage(destinationCGImageRef, sourceCGImageRef, updatedMetadata as CFDictionary)
  let data = CGImageDestinationFinalize(destinationCGImageRef) ? processedImageData as Data : nil
  
  completionHandler(metadata, data)
}
