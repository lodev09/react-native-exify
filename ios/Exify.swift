import PhotosUI

@objc(Exify)
class Exify: NSObject {

  func readFromFile(uri: String, resolve: @escaping RCTPromiseResolveBlock) -> Void {
    if let url = URL(string: uri), let ciImage = CIImage(contentsOf: url) {
      resolve(ciImage.properties)
    } else {
      resolve(nil)
    }
  }

  func readFromAsset(uri: String, resolve: @escaping RCTPromiseResolveBlock) -> Void {
    let assetId = String(uri[uri.index(uri.startIndex, offsetBy: 5)...])
    guard let asset = getAssetBy(id: assetId) else {
      resolve(nil)
      return
    }

    let imageOptions = PHContentEditingInputRequestOptions()
    imageOptions.isNetworkAccessAllowed = true

    asset.requestContentEditingInput(with: imageOptions) { contentInput, info in
      if let url = contentInput?.fullSizeImageURL, let ciImage = CIImage(contentsOf: url) {
        resolve(ciImage.properties)
      } else {
        resolve(nil)
      }
    }
  }
  
  func writeToLocal(uri: String, exif: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
    guard let url = URL(string: uri), let ciImage = CIImage(contentsOf: url) else {
      resolve(nil)
      return
    }
    
    var metadata = ciImage.properties
    
    guard let exifDict = metadata[kCGImagePropertyExifDictionary as String] as? NSDictionary else {
      return
    }
    
    let updatedExif = updateExif(
      metadata: exifDict,
      with: exif
    )
    
    var gpsDict = [String: Any]()

    let gpsLatitude = exif["GPSLatitude"] as? Double
    if let latitude = gpsLatitude {
      gpsDict[kCGImagePropertyGPSLatitude as String] = abs(latitude)
      gpsDict[kCGImagePropertyGPSLatitudeRef as String] = latitude >= 0 ? "N" : "S"
    }

    let gpsLongitude = exif["GPSLongitude"] as? Double
    if let longitude = gpsLongitude {
      gpsDict[kCGImagePropertyGPSLongitude as String] = abs(longitude)
      gpsDict[kCGImagePropertyGPSLongitudeRef as String] = longitude >= 0 ? "E" : "W"
    }

    let gpsAltitude = exif["GPSAltitude"] as? Double
    if let altitude = gpsAltitude {
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
    
    metadata[kCGImagePropertyExifDictionary as String] = updatedExif
    
    do {
      guard let uiImage = UIImage(data: try Data(contentsOf: url)) else {
        reject("Error", "Unable to create image from URI", nil)
        return
      }

      let data = getUpdatedData(
        from: uiImage,
        with: metadata,
        quality: 1
      )
      
      guard let data else {
        reject("Error", "Could not save data", nil)
        return
      }
      
      try data.write(to: url, options: .atomic)
      resolve(metadata)
      
    } catch let error {
      print(error)
    }
  }

  @objc(readAsync:withResolver:withRejecter:)
  func readAsync(uri: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
    if uri.starts(with: "ph://") {
      readFromAsset(uri: uri, resolve: resolve)
    } else {
      readFromFile(uri: uri, resolve: resolve)
    }
  }

  @objc(writeAsync:withExif:withResolver:withRejecter:)
  func writeAsync(uri: String, exif: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
    if uri.starts(with: "ph://") {
      reject("Error", "We don't support ph://, yet", nil)
    } else {
      writeToLocal(uri: uri, exif: exif, resolve: resolve, reject: reject)
    }
  }
}
