import Exify from './specs/NativeExifyModule';
import type { ExifTags, ExifyWriteResult } from './types';

/**
 * Read Exif metadata from an image.
 * @param uri Image URI with a scheme (e.g. `file://`, `ph://`, `content://`). Bare file paths are not supported.
 */
export function read(uri: string): Promise<ExifTags | null> {
  return Exify.read(uri) as Promise<ExifTags | null>;
}

/**
 * Write Exif metadata into an image.
 * @param uri Image URI with a scheme (e.g. `file://`, `ph://`, `content://`). Bare file paths are not supported.
 * @param tags Exif tags to write.
 */
export function write(uri: string, tags: ExifTags): Promise<ExifyWriteResult> {
  return Exify.write(uri, tags as Object) as Promise<ExifyWriteResult>;
}

export * from './types';
