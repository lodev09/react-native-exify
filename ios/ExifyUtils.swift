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

func getExifMetadata(metadata: NSDictionary) -> NSMutableDictionary {
  let mutableMetadata = NSMutableDictionary(dictionary: metadata)

  if let gps = mutableMetadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
    for (gpsKey, gpsValue) in gps {
      mutableMetadata["GPS" + gpsKey] = gpsValue
    }
  }

  return mutableMetadata
}

func getMetadata(from url: URL?) -> NSMutableDictionary? {
  guard let url, let sourceImage = CGImageSourceCreateWithURL(url as CFURL, nil),
        let metadataDict = CGImageSourceCopyPropertiesAtIndex(sourceImage, 0, nil) else {
    return nil
  }
  
  return NSMutableDictionary(dictionary: metadataDict)
}

func updateMetadata(url: URL, with newMetadata: [String: Any], completionHanlder: @escaping (CFDictionary?, Data?) -> Void) -> Void {
  guard var uiImage = UIImage(contentsOfFile: url.path),
    let imageMetadata = getMetadata(from: url) else {
    return
  }
  
  // Handle Orientation
  if let orientation = newMetadata["Orientation"] as? Int {
    let cgOrientation = UIImage.Orientation(rawValue: orientation)
    
    // Mutate image with new orientation
    uiImage = UIImage(cgImage: uiImage.cgImage!, scale: 1, orientation: cgOrientation!)
    
    imageMetadata[kCGImagePropertyOrientation as String] = cgOrientation?.rawValue
    if let tiff = imageMetadata[kCGImagePropertyTIFFDictionary as String] as? NSMutableDictionary {
      tiff[kCGImagePropertyTIFFOrientation as String] = cgOrientation?.rawValue
    }
  }
  
  // Append additional Exif data
  if let exif = newMetadata["Exif"] as? [String: Any] {
    let exifDict = imageMetadata[kCGImagePropertyExifDictionary as String] as? NSMutableDictionary
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

    if imageMetadata[kCGImagePropertyGPSDictionary as String] == nil {
      imageMetadata[kCGImagePropertyGPSDictionary as String] = gpsDict
    } else {
      if let metadataGpsDict = imageMetadata[kCGImagePropertyGPSDictionary as String] as? NSMutableDictionary {
        metadataGpsDict.addEntries(from: gpsDict)
      }
    }
  }
  
  print(kCGImageDestinationLossyCompressionQuality)
  // imageMetadata.setObject(NSNumber(value: 1), forKey: kCGImageDestinationLossyCompressionQuality as NSString)
  
  let destinationData = NSMutableData()

  guard let sourceData = uiImage.jpegData(compressionQuality: 1.0) as CFData?,
    let cgImageSource = CGImageSourceCreateWithData(sourceData, nil),
    let sourceType = CGImageSourceGetType(cgImageSource),
    let destination = CGImageDestinationCreateWithData(destinationData, sourceType, 1, nil) else {
    return
  }

  CGImageDestinationAddImage(destination, uiImage.cgImage!, imageMetadata)
  if CGImageDestinationFinalize(destination) {
    completionHanlder(imageMetadata, destinationData as Data)
  }
}
