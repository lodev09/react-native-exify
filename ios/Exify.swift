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
    // Retrieve local asset ID from full URL we receive from library (prefixed with "ph://")
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

  @objc(readAsync:withResolver:withRejecter:)
  func readAsync(uri: String, resolve: @escaping RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
    // Read exif from PH asset
    if uri.starts(with: "ph://") {
      readFromAsset(uri: uri, resolve: resolve)
    } else {
      readFromFile(uri: uri, resolve: resolve)
    }
  }

  @objc(writeAsync:withExif:withResolver:withRejecter:)
  func writeAsync(uri: String, exif: Dictionary<String, Any>, resolve:RCTPromiseResolveBlock, reject:RCTPromiseRejectBlock) -> Void {
    resolve("Hello world!")
  }
}
