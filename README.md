# @lodev09/react-native-exify

A simple library to read and write Exif metadata from images in React Native.

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

// Read exif from image via URI
const tags = await readAsync(uri)
console.log(tags)
```

### ✍️ Writing Exif
```ts
const uri = 'file://path/to/image.jpg'
const newTags: ExifTags = {
  Make: 'Apple',
  Model: 'iPhone 12 Pro Max',
  Software: '14.4.2'
}
const response = await writeAsync(uri, newTags)
```

💡 Note: On IOS, writing exif into an Asset file will duplicate the image.
Try to write to a local file first before saving!

## Contributing
Contributions are welcome!

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.
