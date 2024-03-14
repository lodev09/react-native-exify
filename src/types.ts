/**
 * From Android's ExifInterface Tags
 * Normalized for both IOS and Android
 */
export interface ExifTags {
  SensorLeftBorder?: number
  SensorBottomBorder?: number
  DefaultCropSize?: number
  GPSTrackRef?: string
  GPSSpeedRef?: string
  GPSSpeed?: number
  GPSMapDatum?: string
  GPSLatitudeRef?: string
  GPSLatitude?: number
  GPSDifferential?: number
  GPSDestLatitudeRef?: string
  GPSDestDistanceRef?: string
  GPSHPositioningError?: string
  GPSDestDistance?: number
  GPSDestBearing?: number
  GPSDateStamp?: string
  GPSAltitudeRef?: number
  GPSAltitude?: number
  GPSDestLatitude?: number
  GPSImgDirection?: number
  GPSDOP?: number
  GPSTrack?: number
  GPSVersionID?: string
  GPSLongitude?: number
  GPSDestLongitudeRef?: string
  GPSImgDirectionRef?: string
  GPSProcessingMethod?: string
  GPSMeasureMode?: string
  GPSLongitudeRef?: string
  GPSSatellites?: string
  GPSAreaInformation?: string
  GPSDestBearingRef?: string
  GPSStatus?: string
  GPSTimeStamp?: string
  GPSDestLongitude?: number
  SensorTopBorder?: number
  Copyright?: string
  PreviewImageStart?: number
  SubSecTimeDigitized?: string
  SubSecTime?: string
  SubfileType?: number
  SpectralSensitivity?: string
  SpatialFrequencyResponse?: string
  DNGVersion?: number
  Sharpness?: number
  PixelXDimension?: number
  SceneCaptureType?: number
  ExposureTime?: number
  RelatedSoundFile?: string
  AspectFrame?: number
  Flash?: number
  SceneType?: string
  OECF?: string
  NewSubfileType?: number
  PixelYDimension?: number
  MakerNote?: string
  ShutterSpeedValue?: number
  LightSource?: number
  UserComment?: string
  GainControl?: number
  ISOSpeedRatings?: number[]
  FocalPlaneResolutionUnit?: number
  FocalPlaneXResolution?: number
  YCbCrCoefficients?: number
  FocalLengthIn35mmFilm?: number
  LensMake?: string
  LensModel?: string
  LensSpecification?: number[]
  ISO?: number
  FlashpixVersion?: number[]
  StripOffsets?: number
  SensingMethod?: number
  FlashEnergy?: number
  FocalLength?: number
  FNumber?: number
  MeteringMode?: number
  FocalPlaneYResolution?: number
  ExposureBiasValue?: number
  ExposureProgram?: number
  SubjectDistance?: number
  ThumbnailImageLength?: number
  Compression?: number
  ExposureMode?: number
  ExposureIndex?: number
  WhiteBalance?: number
  DateTimeOriginal?: string
  RowsPerStrip?: number
  DateTimeDigitized?: string
  ExifVersion?: number[]
  Saturation?: number
  CustomRendered?: number
  Contrast?: number
  ComponentsConfiguration?: number[]
  ColorSpace?: number
  SubjectLocation?: number
  ThumbnailImageWidth?: number
  BrightnessValue?: number
  Model?: string
  InteroperabilityIndex?: string
  CompressedBitsPerPixel?: number
  ApertureValue?: number
  DeviceSettingDescription?: string
  JPEGInterchangeFormat?: number
  StripByteCounts?: number
  YCbCrSubSampling?: number
  DigitalZoomRatio?: number
  PreviewImageLength?: number
  YCbCrPositioning?: number
  FileSource?: string
  Artist?: string
  Make?: string
  CFAPattern?: string
  WhitePoint?: number
  SamplesPerPixel?: number
  SubjectArea?: number[]
  JPEGInterchangeFormatLength?: number
  ResolutionUnit?: number
  PrimaryChromaticities?: number
  PlanarConfiguration?: number
  TransferFunction?: number
  SubSecTimeOriginal?: string
  Orientation?: number
  PhotometricInterpretation?: number
  MaxApertureValue?: number
  ImageDescription?: string
  SensorRightBorder?: number
  YResolution?: number
  BitsPerSample?: number
  ImageUniqueID?: string
  DateTime?: string
  ImageWidth?: number
  ReferenceBlackWhite?: number
  ImageLength?: number
  SubjectDistanceRange?: number
  XResolution?: number
  Software?: string
  [key: string]: unknown
}

/**
 * Exify `writeAsync` result data
 */
export interface ExifyWriteResult {
  /**
   * The URI of the image that was written.
   * On IOS: If input URI is an asset, this will be new URI created.
   *
   * This will return exactly the same as the input URI if the input URI is from a local file.
   */
  uri: string
  /**
   * A newly created asset ID on IOS.
   * Writing exif metadata into an asset file will create a new asset file.
   *
   * @platform ios
   */
  assetId?: string
  /**
   * Normalized Exif tags
   */
  tags?: ExifTags
}
