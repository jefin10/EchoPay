import MaterialIcons from '@expo/vector-icons/MaterialIcons';
import { QueryClientProvider } from '@tanstack/react-query';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { Toaster } from '@/core/components';
import { queryClient } from '@/core/query-client';
import { selectNeedsUnlock, useSession } from '@/core/storage/session';
import { Colors, fontAssets } from '@/core/theme';

SplashScreen.preventAutoHideAsync();

export const unstable_settings = { anchor: 'index' };

export default function RootLayout() {
  const [fontsLoaded, fontError] = useFonts({ ...fontAssets, ...MaterialIcons.font });
  const ready = fontsLoaded || !!fontError;
  const isLoggedIn = useSession((s) => s.isLoggedIn);
  const needsUnlock = useSession(selectNeedsUnlock);

  useEffect(() => {
    if (ready) SplashScreen.hideAsync();
  }, [ready]);

  if (!ready) return null;

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <QueryClientProvider client={queryClient}>
          <StatusBar style="dark" />
          {/* Guards pick the screen: wallet once unlocked, the biometric gate
              while locked, onboarding when logged out. Flipping session state
              is all a screen needs to do to move between them. */}
          <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: Colors.surfaceLight } }}>
            <Stack.Screen name="index" />
            <Stack.Protected guard={isLoggedIn && !needsUnlock}>
              <Stack.Screen name="(app)" />
            </Stack.Protected>
            <Stack.Protected guard={needsUnlock}>
              <Stack.Screen name="biometric" />
            </Stack.Protected>
            <Stack.Protected guard={!isLoggedIn}>
              <Stack.Screen name="(auth)" />
            </Stack.Protected>
          </Stack>
          <Toaster />
        </QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
