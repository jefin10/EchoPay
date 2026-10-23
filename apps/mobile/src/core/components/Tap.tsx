import type { ReactNode } from 'react';
import { Pressable, type PressableProps, type StyleProp, type ViewStyle } from 'react-native';
import Animated, { useAnimatedStyle, useReducedMotion, useSharedValue, withTiming } from 'react-native-reanimated';

import { Motion } from '@/core/theme';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

type TapProps = Omit<PressableProps, 'style' | 'children'> & {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
  /** Scale while pressed. */
  scale?: number;
};

/**
 * A tap target that acknowledges the press: scales down on press-in and
 * snaps back on release (~120ms strong ease-out). Honors reduced motion.
 */
export function Tap({ children, style, scale = 0.97, onPressIn, onPressOut, ...rest }: TapProps) {
  const reduce = useReducedMotion();
  const s = useSharedValue(1);
  const animated = useAnimatedStyle(() => ({ transform: [{ scale: s.get() }] }));
  const to = (v: number) => s.set(withTiming(v, { duration: Motion.press, easing: Motion.out }));

  return (
    <AnimatedPressable
      {...rest}
      onPressIn={(e) => {
        if (!reduce) to(scale);
        onPressIn?.(e);
      }}
      onPressOut={(e) => {
        to(1);
        onPressOut?.(e);
      }}
      style={[style, animated]}>
      {children}
    </AnimatedPressable>
  );
}
