# Imperial Tomb — Lăng Mộ Không Tên

A playable, original Flutter point-and-click escape-room mini-game in Vietnamese. Inspired by **genre mechanics** in IzumiArtisan's Rime, Garden and Haven, but with entirely original story, illustrations, code, clues and solutions.

## Playable prototype
- Four connected scenes: Tiền Điện, Tàng Thư, Tinh Điện, Thủy Môn
- Inspectable hotspots, inventory selection and item-use interactions
- Three linked puzzles (symbols, a 3-digit ledger lock and a star mechanism)
- Three endings (bad, ordinary and true), plus clue notebook and two-tier hints
- Autosave/continue via shared_preferences, full offline play
- Scalable original art drawn by Flutter CustomPainter
- Automated state / endings tests and GitHub Actions checks

This is a **vertical slice**, not a finished store-release game. Scene art is stylized vector concept art; it should later be replaced with professionally illustrated scenes while retaining hotspot IDs.

## Run

Install Flutter SDK and the Android/iOS tooling. Then run:

    flutter create --project-name imperial_tomb --platforms=android,ios .
    flutter pub get
    flutter run

Generated platform runner directories are not committed yet. The command above generates them locally. For iOS builds, macOS with Xcode/signing is required; Android devices need USB debugging enabled.

Check code:

    flutter analyze
    flutter test

Build Android debug APK:

    flutter build apk --debug

The game has no backend, account system, tracking, ads or online assets.

## Controls
Tap the golden labeled hotspots, navigate using the room strip, and tap an inventory object before tapping its target in the scene. Journal replays discovered evidence; the lightbulb provides increasingly direct hints. Progress saves automatically.

## Story and solutions
- [Original narrative / reveal ladder / clue dependencies](docs/STORY.md)
- [Full walkthrough and three endings](docs/WALKTHROUGH.md)
- [Pure game engine](lib/game/game_session.dart)
- [Room definitions](lib/game/content.dart)
- [Original room art](lib/ui/tomb_art.dart)

## Next improvements
1. Original detailed static art for 8–12 additional viewpoints
2. Close-up panels, drag/combine inventory, sound and puzzle animations
3. Accessibility, localization and device integration testing
4. Release signing, privacy/store metadata and optional monetization

Source code and original game content are reserved to the repository owner until they select a license.
