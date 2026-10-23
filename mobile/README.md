# EchoPay Mobile (React Native)

The EchoPay mobile app, built with Expo and TypeScript. It talks to the backends started by the root `docker-compose.yml` (Django :8000, Flask :5002, Rasa :5005).

This app replaces the original Flutter client, which is preserved on the `flutter-app` branch.

## Setup

```bash
cd mobile
npm install
cp .env.example .env.local   # set EXPO_PUBLIC_API_HOST to the machine running docker-compose
```

The app uses native modules (speech recognition, biometrics, camera, contacts), so it needs a development build. Expo Go will not work:

```bash
npm run android     # npx expo run:android: builds, installs and starts Metro
npm start           # later runs: just start Metro
```

`npx expo run:android` needs JDK 17+ (`JAVA_HOME`) and the Android SDK (`ANDROID_HOME`).

With the backend in DEBUG mode no SMS is sent. Dev builds show the OTP the backend returns on the verify screen.

## Scripts

| Command | What it does |
|---|---|
| `npm run android` / `npm run ios` | Build and run a development build |
| `npm start` | Start the Metro dev server |
| `npm test` | Jest unit and screen tests |
| `npm run typecheck` | `tsc --noEmit` |
| `npm run lint` | ESLint (expo config) |

## Release APK

```bash
npx eas-cli@latest build --platform android --profile preview      # internal APK
npx eas-cli@latest build --platform android --profile production
```

Set `EXPO_PUBLIC_API_HOST` for the target backend (see `eas.json`). The landing page in `../echopay` downloads `releases/latest/download/app-release.apk`, so upload the build to a GitHub release under that file name.

## Layout

```
src/
  app/                 Expo Router routes (every file is a screen)
    (auth)/            phone → OTP → name entry
    biometric.tsx      unlock gate
    (app)/(tabs)/      home · voice · profile
    (app)/…            balance, history, pay/*, requests, qr-scanner, my-qr, speech, profile/*
  core/                api client, session store, theme, shared components, utils
  features/            per-feature api calls, React Query hooks and components
  models/              typed backend payloads
  __tests__/           Jest tests (unit + rendered route tree with a mocked backend)
```

Navigation is driven by session state. The root layout uses protected stacks: onboarding while logged out, the biometric gate while locked, and the wallet once unlocked. Screens only update the session store.

## Changes from the Flutter app

Bugs fixed during the port:

- **Voice payments work end to end.** The recipient is chosen as UPI ID, then phone, then name. The Flask name regex also matches words like "Send", and the Flutter app picked that over the phone number. Spoken names are now looked up in contacts instead of being sent to the backend as `+91<name>`.
- An amount the regex took from the phone number is dropped, and the amount stays editable in the confirmation sheet.
- Each user gets their own Rasa conversation. The Flutter app shared one `user` sender.
- The biometric lock setting now takes effect.

Placeholders that are now implemented:

- QR scanning from a gallery image
- Sharing and saving the receive QR
- History search
- Money requests by UPI ID

Not changed: the backend still has no authentication, and it accepts any `senderPhone`. That needs fixing on the server.
