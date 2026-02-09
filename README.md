# React Native Exify

[![CI](https://github.com/lodev09/react-native-exify/actions/workflows/ci.yml/badge.svg)](https://github.com/lodev09/react-native-exify/actions/workflows/ci.yml)
![NPM Downloads](https://img.shields.io/npm/dw/%40lodev09%2Freact-native-exify)

A simple library to read and write image Exif metadata for your React Native Apps. 🏷️

<img alt="@lodev09/react-native-exify" src="preview.gif" width="400" />

## Features

* Read Exif data from an image
* Write Exif data into an image
* Tags are typed and standardized
* Works with Expo and bare React Native projects
* Supports New Architecture (Turbo Module)

## Installation

```sh
yarn add @lodev09/react-native-exify
```

## Usage

```tsx
import * as Exify from '@lodev09/react-native-exify';
```

### Reading Exif 🔍

```tsx
const uri = 'file://path/to/image.jpg'

const tags = await Exify.read(uri)
console.log(tags)
```

> [!IMPORTANT]
> The `uri` must include a scheme (e.g. `file://`, `ph://`, `content://`). Bare file paths like `/var/mobile/.../image.jpg` are not supported and will throw an error.

> [!NOTE]
> On Android 10+, GPS data is redacted from `content://` URIs by default. The library automatically requests `ACCESS_MEDIA_LOCATION` at runtime to access unredacted location data. Your app must have media read access (`READ_MEDIA_IMAGES` or `READ_EXTERNAL_STORAGE`) granted first.
> If you're already using a library like [`expo-media-library`](https://docs.expo.dev/versions/latest/sdk/media-library/) that grants `ACCESS_MEDIA_LOCATION`, exify will use the existing grant.

### Writing Exif ✍️

```tsx
import type { ExifTags } from '@lodev09/react-native-exify';

const uri = 'file://path/to/image.jpg'
const newTags: ExifTags = {
  GPSLatitude: 69.69,
  GPSLongitude: 69.69,
  UserComment: 'Someone wrote GPS here!',
}

const result = await Exify.write(uri, newTags)
console.log(result.tags)
```

> [!NOTE]
> On iOS, writing exif into an Asset file will duplicate the image. iOS does not allow writing exif into an Asset file directly.
> If you're getting the photo from a [camera](https://docs.expo.dev/versions/latest/sdk/camera/), write it into the output file first before saving to the Asset library!

## Example

See [example](example) for more detailed usage.

### Built with True Sheet

The example app uses [@lodev09/react-native-true-sheet](https://github.com/lodev09/react-native-true-sheet) for the image picker UI. Check it out!

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

[MIT](LICENSE)

---

Made with ❤️ by [@lodev09](http://linkedin.com/in/lodev09/)
