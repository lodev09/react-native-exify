import { useEffect, useRef, useState } from 'react';
import { StyleSheet, View, Pressable, Platform, Linking } from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';
import * as ImagePicker from 'expo-image-picker';
import * as MediaLibrary from 'expo-media-library';
import { Image } from 'expo-image';
import * as Exify from '@lodev09/react-native-exify';
import type { ExifTags } from '@lodev09/react-native-exify';

import { mockPosition, json } from './utils';

export default function App() {
  const cameraRef = useRef<CameraView>(null);
  const [preview, setPreview] = useState<string>();

  const [cameraPermission, requestCameraPermission] = useCameraPermissions();
  const [mediaPermission, requestMediaPermission] =
    MediaLibrary.usePermissions();

  useEffect(() => {
    requestCameraPermission();
    requestMediaPermission();
  }, [requestCameraPermission, requestMediaPermission]);

  const readExif = async (uri: string) => {
    const tags = await Exify.read(uri);
    console.log('readExif:', json(tags));
    return tags;
  };

  const writeExif = async (uri: string) => {
    const [lng, lat] = mockPosition();
    const tags: ExifTags = {
      GPSLatitude: lat,
      GPSLongitude: lng,
      GPSTimeStamp: '10:10:10',
      GPSDateStamp: '2024:10:10',
      UserComment: 'Exif updated via @lodev09/react-native-exify',
    };

    console.log('writeExif:', json(tags));
    const result = await Exify.write(uri, tags);
    console.log('writeExif result:', json(result));

    return result;
  };

  const takePhoto = async () => {
    if (!cameraRef.current) return;

    const photo = await cameraRef.current.takePictureAsync({ exif: false });
    if (!photo) return;

    console.log('takePhoto:', photo.uri);

    const result = await writeExif(photo.uri);
    if (!result) return;

    const asset = await MediaLibrary.createAssetAsync(result.uri);
    console.log('saved asset:', asset.uri);

    setPreview(asset.uri);
    await readExif(asset.uri);
  };

  const openLibrary = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 1,
    });

    if (result.canceled) return;

    const asset = result.assets[0];
    if (!asset) return;

    const uri =
      Platform.OS === 'ios' && asset.assetId
        ? `ph://${asset.assetId}`
        : asset.uri;

    console.log('openLibrary:', uri);
    setPreview(asset.uri);
    await readExif(uri);
  };

  if (!cameraPermission?.granted || !mediaPermission?.granted) {
    return (
      <View style={styles.container}>
        <Pressable
          onPress={() => {
            if (cameraPermission?.canAskAgain) {
              requestCameraPermission();
            } else {
              Linking.openSettings();
            }
          }}
        >
          <Image source={require('../assets/icon.png')} style={styles.icon} />
        </Pressable>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <CameraView ref={cameraRef} style={styles.camera} facing="back" />
      <View style={styles.controls}>
        <Pressable onPress={openLibrary} style={styles.previewButton}>
          {preview && (
            <Image source={{ uri: preview }} style={styles.preview} />
          )}
        </Pressable>
        <Pressable onPress={takePhoto} style={styles.captureButton}>
          <View style={styles.captureInner} />
        </Pressable>
        <View style={styles.spacer} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
    alignItems: 'center',
    justifyContent: 'center',
  },
  icon: {
    width: 80,
    height: 80,
  },
  camera: {
    flex: 1,
    width: '100%',
  },
  controls: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 30,
    paddingVertical: 20,
    paddingBottom: 40,
    backgroundColor: '#000',
    width: '100%',
  },
  previewButton: {
    width: 50,
    height: 50,
    borderRadius: 8,
    backgroundColor: '#333',
    overflow: 'hidden',
  },
  preview: {
    width: 50,
    height: 50,
  },
  captureButton: {
    width: 70,
    height: 70,
    borderRadius: 35,
    borderWidth: 4,
    borderColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
  captureInner: {
    width: 58,
    height: 58,
    borderRadius: 29,
    backgroundColor: '#fff',
  },
  spacer: {
    width: 50,
  },
});
