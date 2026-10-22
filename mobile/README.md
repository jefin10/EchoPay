# EchoPay Mobile (React Native)

Expo + TypeScript port of the Flutter app in `../App`. It talks to the same backends started by the root `docker-compose.yml` (Django :8000, Flask :5002, Rasa :5005).

## Setup

```bash
cd mobile
npm install
cp .env.example .env.local   # set EXPO_PUBLIC_API_HOST to the machine running docker-compose
```

The app uses native modules (speech recognition, biometrics, camera, contacts), so it needs a development build — Expo Go will not work:

```bash
npm run android     # npx expo run:android — builds and installs a dev client
npm start           # later runs: just start Metro
```

## Scripts

| Command | What it does |
|---|---|
| `npm run android` / `npm run ios` | Build and run a development build |
| `npm start` | Start the Metro dev server |
| `npm test` | Jest unit tests |
| `npm run typecheck` | `tsc --noEmit` |
| `npm run lint` | ESLint (expo config) |

## Layout

```
src/
  app/        Expo Router routes (every file is a screen)
  core/       api client, session storage, theme, shared components
  features/   per-feature api + React Query hooks
  models/     typed backend payloads
```
