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

func addTagEntries(from dictionary: CFString, metadata: NSDictionary, to tags: NSMutableDictionary) -> Void {
  if let entries = metadata[dictionary] as? [String: Any] {
    tags.addEntries(from: entries)
  }
}

func getTags(from metadata: NSDictionary) -> [String: Any] {
  let tags: NSMutableDictionary = [:]
  
  // Add root non-dictionary properties
  for (key, value) in metadata {
    if value as? [String: Any] == nil {
      tags[key] = value
    }
  }
  
  // Append all {Exif} properties
  addTagEntries(from: kCGImagePropertyExifDictionary, metadata: metadata, to: tags)
  
  // Prefix {GPS} dictionary with "GPS"
  if let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
    for (key, value) in gps {
      tags["GPS" + key] = value
    }
  }
  
  // Include tags from formats
  addTagEntries(from: kCGImagePropertyTIFFDictionary, metadata: metadata, to: tags)
  addTagEntries(from: kCGImagePropertyPNGDictionary, metadata: metadata, to: tags)
  addTagEntries(from: kCGImagePropertyHEICSDictionary, metadata: metadata, to: tags)
  
  return tags as! [String: Any]
}

func getMetadata(from url: URL?) -> NSMutableDictionary {
  guard let url, let sourceImage = CGImageSourceCreateWithURL(url as CFURL, nil),
        let metadataDict = CGImageSourceCopyPropertiesAtIndex(sourceImage, 0, nil) else {
    return [:]
  }
  
  return NSMutableDictionary(dictionary: metadataDict)
}

func updateMetadata(url: URL, with tags: [String: Any], completionHanlder: (NSDictionary?, Data?) -> Void) -> Void {
  let metadata = getMetadata(from: url)

  // Append additional Exif data
  let exifDict = metadata[kCGImagePropertyExifDictionary as String] as? NSMutableDictionary
  exifDict!.addEntries(from: tags)
  
  // Handle GPS Tags
  var gpsDict = [String: Any]()

  if let latitude = tags["GPSLatitude"] as? Double {
    gpsDict[kCGImagePropertyGPSLatitude as String] = abs(latitude)
    gpsDict[kCGImagePropertyGPSLatitudeRef as String] = latitude >= 0 ? "N" : "S"
  }

  if let longitude = tags["GPSLongitude"] as? Double {
    gpsDict[kCGImagePropertyGPSLongitude as String] = abs(longitude)
    gpsDict[kCGImagePropertyGPSLongitudeRef as String] = longitude >= 0 ? "E" : "W"
  }

  if let altitude = tags["GPSAltitude"] as? Double {
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
  
  metadata.setObject(NSNumber(value: 1), forKey: kCGImageDestinationLossyCompressionQuality as NSString)
  
  let destinationData = NSMutableData()

  guard let uiImage = UIImage(contentsOfFile: url.path),
    let sourceData = uiImage.jpegData(compressionQuality: 1.0) as CFData?,
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
