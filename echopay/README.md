# EchoPay Landing Page

Marketing site for EchoPay, built with Next.js 16, React 19 and Tailwind CSS 4. It introduces the app and links to the latest Android build.

## Development

```bash
npm install
npm run dev      # http://localhost:3000
npm run build
npm run lint
```

The page lives in `app/page.tsx` and shared metadata in `app/layout.tsx`. Logos are in `public/`.

## APK download

The download buttons point to:

```
https://github.com/jefin10/EchoPay/releases/latest/download/app-release.apk
```

Publish each Android build (see `../mobile/README.md`) as a GitHub release asset named `app-release.apk` to keep the link working.
