import React, { useEffect } from 'react'
import { TouchableOpacity, View, type ViewStyle } from 'react-native'
import { StatusBar } from 'expo-status-bar'
import { multiply } from '@lodev09/react-native-exify'

const SPACE = 16

const CAPTURE_BUTTON_SIZE = 64
const CAPTURE_WRAPPER_SIZE = CAPTURE_BUTTON_SIZE + SPACE

const App = () => {
  const $captureButtonStyles: ViewStyle = {
    ...$captureButton,
    backgroundColor: 'white',
    width: CAPTURE_BUTTON_SIZE,
    height: CAPTURE_BUTTON_SIZE,
    borderRadius: CAPTURE_BUTTON_SIZE / 2,
  }

  useEffect(() => {
    ;(async () => {
      const result = await multiply(3, 7)
      console.log(result)
    })()
  }, [])

  return (
    <View style={$container}>
      <StatusBar style="light" />
      <View style={$controlsContainer}>
        <View style={$captureWrapper}>
          <TouchableOpacity
            activeOpacity={0.6}
            style={$captureButtonStyles}
            onPress={() => undefined}
          />
        </View>
      </View>
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

export default App
