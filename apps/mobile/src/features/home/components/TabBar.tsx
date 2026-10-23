import type { BottomTabBarProps } from 'expo-router/js-tabs';
import { StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AppText, Icon, Tap, type IconName } from '@/core/components';
import { alpha, Colors, Type } from '@/core/theme';

const ITEMS: Record<string, { label: string; icon: IconName; activeIcon: IconName }> = {
  home: { label: 'Home', icon: 'home', activeIcon: 'home' },
  profile: { label: 'Profile', icon: 'person-outline', activeIcon: 'person' },
};

/** Floating ink pill: Home · raised voice button · Profile. */
export function TabBar({ state, navigateToTab }: BottomTabBarProps) {
  const insets = useSafeAreaInsets();
  const current = state.routes[state.index]?.name;

  const go = (name: string) => {
    const route = state.routes.find((r) => r.name === name);
    if (route && current !== name) navigateToTab(route.key);
  };

  const navItem = (name: keyof typeof ITEMS) => {
    const item = ITEMS[name];
    const selected = current === name;
    const color = selected ? Colors.pop : alpha(Colors.white, 0.55);
    return (
      <Tap
        key={name}
        scale={0.9}
        onPress={() => go(name)}
        style={styles.item}
        accessibilityRole="tab"
        accessibilityState={{ selected }}
        accessibilityLabel={item.label}>
        <Icon name={selected ? item.activeIcon : item.icon} size={24} color={color} />
        <AppText style={[Type.body(11, selected ? 700 : 500, color), styles.label]}>{item.label}</AppText>
      </Tap>
    );
  };

  return (
    <View style={[styles.wrap, { paddingBottom: Math.max(insets.bottom, 8) + 8 }]}>
      <View style={styles.bar}>
        {navItem('home')}
        <Tap
          scale={0.92}
          onPress={() => go('voice')}
          style={styles.voice}
          accessibilityRole="tab"
          accessibilityState={{ selected: current === 'voice' }}
          accessibilityLabel="Voice assistant">
          <Icon name={current === 'voice' ? 'graphic-eq' : 'mic-none'} size={26} color={Colors.ink} />
        </Tap>
        {navItem('profile')}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { paddingHorizontal: 20, backgroundColor: Colors.surfaceLight },
  bar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.ink,
    borderRadius: 28,
    padding: 8,
  },
  item: { flex: 1, alignItems: 'center', paddingVertical: 10 },
  label: { marginTop: 4, letterSpacing: 0.2 },
  voice: {
    width: 56,
    height: 56,
    marginHorizontal: 12,
    marginVertical: 4,
    borderRadius: 20,
    backgroundColor: Colors.pop,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
