/*
 *
 * Created by Jovanni Lo (@lodev09)
 * Copyright 2024
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import PhotosUI

@objc(Exify)
class Exify: NSObject {
  
  func readExif(uri: String, resolve: @escaping RCTPromiseResolveBlock) -> Void {
    guard let url = URL(string: uri) else {
      resolve(nil)
      return
    }
    
    readExifTags(from: url) { tags in
      resolve(tags)
    }
  }

  func readExif(assetId: String, resolve: @escaping RCTPromiseResolveBlock) -> Void {
    guard let asset = getAssetBy(id: assetId) else {
      resolve(nil)
      return
    }

    let imageOptions = PHContentEditingInputRequestOptions()
    imageOptions.isNetworkAccessAllowed = true

    asset.requestContentEditingInput(with: imageOptions) { contentInput, info in
      guard let url = contentInput?.fullSizeImageURL else {
        resolve(nil)
        return
      }
      
      readExifTags(from: url) { tags in
        resolve(tags)
      }
    }
  }
  
  func writeExif(assetId: String, tags: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
    guard let asset = getAssetBy(id: assetId) else {
      reject("Error", "Cannot retrieve asset.", nil)
      return
    }
    
    let imageOptions = PHContentEditingInputRequestOptions()
    imageOptions.isNetworkAccessAllowed = true
    
    asset.requestContentEditingInput(with: imageOptions) { contentInput, _ in
      guard let contentInput, let url = contentInput.fullSizeImageURL else {
        reject("Error", "Unable to read metadata from asset", nil)
        return
      }
      
      updateMetadata(url: url, with: tags) { metadata, data in
        guard let metadata, let data else {
          reject("Error", "Could not update metadata", nil)
          return
        }
        
        do {
          try PHPhotoLibrary.shared().performChangesAndWait{
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
            request.creationDate = Date()
            
            let assetId = request.placeholderForCreatedAsset!.localIdentifier
            resolve([
              "uri": "ph://\(assetId)",
              "assetId": assetId,
              "tags": getExifTags(from: metadata),
            ])
            
          }
        } catch let error {
          reject("Error", "Could not save to image file", nil)
          print(error)
        }
      }
    }
  }
  
  func writeExif(uri: String, tags: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
    guard let url = URL(string: uri) else {
      reject("Error", "Invalid URL", nil)
      return
    }

    updateMetadata(url: url, with: tags) { metadata, data in
      guard let metadata, let data else {
        reject("Error", "Could not update metadata", nil)
        return
      }
      
      do {
        // Write to the current file
        try data.write(to: url, options: .atomic)

        resolve([
          "uri": uri,
          "assetId": nil,
          "tags": getExifTags(from: metadata),
        ])
        
      } catch let error {
        reject("Error", "Could not save to image file", nil)
        print(error)
      }
    }
  }

  @objc(readAsync:withResolver:withRejecter:)
  func readAsync(uri: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
    if uri.starts(with: "ph://") {
      let assetId = String(uri[uri.index(uri.startIndex, offsetBy: 5)...])
      readExif(assetId: assetId, resolve: resolve)
    } else {
      readExif(uri: uri, resolve: resolve)
    }
  }

  @objc(writeAsync:withExif:withResolver:withRejecter:)
  func writeAsync(uri: String, tags: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
    if uri.starts(with: "ph://") {
      let assetId = String(uri[uri.index(uri.startIndex, offsetBy: 5)...])
      writeExif(assetId: assetId, tags: tags, resolve: resolve, reject: reject)
    } else {
      writeExif(uri: uri, tags: tags, resolve: resolve, reject: reject)
    }
  }
}
