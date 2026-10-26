# Art direction and validation — 0.2

## Finished assets

Original illustrations were created using the built-in **image_gen** tool and encoded as WebP at quality 90. Room backgrounds are 1024 × 1536; dedicated detail views are 1536 × 1024. Source prompts are in [art-prompts.json](art-prompts.json). No images or solutions from IzumiArtisan are distributed.

| File in `assets/rooms/` | Role / visible state |
| --- | --- |
| `vestibule.webp` | Limestone antechamber, light shaft, oath stele and bronze lock |
| `vestibule_taken.webp` | Oil lamp removed from pedestal |
| `archive.webp` | Bamboo ledgers, soot mural, letter compartment and lacquer chest |
| `archive_open.webp` | Chest open with empty lining |
| `courtyard.webp` | Open-air well court, lotus carving, rope bench and dry spouts |
| `courtyard_taken.webp` | Rope and hook removed after assembly / retrieval |
| `observatory.webp` | Inclined bronze orrery, wall map, tarnished mirror and reflector stand |
| `observatory_taken.webp` | Mirror removed from wall bracket |
| `workshop.webp` | Engineer plan, counterweight cabinet and pump |
| `floodgate.webp` | Main sluice, empty auxiliary spindle and service tunnel |
| `floodgate_safe.webp` | Installed wheel and lowered, diverted water |
| `closeup_glyph.webp` | New frontal camera on the three-disc stone lock |
| `closeup_well.webp` | Downward camera revealing the tin on a ledge inside the well |
| `closeup_pump.webp` | Maintenance cover removed, exposing the pipe mechanism |

All other closeups crop their room art around the **same normalized coordinate used by the touch target**. The room viewport preserves its 2:3 aspect ratio. In landscape, room/closeup and information/inventory use separate columns so targets stay usable. Support controls are outside the art and cannot obscure hotspots.

The illustrations provide material, lighting and location. Mandatory symbols, labels, dials, pipe connections, evidence names and solution feedback are rendered by Flutter. Decorative engraving is not a hidden code. Partial independent changes (for example taking rope before assembling the hook, or installing a mirror) are represented by closeup text, inventory and persistent control state; this is a static-background game, not a fully animated environment.

## Offline fonts and rights

`assets/fonts/` includes Roboto regular/medium from Flutter's material font distribution and DejaVu Serif for titles. Their license notices are retained beside the fonts. These fonts support the Vietnamese interface and avoid a web font download during play. The small web icon is an original code-native SVG gate.

## Validation

Validated with Flutter **3.47.8** / Dart **3.13.7** on Linux:

- Strict analysis and Dart formatting.
- 13 domain tests: room/tool gates, incorrect solutions, restoration order, combination consumption, actual pipe topology, complete true-ending route, ordinary/bad endings, ending immutability, partial-state saves, v1 migration and malformed saves.
- Two widget tests: phone closeup/item/autosave flow at 390 × 844 and a landscape interaction at 640 × 360. Missed taps are fatal to the widget tests.
- Asset packaging test decodes all 14 room/state/detail images and checks their full resolution.
- Release Flutter web compilation with local CanvasKit resources.
- Optional native Flutter render review via `flutter test --no-pub test/visual_review_test.dart --dart-define=CAPTURE_UI=true`; images are written to `build/ui-review/`. The helper loads the actual bundled text and icon fonts.

A browser smoke run could not start in this execution environment because Chromium's required Unix socket was unavailable. Native Flutter frame review and the release web compile are separate successful checks; no browser/device playtest is claimed.

Human first-play duration, iOS signing/build, Android packaging and memory/thermal performance on physical devices remain to be measured. The 40–70 minute duration is a design target. No release or store submission is included.
