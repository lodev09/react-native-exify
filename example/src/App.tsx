import React, { useEffect, useRef, useState } from 'react'
import {
  Pressable,
  Text,
  TouchableOpacity,
  View,
  type ViewStyle,
  useWindowDimensions,
  StyleSheet,
  type TextStyle,
  type StyleProp,
} from 'react-native'
import { StatusBar } from 'expo-status-bar'
import { Image, type ImageStyle } from 'expo-image'
import {
  CameraView,
  type FlashMode,
  useCameraPermissions,
  useMicrophonePermissions,
} from 'expo-camera/next'
import { isDevice } from 'expo-device'
import { ResizeMode, Video } from 'expo-av'
import { getThumbnailAsync } from 'expo-video-thumbnails'
import { multiply } from 'react-native-exify'

import { delay, mockPosition } from './utils'

const BORDER_RADIUS = 4
const SPACE = 16

const CAPTURE_BUTTON_SIZE = 64
const CAPTURE_WRAPPER_SIZE = CAPTURE_BUTTON_SIZE + SPACE

const SMALL_PREVIEW_SIZE = SPACE * 4
const OVERLAY_COLOR = 'rgba(0, 0, 0, 0.75)'
const OVERLAY_LIGHT_COLOR = 'rgba(0, 0, 0, 0.25)'

const height = (w: number, x: number, y: number) => Math.round(w * (y / x))

interface Preview {
  uri: string
  width: number
  height: number
  thumbnailUri?: string
  isVideo?: boolean
}

// Supported "portrait" Aspect Ratios: 9:16, 3:4
const ASPECT_RATIOS: [number, number][] = [
  [9, 16],
  [3, 4],
]

