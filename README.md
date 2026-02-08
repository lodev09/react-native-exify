# React Native Exify

[![CI](https://github.com/lodev09/react-native-exify/actions/workflows/ci.yml/badge.svg)](https://github.com/lodev09/react-native-exify/actions/workflows/ci.yml)
![NPM Downloads](https://img.shields.io/npm/dw/%40lodev09%2Freact-native-exify)

A simple library to read and write image Exif metadata in React Native. Inspired from [this thread](https://github.com/mrousavy/react-native-vision-camera/issues/780).

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

```ts
import * as Exify from '@lodev09/react-native-exify';
```

### Reading Exif
```ts
const uri = 'file://path/to/image.jpg'

const tags = await Exify.read(uri)
console.log(tags)
```

### Writing Exif
```ts
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

> **Note:** On iOS, writing exif into an Asset file will duplicate the image. iOS does not allow writing exif into an Asset file directly.
> If you're getting the photo from a [camera](https://docs.expo.dev/versions/latest/sdk/camera/), write it into the output file first before saving to the Asset library!

See [example](example) for more detailed usage.

## Contributing
Contributions are welcome!

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
