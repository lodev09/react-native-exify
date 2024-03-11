/**
 * Supported Exif tags are typed.
 * Others are optional.
 * @see https://exiftool.org/TagNames/EXIF.html
 */
export interface ExifData {
  /**
   * 1 = Horizontal (normal),
   * 2 = Mirror horizontal,
   * 3 = Rotate 180,
   * 4 = Mirror vertical,
   * 5 = Mirror horizontal and rotate 270 CW,
   * 6 = Rotate 90 CW,
   * 7 = Mirror horizontal and rotate 90 CW,
   * 8 = Rotate 270 CW,
   */
  Orientation?: 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8
  /**
   * Rotation in degrees.
   * 0, 90, -90, 180
   */
  Rotation?: 0 | 90 | -90 | 180
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
