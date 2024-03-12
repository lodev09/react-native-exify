/**
 * Supported Exif tags are typed.
 * Others are optional.
 * @see https://exiftool.org/TagNames/EXIF.html
 */
export interface ExifData {
  GPS: {
    GPSLongitude?: number
    GPSLatitude?: number
    GPSAltitude?: number
    GPSSpeed?: number
    GPSTimeStamp?: number
    [key: string]: unknown
  }
  Exif: {
    UserComment?: string
    [key: string]: unknown
  }
}

/**
 * Exify `writeAsync` result data
 */
export interface ExifyWriteResult {
  /**
   * The URI of the image that was written.
   * On IOS asset, this will be new URI created.
   */
  uri?: string
  /**
   * Media Library Asset ID
   */
  assetId?: string | null
  /**
   * Raw EXIF data from the platform
   */
  exif?: object
}
