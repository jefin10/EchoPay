import { Children, useEffect, type ReactNode } from 'react';
import type { StyleProp, ViewStyle } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withDelay,
  withTiming,
} from 'react-native-reanimated';

import { Motion } from '@/core/theme';

/**
 * One-shot entrance: fade + rise, plays once on mount. Wrap a screen's body
 * so it doesn't snap in. Honors reduced motion.
 */
export function Entrance({
  children,
  delay = 0,
  distance = 16,
  style,
}: {
  children: ReactNode;
  delay?: number;
  distance?: number;
  style?: StyleProp<ViewStyle>;
}) {
  const reduce = useReducedMotion();
  const t = useSharedValue(reduce ? 1 : 0);

  useEffect(() => {
    if (!reduce) t.set(withDelay(delay, withTiming(1, { duration: Motion.enter, easing: Motion.out })));
  }, [reduce, delay, t]);

  const animated = useAnimatedStyle(() => ({
    opacity: t.get(),
    transform: [{ translateY: (1 - t.get()) * distance }],
  }));

  return <Animated.View style={[style, animated]}>{children}</Animated.View>;
}

/** Children fade + rise in sequence, once, on mount. */
export function Stagger({ children, step = 55, style }: { children: ReactNode; step?: number; style?: StyleProp<ViewStyle> }) {
  return (
    <>
      {Children.toArray(children).map((child, i) => (
        <Entrance key={i} delay={Math.min(i * step, 430)} distance={14} style={style}>
          {child}
        </Entrance>
      ))}
    </>
  );
}
