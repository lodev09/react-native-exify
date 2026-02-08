# Agent Instructions

## General Rules

1. YOU MUST NOT do builds unless you are told to.
2. YOU MUST NOT commit changes yourself until I explicitly tell you to.
3. YOU MUST NOT create summary documents unless you are told to.
4. YOU MUST NOT add code comments that are obvious.

## Project Overview

`@lodev09/react-native-exify` — React Native Turbo Module that reads and writes Exif metadata from/into images. iOS uses ObjC++ with CGImageSource/Photos framework. Android uses Kotlin with ExifInterface.

## API

```ts
import * as Exify from '@lodev09/react-native-exify';

Exify.read(uri)          // Promise<ExifTags | null>
Exify.write(uri, tags)   // Promise<ExifyWriteResult>
```

## Key Files

- `src/NativeExify.ts` — Turbo Module codegen spec
- `src/index.tsx` — Public API
- `src/types.ts` — ExifTags, ExifyWriteResult
- `ios/Exify.mm` — iOS implementation
- `android/.../ExifyModule.kt` — Android implementation
- `example/` — Expo example app with expo-camera

## Scripts

- `yarn tidy` — typecheck + lint + format + objclint + ktlint
- `yarn clean` — full clean + reinstall + prebuild

### Creating a Pull Request

When creating a PR, use the template from `.github/PULL_REQUEST_TEMPLATE.md`.
