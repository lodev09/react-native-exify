import {
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { Image } from 'expo-image';

import type { ExifTags } from '@lodev09/react-native-exify';

interface ExifOverlayProps {
  uri?: string;
  tags: ExifTags | null;
  onClose: () => void;
}

const formatValue = (value: unknown): string => {
  if (Array.isArray(value)) return value.join(', ');
  if (typeof value === 'number')
    return String(Math.round(value * 1000000) / 1000000);
  return String(value);
};

export const ExifOverlay = ({ uri, tags, onClose }: ExifOverlayProps) => {
  if (!tags) return null;

  const entries = Object.entries(tags).sort(([a], [b]) => a.localeCompare(b));

  return (
    <View style={styles.backdrop}>
      <View style={styles.panel}>
        <View style={styles.header}>
          <Text style={styles.title}>EXIF</Text>
          <View style={styles.headerRight}>
            <Text style={styles.count}>{entries.length} tags</Text>
            <Pressable style={styles.closeButton} onPress={onClose}>
              <View style={styles.closeIcon}>
                <Text style={styles.closeIconText}>✕</Text>
              </View>
            </Pressable>
          </View>
        </View>
        {uri && (
          <Image source={{ uri }} style={styles.preview} contentFit="cover" />
        )}
        {uri && (
          <Text style={styles.uri} numberOfLines={2} selectable>
            {uri}
          </Text>
        )}
        <ScrollView style={styles.scroll} showsVerticalScrollIndicator={false}>
          {entries.map(([key, value]) => (
            <View key={key} style={styles.row}>
              <Text style={styles.key} numberOfLines={1}>
                {key}
              </Text>
              <Text style={styles.value} numberOfLines={2} selectable>
                {formatValue(value)}
              </Text>
            </View>
          ))}
        </ScrollView>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  backdrop: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    padding: 20,
  },
  panel: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.8)',
    borderRadius: 16,
    overflow: 'hidden',
    marginTop: 60,
    marginBottom: 20,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(255, 255, 255, 0.15)',
  },
  title: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '700',
    letterSpacing: 1,
  },
  headerRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  count: {
    color: 'rgba(255, 255, 255, 0.4)',
    fontSize: 13,
  },
  closeButton: {
    padding: 2,
  },
  closeIcon: {
    width: 26,
    height: 26,
    borderRadius: 13,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  closeIconText: {
    color: 'rgba(255, 255, 255, 0.6)',
    fontSize: 12,
    fontWeight: '600',
  },
  preview: {
    height: 120,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  uri: {
    color: 'rgba(255, 255, 255, 0.35)',
    fontSize: 11,
    fontFamily: Platform.select({ ios: 'Menlo', android: 'monospace' }),
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(255, 255, 255, 0.1)',
  },
  scroll: {
    flex: 1,
  },
  row: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(255, 255, 255, 0.06)',
  },
  key: {
    width: 140,
    color: 'rgba(255, 255, 255, 0.5)',
    fontSize: 12,
    fontFamily: Platform.select({ ios: 'Menlo', android: 'monospace' }),
  },
  value: {
    flex: 1,
    color: '#fff',
    fontSize: 12,
    fontFamily: Platform.select({ ios: 'Menlo', android: 'monospace' }),
  },
});
