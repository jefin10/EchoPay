import Constants from 'expo-constants';
import { StyleSheet, View } from 'react-native';

import { AppLogo, AppText, Entrance, Screen, ScreenHeader } from '@/core/components';
import { Colors, Type } from '@/core/theme';
import { InfoRow, MenuGroup } from '@/features/profile/MenuRow';

export default function AboutScreen() {
  const version = Constants.expoConfig?.version ?? '1.0.0';
  return (
    <Screen>
      <Entrance>
        <ScreenHeader title="about" />
        <View style={styles.heading}>
          <AppText style={Type.eyebrow()}>about</AppText>
          <AppText style={[Type.heading(30, 800), styles.title]}>{'EchoPay\nApp.'}</AppText>
        </View>

        <View style={styles.brand}>
          <View style={styles.logo}>
            <AppLogo type="icon" width={44} height={44} />
          </View>
          <View>
            <AppText style={Type.heading(20)}>EchoPay</AppText>
            <AppText style={Type.body(13, 500, Colors.textSecondary)}>Version {version}</AppText>
          </View>
        </View>

        <AppText style={[Type.body(14, 500, Colors.textGrayDark), styles.blurb]}>
          Pay with your voice. EchoPay lets you send and receive money just by speaking. Built for speed, designed for
          trust.
        </AppText>

        <MenuGroup>
          <InfoRow label="Version" value={version} />
          <InfoRow label="Platform" value="React Native · Expo" />
          <InfoRow label="License" value="Educational use" />
        </MenuGroup>
      </Entrance>
    </Screen>
  );
}

const styles = StyleSheet.create({
  heading: { marginTop: 22, marginBottom: 22, gap: 6 },
  title: { lineHeight: 34 },
  brand: { flexDirection: 'row', alignItems: 'center', gap: 16 },
  logo: {
    width: 72,
    height: 72,
    borderRadius: 22,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  blurb: { marginVertical: 22, lineHeight: 21 },
});
