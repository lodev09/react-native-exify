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

func getMetadata(from url: URL?) -> NSMutableDictionary {
  guard let url, let sourceImage = CGImageSourceCreateWithURL(url as CFURL, nil),
        let metadataDict = CGImageSourceCopyPropertiesAtIndex(sourceImage, 0, nil) else {
    return [:]
  }
  
  return NSMutableDictionary(dictionary: metadataDict)
}

func updateMetadata(url: URL, with newMetadata: [String: Any], completionHanlder: (CFDictionary?, Data?) -> Void) -> Void {
  guard var uiImage = UIImage(contentsOfFile: url.path) else {
    return
  }
  
  let metadata = getMetadata(from: url)
  
  // Append additional Exif data
  if let exif = newMetadata["Exif"] as? [String: Any] {
    let exifDict = metadata[kCGImagePropertyExifDictionary as String] as? NSMutableDictionary
    exifDict!.addEntries(from: exif)
  }
  
  // Handle GPS
  if let gps = newMetadata["GPS"] as? [String: Any] {
    var gpsDict = [String: Any]()

    if let latitude = gps["GPSLatitude"] as? Double {
      gpsDict[kCGImagePropertyGPSLatitude as String] = abs(latitude)
      gpsDict[kCGImagePropertyGPSLatitudeRef as String] = latitude >= 0 ? "N" : "S"
    }

    if let longitude = gps["GPSLongitude"] as? Double {
      gpsDict[kCGImagePropertyGPSLongitude as String] = abs(longitude)
      gpsDict[kCGImagePropertyGPSLongitudeRef as String] = longitude >= 0 ? "E" : "W"
    }

    if let altitude = gps["GPSAltitude"] as? Double {
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
  }
  
  metadata.setObject(NSNumber(value: 1), forKey: kCGImageDestinationLossyCompressionQuality as NSString)
  
  let destinationData = NSMutableData()

  guard let sourceData = uiImage.jpegData(compressionQuality: 1.0) as CFData?,
    let cgImageSource = CGImageSourceCreateWithData(sourceData, nil),
    let sourceType = CGImageSourceGetType(cgImageSource),
    let destination = CGImageDestinationCreateWithData(destinationData, sourceType, 1, nil) else {
    return
  }

  CGImageDestinationAddImage(destination, uiImage.cgImage!, metadata)
  if CGImageDestinationFinalize(destination) {
    completionHanlder(metadata, destinationData as Data)
  }
}
