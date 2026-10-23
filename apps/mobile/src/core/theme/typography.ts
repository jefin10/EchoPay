import { PlusJakartaSans_400Regular } from '@expo-google-fonts/plus-jakarta-sans/400Regular';
import { PlusJakartaSans_500Medium } from '@expo-google-fonts/plus-jakarta-sans/500Medium';
import { PlusJakartaSans_600SemiBold } from '@expo-google-fonts/plus-jakarta-sans/600SemiBold';
import { PlusJakartaSans_700Bold } from '@expo-google-fonts/plus-jakarta-sans/700Bold';
import { PlusJakartaSans_800ExtraBold } from '@expo-google-fonts/plus-jakarta-sans/800ExtraBold';
import { Sora_600SemiBold } from '@expo-google-fonts/sora/600SemiBold';
import { Sora_700Bold } from '@expo-google-fonts/sora/700Bold';
import { Sora_800ExtraBold } from '@expo-google-fonts/sora/800ExtraBold';
import type { TextStyle } from 'react-native';

import { Colors } from './colors';

/**
 * Sora (geometric, heavy) for display text and amounts; Plus Jakarta Sans
 * for body copy. Custom fonts in React Native need one family per weight, so
 * styles pick the family from the weight instead of setting fontWeight.
 */
export const fontAssets = {
  Sora_600SemiBold,
  Sora_700Bold,
  Sora_800ExtraBold,
  PlusJakartaSans_400Regular,
  PlusJakartaSans_500Medium,
  PlusJakartaSans_600SemiBold,
  PlusJakartaSans_700Bold,
  PlusJakartaSans_800ExtraBold,
};

export type Weight = 400 | 500 | 600 | 700 | 800;

const BODY: Record<Weight, string> = {
  400: 'PlusJakartaSans_400Regular',
  500: 'PlusJakartaSans_500Medium',
  600: 'PlusJakartaSans_600SemiBold',
  700: 'PlusJakartaSans_700Bold',
  800: 'PlusJakartaSans_800ExtraBold',
};

const DISPLAY: Record<Weight, string> = {
  400: 'Sora_600SemiBold',
  500: 'Sora_600SemiBold',
  600: 'Sora_600SemiBold',
  700: 'Sora_700Bold',
  800: 'Sora_800ExtraBold',
};

export const Type = {
  /** Body copy (Plus Jakarta Sans). */
  body(size = 14, weight: Weight = 500, color: string = Colors.ink): TextStyle {
    return { fontFamily: BODY[weight], fontSize: size, color };
  },

  /** Headings (Sora). */
  heading(size = 22, weight: Weight = 700, color: string = Colors.ink, letterSpacing = -0.3): TextStyle {
    return { fontFamily: DISPLAY[weight], fontSize: size, color, letterSpacing };
  },

  /** Amounts, balances and other numeric moments (Sora, tight). */
  amount(size = 36, color: string = Colors.ink, weight: Weight = 800): TextStyle {
    return {
      fontFamily: DISPLAY[weight],
      fontSize: size,
      color,
      letterSpacing: -1,
      lineHeight: Math.round(size * 1.15),
    };
  },

  /** Tight uppercase eyebrow / chip label. */
  eyebrow(color: string = Colors.textSecondary, size = 11): TextStyle {
    return {
      fontFamily: BODY[700],
      fontSize: size,
      color,
      letterSpacing: 1.6,
      textTransform: 'uppercase',
    };
  },
};
