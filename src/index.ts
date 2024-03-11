import { NativeModules, Platform } from 'react-native'
import type { Exif } from './types'

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
 * @param  {string}          uri  the image uri to write
 * @param  {Exif}            exif the exif tags to be written
 * @return {Promise<Exif>}      the full exif tags of the image
 */
export function writeAsync(uri: string, exif: Exif): Promise<Exif | undefined> {
  return Exify.writeAsync(uri, exif)
}

/**
 * Read Exif data from an image file.
 * @param  {string}        uri the image uri to read
 * @return {Promise<Exif>}     the full exif tags of the image
 */
export function readAsync(uri: string): Promise<Exif | undefined> {
  return Exify.readAsync(uri)
}

export * from './types'
