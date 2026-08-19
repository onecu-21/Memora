# Memora

Memora is a local-first Flutter study application for Android, Windows, macOS, and Linux. Students preserve a PDF or photographed handout, organize it by subject/unit, generate grounded notes and atomic concepts, and use a continuous adaptive review loop. There is intentionally no web or iOS client.

> **The original handout is the source of truth. OCR and AI analysis are derived data.**

> **Local data is the primary working copy. Cloud infrastructure provides synchronization and backup.**

## Architecture

`lib/core` contains immutable source-analysis/concept models, validation, answer grading, duplicate prevention, and the pure adaptive scheduler. `lib/storage` owns the versioned SQLite database, private application-data document tree, and secure secret abstraction. `lib/ai` defines provider-independent contracts and Gemini, OpenAI, Anthropic Claude, and deterministic Mock adapters. `lib/sync` implements resilient queue delivery and confirmed-edit conflict behavior. `lib/main.dart` is the responsive Material 3 app with Home, Library, Review, and Settings.

The Cloudflare Worker in `backend/` implements generic email delivery, hashed six-digit OTPs, native-app sessions, owner-scoped D1 records, private R2 objects, and account deletion. D1 SQL is isolated in the migration/repository boundary; R2 keys are server-derived.

## Local data and offline operation

At runtime Memora opens `<application-data>/memora.db` and stores originals under `<application-data>/documents/{documentId}/original`. File signatures, size, and opaque IDs are validated; originals are never removed by failed analysis. SQLite transactions record attempts and an outbox entry before any network call. Existing library, notes, concepts, correction, and review operations therefore remain available offline. API keys and session tokens use platform secure credential storage and are never included in synchronized settings.

## AI and mock mode

Gemini is the default intended provider. Model names are configured per task, allowing multimodal analysis and inexpensive quiz generation to differ. OpenAI and Claude use the same validated domain boundary. Enter BYO keys in Settings; keys remain only in secure device storage. The deterministic Mock provider requires no key or network and produces analysis, handwriting, highlights, notes, eight grounded democracy concepts, and varied questions. Automated tests only use Mock.

Real-provider credentials are not bundled. Production deployments should complete the provider HTTP request configuration for the selected vendor and verify current model identifiers.

## Authentication, mail, and sync

Authentication is email OTP only. Codes are cryptographically random, six digits, SHA-256 hashed with a server secret, single-use, valid for ten minutes, attempt-limited, replaced on resend, and cooldown-limited. Responses do not contain codes or reveal account existence. Configure `MAIL_API_URL`, `MAIL_API_KEY`, and `MAIL_FROM`; the adapter sends a vendor-neutral JSON template request.

D1 holds structured per-user entities and R2 holds private originals/pages. The client updates SQLite first and retries queued changes opportunistically. Timestamp/revision conflict resolution applies to ordinary metadata; a newer remote value cannot silently overwrite a user-confirmed concept and instead produces `CONFLICT`. Account deletion removes D1 entities/sessions and R2 objects without automatically erasing the local working copy.

## Development

Install a stable Flutter SDK (Dart 3.4+), then:

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d linux # or android, windows, macos
```

Platform prerequisites are the Android SDK/JDK for Android, Visual Studio Desktop C++ for Windows, Xcode/CocoaPods for macOS, and GTK 3/CMake/Ninja for Linux. Camera input is Android-only; desktop uses the file picker. Generated platform runner files may be refreshed with `flutter create --platforms=android,windows,macos,linux .` using a compatible Flutter SDK; never add `web` or `ios`.

Backend development:

```sh
cd backend
npm install
npm run check
npm test
npx wrangler d1 migrations apply memora --local
npm run build
```

Set `OTP_SECRET`, mail variables, a D1 binding named `DB`, and private R2 binding `DOCUMENTS` before deployment. Local tests require no production secrets.

## Current MVP limitations

PDF page rasterization and OCR depend on the configured AI provider; Mock supplies deterministic page analysis. Drag-and-drop is not wired beyond the cross-platform picker. External provider requests and live mail delivery require user/server credentials and were not exercised in automated tests. Sync uses a deliberately simple record protocol rather than collaborative merging.

## Automated releases

`.github/workflows/release.yml` builds Android, Linux, and Windows packages. Every push to `main` is serialized and publishes the next numeric `alpha-N` tag as a GitHub prerelease after all three builds pass. Pull requests and pushes to other branches do not trigger the workflow. A stable release can only be started manually with **Run workflow** and is rejected unless its tag matches `vX.Y.Z` exactly. The workflow intentionally does not build macOS.
