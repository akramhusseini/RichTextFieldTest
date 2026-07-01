# RichTextFieldTest

**Research spike: rich-text editing capability on iOS.**

A SwiftUI iOS harness for evaluating how to build a production-quality
**rich-text composer** on iOS, with two hard requirements as the focus of the
research:

- **Arabic / right-to-left (RTL) as a first-class citizen** — mixed-direction
  text, per-paragraph alignment, and RTL list/marker rendering.
- **HTML as the interchange format** — content must round-trip cleanly to and
  from HTML, not just look right on screen.

This is a throwaway evaluation harness, **not** production code. Its job is to
compare editing approaches (third-party vs. custom), stress RTL and formatting
fidelity, and produce a defensible recommendation for what to ship.

The reference UX is a "Create Announcement" (`إنشاء إعلان`) screen: a form with a
rich-text content field that opens a formatting-capable editor (bold, color,
lists, alignment, image/video) and stores the result as HTML.

---

## Quick start

Requirements: Xcode 15+, iOS 16.6+ simulator or device.

```bash
open RichTextFieldTest.xcodeproj
# then Cmd-R, or:

xcodebuild \
  -project RichTextFieldTest.xcodeproj \
  -scheme RichTextFieldTest \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

The only external dependency is [RichTextKit](https://github.com/danielsaidi/RichTextKit)
`1.2.0`, resolved via Swift Package Manager (already pinned in
`project.xcworkspace/xcshareddata/swiftpm/Package.resolved`).

## What you'll see

`ContentView` lists the currently-wired routes:

| Route | Screen | What it exercises |
|-------|--------|-------------------|
| Modal editor – LTR | `LegacyModalComposerView(.leftToRight)` | Bottom-sheet editor + HTML preview, English |
| Modal editor – RTL | `LegacyModalComposerView(.rightToLeft)` | Same, Arabic layout direction |

> A second variant, `RichTextKitComposerView` (inline editor + live diagnostics),
> exists in the code but is **not currently linked from `ContentView`**. See
> [docs/BACKLOG.md](docs/BACKLOG.md).

## Documentation

Start here and read in order:

1. **[docs/EVALUATION.md](docs/EVALUATION.md)** — why this spike exists, goals,
   success criteria, the approaches being compared, and the test matrix. **This is
   the driving document for continuing the evaluation.**
2. **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — how the current
   implementation actually works, file by file.
3. **[docs/THIRD_PARTY.md](docs/THIRD_PARTY.md)** — third-party vs. custom
   analysis: RichTextKit assessment and the alternatives on the table.
4. **[docs/BACKLOG.md](docs/BACKLOG.md)** — open questions, known gaps, and the
   next research steps, prioritized.

Agent/AI-assistant orientation lives in **[CLAUDE.md](CLAUDE.md)**.
