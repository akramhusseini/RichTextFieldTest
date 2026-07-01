# Architecture

How the current implementation actually works. Pair this with the source; file
references are the source of truth.

## Layer overview

```
┌──────────────────────────────────────────────────────────────┐
│ SwiftUI screens                                                │
│   ContentView → LegacyModalComposerView (A1)                   │
│                 RichTextKitComposerView (A2, not wired)        │
├──────────────────────────────────────────────────────────────┤
│ Shared chrome & logic  (ComposerChrome.swift)                  │
│   ComposerSection / ComposerTextField / chips / palette        │
│   DesignRichTextToolbar  (design-matched keyboard toolbar)     │
│   ComposerListFormatter  (marker-based list engine)            │
│   Media picker (UIImagePickerController) + video embedding     │
├──────────────────────────────────────────────────────────────┤
│ RichTextKit 1.2.0                                              │
│   RichTextEditor / RichTextContext / RichTextViewer            │
│   RichTextFormat.Sheet (font/size/color/indent/styles)         │
├──────────────────────────────────────────────────────────────┤
│ UIKit / Foundation                                             │
│   NSAttributedString · UITextView · WKWebView · AVFoundation   │
└──────────────────────────────────────────────────────────────┘
```

The **model in memory is always an `NSAttributedString`**. HTML is a derived
output, produced on save.

## Direction abstraction — `ComposerDirection`

`AnnouncementSample.swift` defines `ComposerDirection { leftToRight, rightToLeft }`.
It is the single source for everything direction-dependent:

- `layoutDirection` → applied via `.environment(\.layoutDirection, …)`
- `localeIdentifier` (`en`/`ar`) → `.environment(\.locale, …)`
- `textAlignment` (`.left`/`.right`), `horizontalAlignment` (`.leading`/`.trailing`)
- Localized copy: `navigationTitle`, `sampleTitle`, `contentLabel`

Every screen is constructed with a direction and pulls all of these from it. This
is what makes side-by-side LTR/RTL testing cheap — and why new UI must route
through it rather than hardcoding sides.

## A1 — `LegacyModalComposerView` (the wired variant)

Flow:

1. Renders the form (title field, type chips) plus an
   `AnnouncementContentPreviewField` — a tappable `WKWebView` showing the current
   content as HTML.
2. Tapping it presents `LegacyRichTextSheet` (`.large` detent) containing the
   `RichTextEditor` bound to a draft `NSAttributedString`, with the
   `DesignKeyboardRichTextToolbar` pinned above the keyboard.
3. On **Save**, the draft is written back and re-serialized to HTML via
   `RichTextHTMLConverter`, which the preview `WKWebView` renders.

List continuation is wired here via `.onChange(of: draftText.string)` →
`handleDraftStringChange` → `ComposerListFormatter.returnChange(...)`, using an
`isApplyingListContinuation` guard to avoid feedback loops.

This variant models the **"edit in a modal, store HTML"** production pattern, and
is the one that surfaces the HTML serialization path.

## A2 — `RichTextKitComposerView` (inline, not wired)

Everything inline in the scroll view: the `RichTextEditor`, a `RichTextViewer`
live preview, and `RichTextDiagnosticsPanel`. It configures the format sheet
(`.richTextFormatSheetConfig`) with foreground/background color pickers, font +
size pickers, indent buttons, and all styles.

It does **not** go through `RichTextHTMLConverter` — it shows RichTextKit's own
render. It exists to compare inline vs modal UX and to expose the diagnostics.
It is **not reachable from `ContentView`** today (add a route to test it).

## The toolbar — `DesignRichTextToolbar`

A horizontally-scrolling keyboard accessory matching the Figma. Wrapped by
`DesignKeyboardRichTextToolbar`, which only shows it while
`context.isEditingText` is true. Buttons drive RichTextKit:

- **Color menu** — quick foreground colors + a yellow highlight, plus "More
  formatting" which opens `RichTextFormat.Sheet`.
