import React, { useEffect, useRef } from 'react'
import {
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  type TextStyle,
  type ViewStyle,
} from 'react-native'
import { StatusBar } from 'expo-status-bar'
import { multiply } from '@lodev09/react-native-exify'
import {
  Camera,
  useCameraDevice,
  useCameraPermission,
  useMicrophonePermission,
} from 'react-native-vision-camera'
import * as MediaLibrary from 'expo-media-library'

const SPACE = 16

const CAPTURE_BUTTON_SIZE = 64
const CAPTURE_WRAPPER_SIZE = CAPTURE_BUTTON_SIZE + SPACE

const App = () => {
  const camera = useRef<Camera>(null)

  const cameraPermission = useCameraPermission()
  const microphonePermission = useMicrophonePermission()
  const device = useCameraDevice('back')

  const takePhoto = async () => {
    try {
      const photo = await camera.current?.takePhoto()
      if (photo) {
        const photoUri = `file://${photo.path}`
        const libraryPermission = await MediaLibrary.requestPermissionsAsync()
        if (libraryPermission.granted) {
          const asset = await MediaLibrary.createAssetAsync(photoUri)
          console.log('ASSET URI:', asset.uri)
        } else {
          console.log('LOCAL URI:', photoUri)
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
      await MediaLibrary.requestPermissionsAsync()

      const result = await multiply(3, 7)
      console.log(result)
    })()
  }, [])

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
      <Camera photo ref={camera} style={StyleSheet.absoluteFill} device={device} isActive={true} />
      {cameraPermission.hasPermission ? (
        <View style={$controlsContainer}>
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
  position: 'absolute',
  bottom: SPACE * 2,
  width: '100%',
}

const $captureWrapper: ViewStyle = {
  alignSelf: 'center',
  height: CAPTURE_WRAPPER_SIZE,
  width: CAPTURE_WRAPPER_SIZE,
  borderRadius: CAPTURE_WRAPPER_SIZE / 2,
  marginBottom: SPACE * 2,
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
