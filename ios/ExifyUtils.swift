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

