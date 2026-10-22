import type { ReactNode } from 'react';
import { KeyboardAvoidingView, Modal, Platform, Pressable, StyleSheet, View } from 'react-native';
import Animated, { FadeIn, SlideInDown } from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Colors, Motion } from '@/core/theme';

/** Bottom sheet: dimmed backdrop (tap to dismiss), cream panel, drag handle. */
export function Sheet({
  visible,
  onClose,
  children,
  dismissable = true,
}: {
  visible: boolean;
  onClose: () => void;
  children: ReactNode;
  /** Whether tapping the backdrop / back button closes it. */
  dismissable?: boolean;
}) {
  const insets = useSafeAreaInsets();
  return (
    <Modal visible={visible} transparent animationType="none" statusBarTranslucent onRequestClose={dismissable ? onClose : () => {}}>
      <KeyboardAvoidingView style={styles.root} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
        <Animated.View entering={FadeIn.duration(Motion.fast)} style={StyleSheet.absoluteFill}>
          <Pressable
            style={styles.backdrop}
            onPress={dismissable ? onClose : undefined}
            accessibilityLabel="Close"
          />
        </Animated.View>
        <Animated.View
          entering={SlideInDown.duration(Motion.medium).easing(Motion.out)}
          style={[styles.panel, { paddingBottom: Math.max(insets.bottom, 16) + 8 }]}>
          <View style={styles.handle} />
          {children}
        </Animated.View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, justifyContent: 'flex-end' },
  backdrop: { flex: 1, backgroundColor: 'rgba(20,18,43,0.5)' },
  panel: {
    backgroundColor: Colors.surfaceLight,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    paddingHorizontal: 24,
    paddingTop: 12,
  },
  handle: {
    alignSelf: 'center',
    width: 40,
    height: 4,
    borderRadius: 2,
    backgroundColor: Colors.borderStrong,
    marginBottom: 20,
  },
});
