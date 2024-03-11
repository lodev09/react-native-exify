import Photos

extension UIImage.Orientation {
  init(_ cgOrientation: CGImagePropertyOrientation) {
    switch cgOrientation {
      case .up: self = .up
      case .upMirrored: self = .upMirrored
      case .down: self = .down
      case .downMirrored: self = .downMirrored
      case .left: self = .left
      case .leftMirrored: self = .leftMirrored
      case .right: self = .right
      case .rightMirrored: self = .rightMirrored
      default: self = .up
    }
  }
}

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

func getExifMetadata(metadata: NSDictionary) -> NSMutableDictionary {
  let mutableMetadata = NSMutableDictionary(dictionary: metadata)

  if let gps = mutableMetadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
    for (gpsKey, gpsValue) in gps {
      mutableMetadata["GPS" + gpsKey] = gpsValue
    }
  }

  return mutableMetadata
}

func getMetadata(from data: CFData?) -> [String: Any]? {
  guard let data, let sourceCGImageSourceRef = CGImageSourceCreateWithData(data, nil),
        let metadata = CGImageSourceCopyPropertiesAtIndex(sourceCGImageSourceRef, 0, nil) as? [String: Any] else {
    return nil
  }
  
  return metadata
}

func updateMetadata(url: URL?, data: [String: Any], completionHandler: @escaping ([String: Any]?, Data?) -> Void) -> Void {
  guard let url,
        var uiImage = UIImage(contentsOfFile: url.path),
        var metadata = getMetadata(from: url),
        let sourceCGImageRef = uiImage.cgImage,
        let sourceData = uiImage.jpegData(compressionQuality: 1.0) as CFData?,
        let sourceCGImageSourceRef = CGImageSourceCreateWithData(sourceData, nil),
        let sourceMetadata = CGImageSourceCopyPropertiesAtIndex(sourceCGImageSourceRef, 0, nil) else {
    return
  }
  
  // Handle Orientation
  if let orientation = data["Orientation"] as? UInt32 {
    let cgOrientation = CGImagePropertyOrientation(rawValue: orientation)
    uiImage = UIImage(cgImage: sourceCGImageRef, scale: 1, orientation: UIImage.Orientation(cgOrientation!))
    
    let orignalMetadata = NSMutableDictionary(dictionary: metadata as NSDictionary)
    
    let newMetadata = getMetadata(from: uiImage.jpegData(compressionQuality: 1.0) as CFData?)!
    orignalMetadata.addEntries(from: newMetadata)

    // Retain Exif info from original metadata
    orignalMetadata[kCGImagePropertyExifDictionary as String] = metadata[kCGImagePropertyExifDictionary as String]
    
    let tiffDict = metadata[kCGImagePropertyTIFFDictionary as String] as? NSDictionary
    let tiffMetadata = NSMutableDictionary(dictionary: tiffDict! )
    tiffMetadata[kCGImagePropertyTIFFOrientation] = orientation
    
    orignalMetadata[kCGImagePropertyTIFFDictionary as String] = tiffMetadata
    orignalMetadata[kCGImagePropertyOrientation as String] = orientation

    // Use new metadata
    metadata = orignalMetadata as! [String: Any]
  }
  
  // Append additional Exif data
  if let exif = data["Exif"] as? [String: Any] {
    let exifDict = metadata[kCGImagePropertyExifDictionary as String] as? NSDictionary

    let exifMetadata = NSMutableDictionary(dictionary: exifDict! )
    exifMetadata.addEntries(from: exif)

    metadata[kCGImagePropertyExifDictionary as String] = exifMetadata
  }
  
  // Update additional GPS exif data
  if let gps = data["GPS"] as? [String: Any] {
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