- **Underline** — `context.toggleStyle(.underlined)`.
- **Image / video** — a confirmation dialog (library/camera) →
  `ComposerMediaPicker` (`UIImagePickerController`) → inserted as an attachment.
- **Lists** — bullet / numbered / checklist via `applyList(...)` →
  `ComposerListFormatter.listEdit(...)`.
- **Alignment** — `context.trigger(.setAlignment(...))` for L/C/R/justify.

## Lists — `ComposerListFormatter` (marker-based)

RichTextKit (and `NSAttributedString`) have **no native list model**, so lists are
implemented as **plain-text markers**:

- Bullet `• `, checklist `☐ ` / `☑ `, numbered `1. ` (indent-preserving).
- `listEdit(for:selectedRange:kind:)` rewrites the selected line range, prefixing
  each line with the marker and renumbering ordered lists.
- `returnChange(previous:current:)` detects a newline insertion after a list line
  and either (a) inserts the next marker, or (b) if the previous item was empty,
  removes the dangling marker to exit the list.

**Implication:** lists are not structural — they are text that *looks* like a
list. The HTML converter re-detects these markers to emit real `<ul>/<ol>`. This
is the most fragile part of the system (paste, editing mid-marker, RTL marker
placement, nested/indented lists all stress it). See [BACKLOG.md](BACKLOG.md).

## HTML serialization — `RichTextHTMLConverter`

Lives in `LegacyModalComposerView.swift`. One-way: `NSAttributedString → HTML`.

- **Document**: emits `<html lang dir>` from the direction, plus a `<style>` block
  (list styling, `.media-attachment`, checklist `☐` pseudo-marker) and computes
  `text-align` from the first paragraph style.
- **Block pass** (`htmlBody`): splits into lines, groups marker lines into
  `<ul>/<ol>/<ul class="checklist">`, emits `<br>` for blank lines and line
  breaks.
- **Inline pass** (`inlineHTML` / `styledSpan`): walks attribute runs, emits
  `<span style>` for bold (`font-weight`), italic, size, underline/strikethrough
  (`text-decoration`), and `color` / `background-color` as `rgba(...)`.
- **Attachments** (`attachmentHTML`): images → `data:image/...;base64` `<img>`;
  videos → `<video>` with a base64 `<source>` and base64 poster, using the custom
  attributed-string keys below.

**Custom attribute keys** (`NSAttributedString.Key` extension in
`ComposerChrome.swift`): `composerMediaKind`, `composerVideoDataBase64`,
`composerVideoMimeType` — how video payloads ride along inside the attributed
string until serialization.

**Known limitations of the converter**: no inverse (HTML → attributed string);
alignment is derived from the *first* paragraph only, not per-block; media is
inlined as base64 (payload bloat, no upload/URL story).

## Media pipeline

`ComposerMediaPicker` (`UIImagePickerController`) returns an image or a
`ComposerPickedVideo` (data + mime + generated thumbnail + duration). Videos get a
rendered "video card" thumbnail (`videoThumbnail(...)`) as the visible attachment,
with the actual video bytes carried in the custom attributes and emitted as an
inline `<video>` on serialization. Images use RichTextKit's
`RichTextImageAttachment`.

## Diagnostics — `AnnouncementSample.metrics`

Computes character count, attachment count, style-run character totals
(bold/italic/underline/strike), and an **RTF payload byte count** (serializes the
attributed string to RTF). Surfaced by `RichTextDiagnosticsPanel` in A2 as the
harness's measurement readout.

## Notable current-state facts

- Only `LegacyModalComposerView` is reachable from the UI; `RichTextKitComposerView`
  is dead-linked (exists, not routed).
- App is locked to `.light` color scheme (`RichTextFieldTestApp`); dark mode is
  untested.
- No persistence — content resets on relaunch; HTML is never stored or reloaded.
- Not a git repo; no tests; iOS 16.6 min (so iOS 18+ SwiftUI rich-text `TextEditor`
  APIs are out of scope for the current target).
