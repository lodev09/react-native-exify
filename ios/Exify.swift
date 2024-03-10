import PhotosUI

@objc(Exify)
class Exify: NSObject {

  func readFromFile(uri: String) -> [String: Any]? {
    var properties: [String: Any]?

    if let url = URL(string: uri), let ciImage = CIImage(contentsOf: url) {
      properties = ciImage.properties
    }

    return properties
  }

  func readFromAsset(uri: String) -> [String: Any]? {
    var properties: [String: Any]?

    // Retrieve local asset ID from full URL we receive from library (prefixed with "ph://")
    let assetId = String(uri[uri.index(uri.startIndex, offsetBy: 5)...])

    if let asset = getAssetBy(id: assetId) {
      if asset.mediaType == .image {
        let imageOptions = PHContentEditingInputRequestOptions()
        imageOptions.isNetworkAccessAllowed = true

        asset.requestContentEditingInput(with: imageOptions) { contentInput, info in
          if let url = contentInput?.fullSizeImageURL, let ciImage = CIImage(contentsOf: url) {
            properties = ciImage.properties
          }
        }
      }
    }

    return properties
  }

  @objc(readAsync:withResolver:withRejecter:)
  func readAsync(uri: String, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    var response:Dictionary<String, Any>?

    // Read exif from PH asset
    if uri.starts(with: "ph://") {
      response = readFromAsset(uri: uri)
    } else {
      response = readFromFile(uri: uri)
    }

    if (response != nil) {
      resolve(response)
    } else {
      reject("Error", "Unable to retrieve Exif data from URI. Check your permissions.", nil)
    }
  }

  @objc(writeAsync:withExif:withResolver:withRejecter:)
  func writeAsync(uri: String, exif: Dictionary<String, Any>, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    resolve("Hello world!")
  }
}
