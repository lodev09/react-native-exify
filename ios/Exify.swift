@objc(Exify)
class Exify: NSObject {

  @objc(writeAsync:withExif:withResolver:withRejecter:)
  func writeAsync(uri: String, exif: Dictionary<String, Any>, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    resolve("Hello world!")
  }
}
