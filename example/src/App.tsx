import React, { useEffect, useRef, useState } from 'react'
import {
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  type TextStyle,
  type ViewStyle,
} from 'react-native'
import { StatusBar } from 'expo-status-bar'
import * as Exify from '@lodev09/react-native-exify'
import * as ImagePicker from 'expo-image-picker'
import { Image, type ImageStyle } from 'expo-image'
import {
  Camera,
  useCameraDevice,
  useCameraPermission,
  useMicrophonePermission,
} from 'react-native-vision-camera'
import * as MediaLibrary from 'expo-media-library'

// import { mockPosition } from './utils'

const SPACE = 16

const CAPTURE_BUTTON_SIZE = 64
const CAPTURE_WRAPPER_SIZE = CAPTURE_BUTTON_SIZE + SPACE

const App = () => {
  const camera = useRef<Camera>(null)

  const [libraryUri, setLibraryUri] = useState<string | undefined>()

  const cameraPermission = useCameraPermission()
  const microphonePermission = useMicrophonePermission()
  const [mediaLibraryPermission, requestMediaLibraryPermission] = MediaLibrary.usePermissions()

  const device = useCameraDevice('back')

  const readExif = async (uri: string) => {
    const exif = await Exify.readAsync(uri)
    console.log(exif)
  }

  const takePhoto = async () => {
    try {
      const photo = await camera.current?.takePhoto()
      if (photo) {
        const photoUri = `file://${photo.path}`
        await readExif(photoUri)

        // const position = mockPosition()
        // console.log(position)

        // const exif = await Exify.writeAsync(photoUri, {
        //   GPSLatitude: position[1],
        //   GPSLongitude: position[0],
        // })

        // const libraryPermission = await MediaLibrary.requestPermissionsAsync()
        // if (libraryPermission.granted) {
        //   const asset = await MediaLibrary.createAssetAsync(photoUri)
        //   console.log('ASSET URI:', asset.uri)
        //   await readExif(asset.uri)
        // } else {
        //   console.log('LOCAL URI:', photoUri)
        //   await readExif(photoUri)
        // }
      }
    } catch (e) {
      console.error(e)
    }
  }

  const openLibrary = async () => {
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ImagePicker.MediaTypeOptions.All,
        allowsMultipleSelection: true,
        selectionLimit: 1,
      })

      if (!result.canceled) {
        for (const asset of result.assets) {
          if (asset.assetId) {
            const assetInfo = await MediaLibrary.getAssetInfoAsync(asset.assetId)
            await readExif(assetInfo.uri)
          }
        }
      }
    } catch (e) {
      console.error(e)
    }
  }

  useEffect(() => {
    ;(async () => {
      await cameraPermission.requestPermission()
      await microphonePermission.requestPermission()
      await requestMediaLibraryPermission()
    })()
  }, [])

  useEffect(() => {
    ;(async () => {
      if (mediaLibraryPermission?.granted) {
        const result = await MediaLibrary.getAssetsAsync({ first: 1, mediaType: 'photo' })
        if (result.assets.length) {
          setLibraryUri(result.assets[0]?.uri)
        }
      }
    })()
  }, [mediaLibraryPermission])

  if (!device) {
    return (
      <View style={$container}>
        <Text style={$text}>Only available on your fully paid iPhone!</Text>
      </View>
    )
  }

  return (
    <View style={$container}>
      <StatusBar style="light" />
      <Camera photo ref={camera} style={StyleSheet.absoluteFill} device={device} isActive />
      {cameraPermission.hasPermission ? (
        <View style={$controlsContainer}>
          <TouchableOpacity activeOpacity={0.6} onPress={openLibrary} style={$library}>
            <Image source={{ uri: libraryUri }} style={$image} />
          </TouchableOpacity>
          <View style={$captureWrapper}>
            <TouchableOpacity activeOpacity={0.6} style={$captureButton} onPress={takePhoto} />
          </View>
        </View>
      ) : (
        <Text style={$text}>⚠️ We need access to your Camera</Text>
      )}
    </View>
  )
}

const $container: ViewStyle = {
  flex: 1,
  backgroundColor: '#0d0e11',
  alignItems: 'center',
  justifyContent: 'center',
}

const $controlsContainer: ViewStyle = {
  flexDirection: 'row',
  alignItems: 'center',
  justifyContent: 'center',
  position: 'absolute',
  bottom: SPACE * 4,
  width: '100%',
}

const $image: ImageStyle = {
  width: '100%',
  height: '100%',
}

const $library: ImageStyle = {
  position: 'absolute',
  left: SPACE * 2,
  width: SPACE * 3,
  height: SPACE * 3,
  borderRadius: 4,
  marginRight: SPACE,
  borderWidth: 2,
  borderColor: 'white',
}

const $captureWrapper: ViewStyle = {
  alignSelf: 'center',
  height: CAPTURE_WRAPPER_SIZE,
  width: CAPTURE_WRAPPER_SIZE,
  borderRadius: CAPTURE_WRAPPER_SIZE / 2,
  alignItems: 'center',
  justifyContent: 'center',
  borderWidth: 2,
  borderColor: 'white',
}

const $captureButton: ViewStyle = {
  backgroundColor: '#ffffff',
  height: CAPTURE_BUTTON_SIZE,
  width: CAPTURE_BUTTON_SIZE,
  borderRadius: CAPTURE_BUTTON_SIZE / 2,
}

const $text: TextStyle = {
  color: '#ffffff',
  fontWeight: 'bold',
}

export default App
