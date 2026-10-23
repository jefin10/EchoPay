import { LinearGradient } from 'expo-linear-gradient';
import { useEffect, useState, type ReactNode } from 'react';
import { StyleSheet, View, type DimensionValue } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';

import { Colors } from '@/core/theme';

/** Flat placeholder block for skeleton loading states. */
export function SkeletonBar({
  width,
  height,
  radius = 6,
  dark = false,
}: {
  width: DimensionValue;
  height: number;
  radius?: number;
  dark?: boolean;
}) {
  return (
    <View
      style={{
        width,
        height,
        borderRadius: radius,
        backgroundColor: dark ? 'rgba(255,255,255,0.14)' : Colors.surfaceDim,
      }}
    />
  );
}

/** Sweeps a soft highlight across its children instead of a spinner. */
export function Shimmer({ children }: { children: ReactNode }) {
  const reduce = useReducedMotion();
  const [width, setWidth] = useState(0);
  const x = useSharedValue(0);

  useEffect(() => {
    if (reduce || width === 0) return;
    x.set(0);
    x.set(withRepeat(withTiming(1, { duration: 1100, easing: Easing.linear }), -1, false));
  }, [reduce, width, x]);

  const sweep = useAnimatedStyle(() => ({
    transform: [{ translateX: -220 + x.get() * (width + 220) }],
  }));

  if (reduce) return <View style={{ opacity: 0.6 }}>{children}</View>;

  return (
    <View onLayout={(e) => setWidth(e.nativeEvent.layout.width)} style={styles.clip}>
      {children}
      <Animated.View pointerEvents="none" style={[StyleSheet.absoluteFill, styles.sweep, sweep]}>
        <LinearGradient
          colors={['rgba(255,255,255,0)', 'rgba(255,255,255,0.45)', 'rgba(255,255,255,0)']}
          start={{ x: 0, y: 0.5 }}
          end={{ x: 1, y: 0.5 }}
          style={styles.gradient}
        />
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  clip: { overflow: 'hidden' },
  sweep: { width: 220 },
  gradient: { flex: 1 },
});
