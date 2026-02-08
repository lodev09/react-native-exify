import {
  forwardRef,
  useImperativeHandle,
  useRef,
  useState,
  useCallback,
  type ComponentRef,
} from 'react';
import { StyleSheet, TextInput, Text, Pressable, View } from 'react-native';
import { TrueSheet } from '@lodev09/react-native-true-sheet';

export interface PromptSheetRef {
  prompt: (
    title: string,
    defaultValue?: string,
    placeholder?: string
  ) => Promise<string | null>;
}

export const PromptSheet = forwardRef<PromptSheetRef>((_props, ref) => {
  const sheetRef = useRef<TrueSheet>(null);
  const inputRef = useRef<ComponentRef<typeof TextInput>>(null);
  const resolveRef = useRef<((value: string | null) => void) | null>(null);

  const [title, setTitle] = useState('');
  const [placeholder, setPlaceholder] = useState('');
  const [value, setValue] = useState('');

  useImperativeHandle(ref, () => ({
    prompt: (promptTitle, defaultValue = '', promptPlaceholder = '') => {
      setTitle(promptTitle);
      setValue(defaultValue);
      setPlaceholder(promptPlaceholder);
      return new Promise<string | null>((resolve) => {
        resolveRef.current = resolve;
        sheetRef.current?.present();
      });
    },
  }));

  const handlePresent = useCallback(() => {
    inputRef.current?.focus();
  }, []);

  const handleSubmit = useCallback(() => {
    resolveRef.current?.(value);
    resolveRef.current = null;
    sheetRef.current?.dismiss();
  }, [value]);

  const handleDismiss = useCallback(() => {
    resolveRef.current?.(null);
    resolveRef.current = null;
  }, []);

  return (
    <TrueSheet
      ref={sheetRef}
      detents={['auto']}
      cornerRadius={16}
      backgroundColor="#1c1c1e"
      grabber={false}
      onDidPresent={handlePresent}
      onDidDismiss={handleDismiss}
    >
      <View style={styles.content}>
        <Text style={styles.title}>{title}</Text>
        <View style={styles.inputContainer}>
          <TextInput
            ref={inputRef}
            style={styles.input}
            value={value}
            onChangeText={setValue}
            placeholder={placeholder}
            placeholderTextColor="#666"
            autoCapitalize="none"
            autoCorrect={false}
            selectionColor="#0a84ff"
            returnKeyType="done"
            onSubmitEditing={handleSubmit}
          />
          {value.length > 0 && (
            <Pressable style={styles.clearButton} onPress={() => setValue('')}>
              <Text style={styles.clearText}>✕</Text>
            </Pressable>
          )}
        </View>
        <View style={styles.buttons}>
          <Pressable
            style={styles.button}
            onPress={() => sheetRef.current?.dismiss()}
          >
            <Text style={styles.cancelText}>Cancel</Text>
          </Pressable>
          <Pressable
            style={[styles.button, styles.submitButton]}
            onPress={handleSubmit}
          >
            <Text style={styles.submitText}>OK</Text>
          </Pressable>
        </View>
      </View>
    </TrueSheet>
  );
});

const styles = StyleSheet.create({
  content: {
    padding: 20,
    paddingBottom: 32,
  },
  title: {
    color: '#fff',
    fontSize: 17,
    fontWeight: '600',
    marginBottom: 16,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#2c2c2e',
    borderRadius: 10,
    marginBottom: 20,
  },
  input: {
    flex: 1,
    color: '#fff',
    fontSize: 15,
    padding: 12,
  },
  clearButton: {
    padding: 10,
  },
  clearText: {
    color: '#666',
    fontSize: 14,
  },
  buttons: {
    flexDirection: 'row',
    gap: 10,
  },
  button: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    borderRadius: 10,
    backgroundColor: '#2c2c2e',
  },
  cancelText: {
    color: '#999',
    fontSize: 15,
    fontWeight: '600',
  },
  submitButton: {
    backgroundColor: '#0a84ff',
  },
  submitText: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '600',
  },
});
