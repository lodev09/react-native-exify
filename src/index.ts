import { NativeModules, Platform } from 'react-native'
import type { ExifData, ExifyWriteResult } from './types'

const LINKING_ERROR =
  `The package '@lodev09/react-native-exify' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n'

const Exify = NativeModules.Exify
  ? NativeModules.Exify
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR)
        },
      }
    )

/**
 * Write Exif data into an image file.
 * @param  {string}          uri the image uri to write
 * @param  {ExifData}        data the exif tags to be written
 * @return {Promise<ExifyWriteResult>}      the full exif tags of the image
 */
export function writeAsync(uri: string, data: ExifData): Promise<ExifyWriteResult | undefined> {
  return Exify.writeAsync(uri, data)
}

/**
 * Read Exif data from an image file.
 * @param  {string}        uri the image uri to read
 * @return {Promise<object>}     the raw exif tags of the image
 */
export function readAsync(uri: string): Promise<object | undefined> {
  return Exify.readAsync(uri)
}

export * from './types'
