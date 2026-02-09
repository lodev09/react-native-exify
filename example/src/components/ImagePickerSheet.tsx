import {
  forwardRef,
  useCallback,
  useImperativeHandle,
  useRef,
  useState,
} from 'react';
import {
  FlatList,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
  type ListRenderItemInfo,
} from 'react-native';
import * as MediaLibrary from 'expo-media-library';
import { Image } from 'expo-image';
import { TrueSheet } from '@lodev09/react-native-true-sheet';

const NUM_COLUMNS = 3;
const GAP = 2;
const PAGE_SIZE = 60;

export interface ImagePickerResult {
  uri: string;
  preview: string;
}

export interface ImagePickerSheetRef {
  pick: () => Promise<ImagePickerResult | null>;
  refresh: () => void;
}

export const ImagePickerSheet = forwardRef<ImagePickerSheetRef>(
  (_props, ref) => {
    const sheetRef = useRef<TrueSheet>(null);
    const resolveRef = useRef<
      ((result: ImagePickerResult | null) => void) | null
    >(null);

    const [assets, setAssets] = useState<MediaLibrary.Asset[]>([]);
    const [endCursor, setEndCursor] = useState<string>();
    const [hasMore, setHasMore] = useState(true);

    const { width } = useWindowDimensions();
    const itemSize = (width - GAP * (NUM_COLUMNS - 1)) / NUM_COLUMNS;

    const loadAssets = useCallback(async (after?: string) => {
      const result = await MediaLibrary.getAssetsAsync({
        first: PAGE_SIZE,
        after,
        mediaType: MediaLibrary.MediaType.photo,
        sortBy: [[MediaLibrary.SortBy.creationTime, false]],
      });

      setAssets((prev) =>
        after ? [...prev, ...result.assets] : result.assets
      );
      setEndCursor(result.endCursor);
      setHasMore(result.hasNextPage);
    }, []);

    const loadMore = useCallback(() => {
      if (hasMore && endCursor) {
        loadAssets(endCursor);
      }
    }, [hasMore, endCursor, loadAssets]);

    useImperativeHandle(ref, () => ({
      pick: () => {
        loadAssets();
        return new Promise<ImagePickerResult | null>((resolve) => {
          resolveRef.current = resolve;
          sheetRef.current?.present();
        });
      },
      refresh: () => loadAssets(),
    }));

    const getAssetUri = useCallback((asset: MediaLibrary.Asset) => {
      if (Platform.OS === 'ios') {
        return `ph://${asset.id}`;
      }
      return asset.uri;
    }, []);

    const handleSelect = useCallback(
      (asset: MediaLibrary.Asset) => {
        const uri = getAssetUri(asset);
        resolveRef.current?.({ uri, preview: asset.uri });
        resolveRef.current = null;
        sheetRef.current?.dismiss();
      },
      [getAssetUri]
    );

    const handleDismiss = useCallback(() => {
      resolveRef.current?.(null);
      resolveRef.current = null;
    }, []);

    const renderItem = useCallback(
      ({ item }: ListRenderItemInfo<MediaLibrary.Asset>) => (
        <Pressable
          onPress={() => handleSelect(item)}
          style={[styles.item, { width: itemSize, height: itemSize }]}
        >
          <Image
            source={{ uri: item.uri }}
            style={styles.image}
            recyclingKey={item.id}
          />
        </Pressable>
      ),
      [handleSelect, itemSize]
    );

    const header = useCallback(
      () => (
        <View style={styles.header}>
          <Text style={styles.title}>Recents</Text>
          <Pressable
            style={styles.closeButton}
            onPress={() => sheetRef.current?.dismiss()}
          >
            <View style={styles.closeIcon}>
              <Text style={styles.closeIconText}>✕</Text>
            </View>
          </Pressable>
        </View>
      ),
      []
    );

    return (
      <TrueSheet
        ref={sheetRef}
        detents={[0.6, 1]}
        scrollable
        cornerRadius={14}
        backgroundColor="#1c1c1e"
        onDidDismiss={handleDismiss}
        header={header}
      >
        <FlatList
          data={assets}
          renderItem={renderItem}
          keyExtractor={keyExtractor}
          numColumns={NUM_COLUMNS}
          columnWrapperStyle={styles.row}
          onEndReached={loadMore}
          onEndReachedThreshold={0.5}
        />
      </TrueSheet>
    );
  }
);

const keyExtractor = (item: MediaLibrary.Asset) => item.id;

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 14,
    paddingBottom: 10,
  },
  title: {
    color: '#fff',
    fontSize: 17,
    fontWeight: '600',
  },
  closeButton: {
    padding: 4,
  },
  closeIcon: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(255, 255, 255, 0.15)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  closeIconText: {
    color: 'rgba(255, 255, 255, 0.6)',
    fontSize: 13,
    fontWeight: '600',
  },
  row: {
    gap: GAP,
  },
  item: {
    overflow: 'hidden',
  },
  image: {
    flex: 1,
  },
});
