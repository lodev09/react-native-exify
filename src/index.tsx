import Exify from './NativeExify';
import type { ExifTags, ExifyWriteResult } from './types';

export function read(uri: string): Promise<ExifTags | null> {
  return Exify.read(uri) as Promise<ExifTags | null>;
}

export function write(uri: string, tags: ExifTags): Promise<ExifyWriteResult> {
  return Exify.write(uri, tags as Object) as Promise<ExifyWriteResult>;
}

export * from './types';
