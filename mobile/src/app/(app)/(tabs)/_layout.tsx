import { Tabs } from 'expo-router/js-tabs';

import { TabBar } from '@/features/home/components/TabBar';

export default function TabsLayout() {
  return (
    <Tabs tabBar={(props) => <TabBar {...props} />} screenOptions={{ headerShown: false, animation: 'fade' }}>
      <Tabs.Screen name="home" />
      <Tabs.Screen name="voice" />
      <Tabs.Screen name="profile" />
    </Tabs>
  );
}
