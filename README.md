# @lodev09/react-native-exify

A simple library to read and write image Exif metadata in React Native.

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
  GPSLatitude: 69.696969,
  GPSLongitude: 69.696969,
  UserComment: 'Someone wrote GPS here!',
}

const result = await writeAsync(uri, newTags)
console.log(result)
```

💡 Note: On IOS, writing exif into an Asset file will duplicate the image.
Try to write to a local file first before saving!

## Contributing
Contributions are welcome!

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.
