import { StyleSheet, View } from 'react-native';

import { AppText, Entrance, Icon, Screen, ScreenHeader } from '@/core/components';
import { useSession } from '@/core/storage/session';
import { alpha, Colors, Type } from '@/core/theme';
import { InfoRow, MenuGroup, ToggleRow } from '@/features/profile/MenuRow';

export default function SecurityScreen() {
  const enabled = useSession((s) => s.flags.biometricEnabled);
  const setFlag = useSession((s) => s.setFlag);

  return (
    <Screen>
      <Entrance>
        <ScreenHeader title="security" />
        <View style={styles.heading}>
          <AppText style={Type.eyebrow()}>security</AppText>
          <AppText style={[Type.heading(30, 800), styles.title]}>{'Security\nSettings.'}</AppText>
        </View>

        <AppText style={[Type.eyebrow(), styles.label]}>authentication</AppText>
        <MenuGroup>
          <ToggleRow
            icon="fingerprint"
            title="Biometric lock"
            subtitle={enabled ? 'Unlock the app and confirm voice actions' : 'App opens and voice actions run without a check'}
            value={enabled}
            onValueChange={(v) => setFlag('biometricEnabled', v)}
          />
        </MenuGroup>

        <AppText style={[Type.eyebrow(), styles.label]}>upi protection</AppText>
        <MenuGroup>
          <InfoRow icon="lock-outline" label="UPI PIN" value="Managed by your bank app" />
          <InfoRow icon="verified-user" label="Voice payments" value="Confirm before sending" />
        </MenuGroup>

        <View style={styles.note}>
          <Icon name="info-outline" size={20} color={Colors.primary} />
          <View style={styles.flex}>
            <AppText style={Type.heading(14)}>Your PIN stays with your bank</AppText>
            <AppText style={[Type.body(13, 500, Colors.textSecondary), styles.noteText]}>
              EchoPay never asks for or stores your UPI PIN. With the biometric lock on, the app asks for your fingerprint,
              face or device PIN on launch and before voice payments.
            </AppText>
          </View>
        </View>
      </Entrance>
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  heading: { marginTop: 22, marginBottom: 10, gap: 6 },
  title: { lineHeight: 34 },
  label: { marginTop: 18, marginBottom: 10 },
  note: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 22,
    padding: 16,
    borderRadius: 16,
    backgroundColor: alpha(Colors.primary, 0.06),
    borderWidth: 1,
    borderColor: alpha(Colors.primary, 0.15),
  },
  noteText: { marginTop: 4, lineHeight: 19 },
});
