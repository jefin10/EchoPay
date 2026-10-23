/**
 * EchoPay palette — deep violet ink, warm cream surfaces, a single yellow
 * "pop" accent. Flat colours only; no gradients.
 */
export const Colors = {
  // Primary — deep violet
  primary: '#3B1F8C',
  primaryDark: '#26145C',
  primaryLight: '#EDE7FB',

  // Accents
  pop: '#FFB800',
  popSoft: '#FFF1C2',
  coral: '#FF5A5F',
  mint: '#10B981',
  sky: '#2563EB',

  // Surfaces
  surfaceLight: '#F5F1E6', // page background
  surface: '#FFFFFF', // cards
  surfaceDim: '#EDE8DA', // input fill
  cardLight: '#FAF7EE',
  backgroundDark: '#15102E',

  // Ink & text
  ink: '#14122B',
  textSecondary: '#6B6883',
  textMuted: '#9B98AE',
  textGrayDark: '#3F3D55',
  white: '#FFFFFF',

  // Status
  success: '#10B981',
  error: '#FF5A5F',
  warning: '#EAA000',
  info: '#2563EB',

  // Lines
  border: '#E0DBCB',
  borderStrong: '#C9C2AC',
  divider: '#E6E1D2',
} as const;

/** `#RRGGBB` + alpha (0–1) → `rgba(...)`. */
export function alpha(hex: string, a: number): string {
  const n = Number.parseInt(hex.slice(1), 16);
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${a})`;
}
