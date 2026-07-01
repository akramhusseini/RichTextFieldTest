# CLAUDE.md

Orientation for AI assistants and new developers working in this repository.
Keep this file current when the architecture changes.

## What this project is

`RichTextFieldTest` is a **SwiftUI iOS evaluation spike** (not production code)
for choosing how to build a **rich-text announcement composer** for an
LMS mobile app. **Arabic / RTL is a first-class requirement**, not an
afterthought. The composer must produce **HTML** (the interchange format used by
the LMS backend/web — treat this as an assumption to verify, see
[docs/BACKLOG.md](docs/BACKLOG.md)).

Bundle id `com.example.RichTextFieldTest` · iOS 16.6+ · Swift 5.0 · single
dependency: **RichTextKit 1.2.0** (SPM).

Read [docs/EVALUATION.md](docs/EVALUATION.md) before making changes — it defines
what we're trying to learn.

## Build & run

```bash
xcodebuild -project RichTextFieldTest.xcodeproj \
  -scheme RichTextFieldTest \
  -destination 'platform=iOS Simulator,name=iPhone 15' build
```

There is **no test target yet** and **no CI**. Verification today is manual, in
the simulator/device. If you add automated coverage, document it here.

## Architecture map

All source is in `RichTextFieldTest/`:

| File | Responsibility |
|------|----------------|
| `RichTextFieldTestApp.swift` | App entry point. Forces `.light` color scheme. |
| `ContentView.swift` | Route list. **Only wires up `LegacyModalComposerView`** (LTR + RTL). |
| `LegacyModalComposerView.swift` | Primary variant: form → bottom-sheet `RichTextEditor` → save → `NSAttributedString`→HTML → `WKWebView` preview. Contains `RichTextHTMLConverter`. |
| `RichTextKitComposerView.swift` | Alternate variant: inline editor + `RichTextViewer` preview + diagnostics. **Not linked from `ContentView`.** |
| `ComposerChrome.swift` | Shared UI + logic: palette, form fields, chips, the design-matched keyboard toolbar (`DesignRichTextToolbar`), media picker, and `ComposerListFormatter` (list engine). |
| `AnnouncementSample.swift` | `ComposerDirection` (LTR/RTL abstraction), seeded sample content, and diagnostics `metrics(...)`. |

## Key concepts

- **`ComposerDirection`** (`AnnouncementSample.swift`) is the LTR/RTL switch.
  Every screen takes one and derives layout direction, locale, alignment, and
  sample copy from it. When you touch layout, exercise **both** directions.
- **RichTextKit** provides the editor core (`RichTextEditor`, `RichTextContext`,
  `RichTextViewer`) over UIKit's `NSAttributedString`/`UITextView`. The formatting
  toolbar drives it through `context.trigger(...)`, `context.toggleStyle(...)`,
  `context.setColor(...)`.
- **Lists are custom, marker-based** (`ComposerListFormatter`). RichTextKit has no
  native list model, so lists are plain-text markers (`•`, `☐`, `1.`) plus
  return-key continuation logic. This is fragile by design — see the backlog.
- **HTML is produced by our own serializer** (`RichTextHTMLConverter` in
  `LegacyModalComposerView.swift`). It walks the `NSAttributedString` and emits
  inline styles, `<ul>/<ol>`, alignment, and base64 `<img>`/`<video>`. There is
  currently **no HTML → NSAttributedString path** (you cannot re-open saved HTML
  for editing).

## Conventions

- Keep RTL parity: anything added for LTR must have an RTL counterpart via
  `ComposerDirection`. Do not hardcode `.leading`/`.left`.
- Match the existing SwiftUI style (small private structs, `ComposerPalette` for
  colors, `ComposerSection` for card chrome).
- This is a spike: prefer clarity and instrumentation over abstraction. New
  approaches should be added as **new routes/variants** so they can be compared
  side by side, not by replacing existing ones.

## Repository status

- **Not a git repository yet** (`git status` fails). If you start tracking it,
  add a Swift/Xcode `.gitignore` (exclude `xcuserdata/`, `.DS_Store`, build
  output).
- Per user rule: **never add Claude/Anthropic co-author trailers** to commits or
  PRs in any of these projects.

## Related context

This spike informs a production LMS iOS app (a separate, private codebase) that
also has an Android counterpart. Those are separate repos; changes here don't
touch them.