const App = () => {
  const dimensions = useWindowDimensions()
  const [cameraPermission, requestCameraPermission] = useCameraPermissions()
  const [_, requestMicrophonePermission] = useMicrophonePermissions()

  const [isCameraReady, setIsCameraReady] = useState(false)
  const [[x, y], setAspectRatio] = useState<[number, number]>([3, 4])
  const [preview, setPreview] = useState<Preview>()

  const [isRecording, setIsRecording] = useState(false)

  const [expandedPreview, setExpandedPreview] = useState(false)
  const [flashMode, setFlashMode] = useState<FlashMode>('on')

  const cameraRef = useRef<CameraView>(null)

  const previewWidth = dimensions.width - SPACE * 2
  const previewAspectRatio = preview ? preview.width / preview.height : 0

  const startRecording = async () => {
    try {
      setIsRecording(true)

      // 🐛 Bug?
      // Is there a better way to switch camera modes?
      // Without delaying, record doesn't initialize..
      // most likely because camera isn't available yet after the switch
      await delay(300)

      const video = await cameraRef.current?.recordAsync()

      if (video?.uri) {
        const thumbnail = await getThumbnailAsync(video.uri, {
          quality: 0.5,
        })

        setPreview({
          ...thumbnail,
          uri: video.uri,
          thumbnailUri: thumbnail.uri,
          isVideo: true,
        })
      }
    } catch (e) {
      console.error(e)
    }
  }

  const handleCapturePress = async () => {
    if (isRecording) {
      setIsRecording(false)
      cameraRef.current?.stopRecording()
      return
    }

    const [lng, lat] = mockPosition()

    const locationExif = {
      GPSLatitude: lat,
      GPSLongitude: lng,
      GPSAltitude: 0,
      GPSSpeed: 0,
      GPSTimeStamp: Date.now(),
    }

    try {
      const picture = await cameraRef.current?.takePictureAsync({
        exif: true,
        additionalExif: {
          ...locationExif,
          UserComment: `Bug with expo-camera/next`,
        },
      })

      setPreview(picture)
    } catch (e) {
      console.error(e)
    }
  }

  const expandPreview = () => {
    setExpandedPreview(true)
  }

  const dismissPreview = () => {
    setExpandedPreview(false)
  }

  const $previewStyles: StyleProp<ViewStyle> = [
    $previewContainer,
    {
      width: expandedPreview ? previewWidth : SMALL_PREVIEW_SIZE,
      height: expandedPreview ? previewWidth / previewAspectRatio : SMALL_PREVIEW_SIZE,
    },
  ]

  const $captureButtonStyles: ViewStyle = {
    ...$captureButton,
    backgroundColor: isRecording ? 'red' : 'white',
    width: isRecording ? CAPTURE_BUTTON_SIZE / 2 : CAPTURE_BUTTON_SIZE,
    height: isRecording ? CAPTURE_BUTTON_SIZE / 2 : CAPTURE_BUTTON_SIZE,
    borderRadius: isRecording ? BORDER_RADIUS : CAPTURE_BUTTON_SIZE / 2,
  }

  useEffect(() => {
    ;(async () => {
      await requestCameraPermission()
      await requestMicrophonePermission()
    })()
  }, [requestCameraPermission, requestMicrophonePermission])

  useEffect(() => {
    // Set Camera height based on available screen height
    const ratio = ASPECT_RATIOS.find(([x, y]) => {
      return height(dimensions.width, x, y) < dimensions.height
    }) ?? [3, 4]

    setAspectRatio(ratio ?? [3, 4])
  }, [dimensions.width, dimensions.height])

  useEffect(() => {
    ;(async () => {
      const result = await multiply(3, 7)
      console.log(result)
    })()
  }, [])

  if (!isDevice) {
    return (
      <View style={$container}>
        <Text style={$text}>Only available on your fully paid iPhone!</Text>
      </View>
    )
  }

  return (
    <View style={$container}>
      <StatusBar style="light" />
      {cameraPermission?.granted ? (
        <CameraView
          ref={cameraRef}
          facing="back"
          flash={flashMode}
          // Passing only `video` here will cause expo-haptics to not work
          // We need haptics! :(
          mode={isRecording ? 'video' : 'picture'}
          mute={false} // 🐛 Default `mute=false` doesn't work. Need to set it explicitly to work
          style={[$camera, x && y ? { height: height(dimensions.width, x, y) } : undefined]}
          onCameraReady={() => setIsCameraReady(true)}
        >
          <View style={$controlsContainer}>
            <TouchableOpacity
              style={[$flashControls, { opacity: isRecording ? 0 : 1 }]}
              activeOpacity={0.6}
              onPress={() => setFlashMode(flashMode === 'on' ? 'off' : 'on')}
            >
              <Text style={$text}>FLASH: {flashMode === 'on' ? 'ON' : 'OFF'}</Text>
            </TouchableOpacity>
            <View style={$captureWrapper}>
              <TouchableOpacity
                activeOpacity={0.6}
                style={$captureButtonStyles}
                disabled={!isCameraReady || expandedPreview}
                onPress={handleCapturePress}
                onLongPress={startRecording}
              />
            </View>
          </View>
          {expandedPreview && <View style={$previewOverlay} />}
          {!!preview?.uri && (
            <View style={$previewStyles}>
              {expandedPreview ? (
                <>
                  {preview.isVideo ? (
                    <Video
                      source={{ uri: preview.uri }}
                      shouldPlay
                      style={$previewSource}
                      useNativeControls
                      resizeMode={ResizeMode.CONTAIN}
                    />
                  ) : (
                    <Image source={{ uri: preview.uri }} style={$previewSource} />
                  )}
                  <TouchableOpacity
                    style={$dimissPreview}
                    activeOpacity={0.6}
                    onPress={dismissPreview}
                  >
                    <Text style={$text}>Dismiss</Text>
                  </TouchableOpacity>
                </>
              ) : (
                <>
                  <Image
                    source={{ uri: preview.thumbnailUri ?? preview.uri }}
                    style={$previewSource}
                  />
                  <Pressable style={$previewIconOverlay} onPress={expandPreview}>
                    {preview.isVideo && <Text style={$previewIcon}>🎬</Text>}
                  </Pressable>
                </>
              )}
            </View>
          )}
        </CameraView>
      ) : (
        <Text style={$text}>⚠️ We need access to your Camera!</Text>
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
  bottom: SPACE,
  width: '100%',
}

const $flashControls: ViewStyle = {
  alignSelf: 'center',
  paddingHorizontal: 8,
  paddingVertical: 4,
  backgroundColor: OVERLAY_COLOR,
  borderRadius: BORDER_RADIUS,
  marginBottom: SPACE * 2,
}

const $previewOverlay: ViewStyle = {
  ...StyleSheet.absoluteFillObject,
  backgroundColor: OVERLAY_COLOR,
}

const $text: TextStyle = {
  color: '#ffffff',
  fontWeight: 'bold',
}

const $camera: ViewStyle = {
  width: '100%',
  height: '100%',
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

const $previewContainer: ViewStyle = {
  position: 'absolute',
  top: SPACE,
  right: SPACE,
  borderWidth: 2,
  borderColor: '#ffffff',
}

const $previewSource: ImageStyle = {
  width: '100%',
  height: '100%',
}

const $previewIconOverlay: ViewStyle = {
  ...StyleSheet.absoluteFillObject,
  alignItems: 'center',
  justifyContent: 'center',
  backgroundColor: OVERLAY_LIGHT_COLOR,
}

const $previewIcon: TextStyle = {
  fontSize: 28,
}

const $dimissPreview: ViewStyle = {
  position: 'absolute',
  right: SPACE,
  top: SPACE,
  backgroundColor: OVERLAY_COLOR,
  borderRadius: BORDER_RADIUS,
  paddingHorizontal: SPACE,
  paddingVertical: SPACE / 2,
  zIndex: 1,
}

export default App
