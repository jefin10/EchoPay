import { Stack } from 'expo-router';

import { Colors } from '@/core/theme';

export const unstable_settings = { anchor: 'phone' };

export default function AuthLayout() {
  return <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: Colors.surfaceLight } }} />;
}
