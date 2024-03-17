# React Native Exify

[![CI](https://github.com/lodev09/react-native-exify/actions/workflows/ci.yml/badge.svg)](https://github.com/lodev09/react-native-exify/actions/workflows/ci.yml)
![GitHub Release](https://img.shields.io/github/v/release/lodev09/react-native-exify)
![NPM Downloads](https://img.shields.io/npm/dw/%40lodev09%2Freact-native-exify)

A simple library to read and write image Exif metadata in React Native. Inspired from [this thread](https://github.com/mrousavy/react-native-vision-camera/issues/780).

## Features
- Read Exif data from an image
- Write Exif data into an image
- Tags are typed and standardized
- Works with Expo and bare React Native projects

## Installation

```sh
yarn add @lodev09/react-native-exify
```

## Usage

```ts
import { writeAsync, readAsync, ExifTags } from '@lodev09/react-native-exify';
```

### 🧐 Reading Exif
```ts
// ...
const uri = 'file://path/to/image.jpg'

const tags = await readAsync(uri)
console.log(tags)
```

### ✍️ Writing Exif
```ts
const uri = 'file://path/to/image.jpg'
const newTags: ExifTags = {
  GPSLatitude: 69.69,
  GPSLongitude: 69.69,
  UserComment: 'Someone wrote GPS here!',
}

const result = await writeAsync(uri, newTags)
console.log(result.tags)
```

> **Note**:
> On IOS, writing exif into an Asset file will duplicate the image. IOS does not allow writing exif into an Asset file directly.
> If you're getting the photo from a [camera](https://github.com/mrousavy/react-native-vision-camera/), write it into the output file first before saving to the Asset library!

See [example](example) for more detailed usage.

## Contributing
Contributions are welcome!

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.
