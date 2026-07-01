# Evaluation charter

> The driving document for this spike. If you're picking the work back up, start
> here. Update the tables as findings land.

## 1. Why this exists

An LMS mobile app needs a **rich-text composer** for authoring
announcements (and likely other content: assignments, messages, descriptions).
The reference design is the "Create Announcement" (`إنشاء إعلان`) screen: a form
whose content field opens a formatting-capable editor supporting bold, text
color/highlight, ordered/unordered/checklist lists, alignment, and image/video
insertion.

Two constraints make this non-trivial and are the reason for a dedicated spike:

1. **Arabic / RTL is first-class.** The app is bilingual (Arabic + English).
   Mixed-direction text, per-paragraph alignment, and RTL list/marker rendering
   all have to be correct, not "mostly works in English."
2. **The stored format is HTML.** Announcement content is exchanged as HTML with
   the backend/web (⚠️ **assumption — verify**, see [BACKLOG](BACKLOG.md)). So
   whatever editor we pick must round-trip cleanly to and from HTML, not just look
   right on screen.

This project exists to answer: **what is the right editor foundation to build the
production composer on, and what does it cost us in RTL fidelity, HTML fidelity,
and maintenance?**

## 2. Goals & non-goals

**Goals**
- Determine whether **RichTextKit** (current pick) is good enough for a
  production Arabic-first, HTML-backed composer.
- Prove out the hard parts in a disposable harness: RTL formatting, list
  behavior, HTML serialization, media embedding, editing UX (modal vs inline).
- Produce a defensible **build-vs-buy / third-party recommendation**
  (see [THIRD_PARTY.md](THIRD_PARTY.md)).

**Non-goals (for this spike)**
- Production-quality code, networking, persistence, or auth.
- Full design-system fidelity — the chrome approximates the Figma, it isn't pixel
  perfect.
- Android parity (a separate app; noted only for consistency of the final format).

## 3. Approaches under comparison

The harness is structured so approaches can live side by side as routes/variants.

| ID | Approach | Status | Where |
|----|----------|--------|-------|
| A1 | **Modal editor** — tap field → bottom sheet with `RichTextEditor`, save → HTML, preview in `WKWebView` | Implemented, wired | `LegacyModalComposerView.swift` |
| A2 | **Inline editor** — `RichTextEditor` embedded directly in the form + live `RichTextViewer` + diagnostics | Implemented, **not wired into `ContentView`** | `RichTextKitComposerView.swift` |
| A3 | **Native `UITextView` only** (drop RichTextKit) | Not started | — |
| A4 | **WKWebView / contenteditable** (HTML-native editor, e.g. Quill/ProseMirror/Trix) | Not started | — |

A1 and A2 both sit on RichTextKit; A3/A4 are the genuinely different foundations
we may need to prototype before committing. See [THIRD_PARTY.md](THIRD_PARTY.md)
for the rationale.

## 4. Success criteria

The chosen approach should satisfy these. Fill in verdicts as testing proceeds
(✅ pass / ⚠️ partial / ❌ fail / — untested).

| # | Criterion | A1 (modal) | A2 (inline) | Notes |
|---|-----------|:----------:|:-----------:|-------|
| C1 | Bold / italic / underline / strikethrough apply and render | — | — | |
| C2 | Foreground color + highlight (background) apply and render | — | — | |
| C3 | Font family + size changes apply | — | — | via format sheet |
| C4 | Ordered / unordered / checklist lists create correctly | — | — | marker-based, fragile |
| C5 | Return-key continues a list; empty item exits the list | — | — | `ComposerListFormatter.returnChange` |
| C6 | Paragraph alignment (L/C/R/justify) applies | — | — | |
| C7 | **RTL: Arabic text, alignment, and markers render correctly** | — | — | primary risk |
| C8 | **Mixed LTR+RTL in one field** behaves (numbers, latin words in Arabic) | — | — | primary risk |
| C9 | Image insert (library + camera) embeds and renders | — | — | base64 in HTML |
| C10 | Video insert embeds and plays in preview | — | — | base64 in HTML |
| C11 | `NSAttributedString` → HTML is faithful (styles, lists, alignment) | — | — | `RichTextHTMLConverter` |
| C12 | **HTML → `NSAttributedString`** (re-open saved content for editing) | ❌ | ❌ | **not implemented** — see BACKLOG |
| C13 | HTML payload size is acceptable (esp. with media) | — | — | watch `RTF payload` metric + base64 bloat |
| C14 | Copy/paste (incl. from other apps) preserves/normalizes formatting | — | — | |
| C15 | Undo / redo works | — | — | |
| C16 | Accessibility: VoiceOver, Dynamic Type | — | — | toolbar buttons have a11y labels |
| C17 | Performance with long content + several images | — | — | |

C12 is currently the biggest known hole: there is no path to load existing HTML
back into the editor. Any real composer needs edit-existing, so this must be
resolved before a recommendation is final.

## 5. Test scenarios

Run each in **both** LTR and RTL. Use the seeded sample (`AnnouncementSample`) as
the starting point, then:

1. **Formatting sweep** — select ranges, apply each toolbar action, confirm on
   screen and in the HTML/preview (C1–C6).
2. **List lifecycle** — create each list type, press Return to add items, press
   Return on an empty item to exit, mix a list with a paragraph (C4–C5).
3. **RTL mixed content** — type Arabic with embedded latin words, numbers, and
   punctuation; check caret, alignment, and marker side (C7–C8).
4. **Media** — insert an image and a video from library and camera; confirm they
   appear in the editor and in the `WKWebView` HTML preview (C9–C10).
5. **Serialization audit** — read the generated HTML (A1 preview) and the
   diagnostics panel (A2) for the same content; confirm fidelity and payload size
   (C11, C13).
6. **Round-trip (blocked)** — once C12 exists: save → reload → confirm identical
   render.

## 6. Instrumentation

The harness already carries measurement tools — use them as evidence:

- **Diagnostics panel** (`RichTextDiagnosticsPanel`, A2): character count,
  attachment count, bold/italic/underline/strike ranges, and **RTF payload byte
  count** — a cheap proxy for content weight.
- **HTML preview** (`WKWebView`, A1): the actual serialized output, rendered.
- **`RichTextViewer`** (A2): RichTextKit's own read-only render, to compare
  against our HTML render.

## 7. Decision & next steps

The recommendation lives in [THIRD_PARTY.md](THIRD_PARTY.md); the prioritized work
to get there lives in [BACKLOG.md](BACKLOG.md). This charter should be updated
with verdicts (Section 4) as scenarios (Section 5) are executed.
