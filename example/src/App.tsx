import { useEffect, useRef, useState } from 'react';
import { StyleSheet, View, Pressable, Linking, Text } from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';

import * as MediaLibrary from 'expo-media-library';
import { Image } from 'expo-image';
import * as Exify from '@lodev09/react-native-exify';
import type { ExifTags } from '@lodev09/react-native-exify';

import { mockPosition, json } from './utils';
import { PromptSheet, type PromptSheetRef } from './components/PromptSheet';
import {
  ImagePickerSheet,
  type ImagePickerSheetRef,
} from './components/ImagePickerSheet';
import { ExifOverlay } from './components/ExifOverlay';

export default function App() {
  const cameraRef = useRef<CameraView>(null);
  const promptRef = useRef<PromptSheetRef>(null);
  const pickerRef = useRef<ImagePickerSheetRef>(null);
  const [preview, setPreview] = useState<string>();
  const [exifTags, setExifTags] = useState<ExifTags | null>(null);
  const [exifUri, setExifUri] = useState<string>();
  const [urlPreview, setUrlPreview] = useState<string>();

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
    setExifUri(uri);
    setExifTags(tags);
    return tags;
  };

  const writeExif = async (uri: string) => {
    const [lng, lat] = mockPosition();
    const tags: ExifTags = {
      GPSLatitude: Math.abs(lat),
      GPSLatitudeRef: lat >= 0 ? 'N' : 'S',
      GPSLongitude: Math.abs(lng),
      GPSLongitudeRef: lng >= 0 ? 'E' : 'W',
      GPSTimeStamp: '10:10:10',
      GPSDateStamp: '2024:10:10',
      GPSDOP: 5.0,
      GPSHPositioningError: '10.0',
      GPSImgDirection: 180.5,
      GPSImgDirectionRef: 'T',
      UserComment: 'Exif updated via @lodev09/react-native-exify',
      Make: 'Exify',
      Model: 'ExifyCamera',
      Software: 'react-native-exify',
      DateTime: '2024:10:10 10:10:10',
    };

    console.log('writeExif:', json(tags));
    const result = await Exify.write(uri, tags);
    console.log('writeExif result:', json(result));

    return result;
  };

  const readWriteRoundTrip = async (uri: string) => {
    const tags = await Exify.read(uri);
    if (!tags) return;

    console.log('roundTrip read:', json(tags));
    const result = await Exify.write(uri, tags);
    console.log('roundTrip write:', json(result));

    const verify = await Exify.read(uri);
    console.log('roundTrip verify:', json(verify));
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
    pickerRef.current?.refresh();
    await readExif(asset.uri);
  };

  const pickImage = async () => {
    const result = await pickerRef.current?.pick();
    if (!result) return null;

    setPreview(result.preview);
    return result.uri;
  };

  const openLibrary = async () => {
    const uri = await pickImage();
    if (!uri) return;

    console.log('openLibrary:', uri);
    await readExif(uri);
  };

  const testRoundTrip = async () => {
    const uri = await pickImage();
    if (!uri) return;

    console.log('testRoundTrip:', uri);
    await readWriteRoundTrip(uri);
  };

  const lastUrlRef = useRef(
    'https://raw.githubusercontent.com/ianare/exif-samples/master/jpg/gps/DSCN0010.jpg'
  );

  const openUrl = async () => {
    const url = await promptRef.current?.prompt(
      'Enter image URL',
      lastUrlRef.current,
      'https://'
    );
    if (!url) return;

    console.log('openUrl:', url);
    lastUrlRef.current = url;
    setUrlPreview(url);
    await readExif(url);
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
      <View style={styles.camera}>
        <View style={styles.cameraPlaceholder}>
          <Text style={styles.cameraIcon}>📷</Text>
          <Text style={styles.cameraLabel}>Camera</Text>
        </View>
        <CameraView
          style={StyleSheet.absoluteFill}
          facing="back"
          ref={cameraRef}
        />
        <ExifOverlay
          uri={exifUri}
          tags={exifTags}
          onClose={() => setExifTags(null)}
        />
      </View>
      <PromptSheet ref={promptRef} />
      <ImagePickerSheet ref={pickerRef} />
      <View style={styles.controls}>
        <Pressable
          onPress={openLibrary}
          onLongPress={testRoundTrip}
          style={styles.sideButton}
        >
          {preview ? (
            <Image source={{ uri: preview }} style={styles.preview} />
          ) : (
            <Text style={styles.buttonIcon}>🏞️</Text>
          )}
        </Pressable>
        <Pressable onPress={takePhoto} style={styles.captureButton}>
          <View style={styles.captureInner} />
        </Pressable>
        <Pressable onPress={openUrl} style={styles.sideButton}>
          {urlPreview ? (
            <Image source={{ uri: urlPreview }} style={styles.preview} />
          ) : (
            <Text style={styles.urlLabel}>URL</Text>
          )}
        </Pressable>
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
  cameraPlaceholder: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#1a1a1a',
  },
  cameraIcon: {
    fontSize: 80,
    marginBottom: 12,
  },
  cameraLabel: {
    color: 'rgba(255, 255, 255, 0.3)',
    fontSize: 15,
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
  sideButton: {
    width: 50,
    height: 50,
    borderRadius: 8,
    backgroundColor: '#333',
    alignItems: 'center',
    justifyContent: 'center',
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
  buttonIcon: {
    fontSize: 24,
  },
  urlLabel: {
    color: '#fff',
    fontSize: 13,
    fontWeight: '600',
  },
});
