import { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated, { FadeInDown, FadeOutDown } from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { create } from 'zustand';

import { Colors, Type } from '@/core/theme';

import { AppText } from './AppText';
import { Icon } from './Icon';

type ToastKind = 'info' | 'success' | 'error';

interface ToastState {
  id: number;
  message: string | null;
  kind: ToastKind;
  show(message: string, kind?: ToastKind): void;
  hide(): void;
}

const useToastStore = create<ToastState>()((set) => ({
  id: 0,
  message: null,
  kind: 'info',
  show: (message, kind = 'info') => set((s) => ({ id: s.id + 1, message, kind })),
  hide: () => set({ message: null }),
}));

/** Show a floating snackbar-style message. Callable from anywhere. */
export const toast = (message: string, kind: ToastKind = 'info') => useToastStore.getState().show(message, kind);

const ICONS = { info: 'info-outline', success: 'check-circle', error: 'error-outline' } as const;
const TINT = { info: Colors.white, success: Colors.mint, error: Colors.coral };

/** Mount once near the root. */
export function Toaster() {
  const { id, message, kind, hide } = useToastStore();
  const insets = useSafeAreaInsets();

  useEffect(() => {
    if (!message) return;
    const timer = setTimeout(hide, 2800);
    return () => clearTimeout(timer);
  }, [id, message, hide]);

  if (!message) return null;
  return (
    <View pointerEvents="box-none" style={[styles.host, { bottom: insets.bottom + 96 }]}>
      <Animated.View
        key={id}
        entering={FadeInDown.duration(220)}
        exiting={FadeOutDown.duration(180)}
        style={styles.toast}
        accessibilityLiveRegion="polite">
        <Icon name={ICONS[kind]} size={18} color={TINT[kind]} />
        <AppText style={[Type.body(14, 600, Colors.white), styles.text]}>{message}</AppText>
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  host: { position: 'absolute', left: 16, right: 16 },
  toast: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: Colors.ink,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  text: { flex: 1 },
});
