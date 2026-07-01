# Backlog & open questions

Prioritized list of what's unresolved. Keep this current — it's the "what next"
for continuing the evaluation. Legend: 🔴 blocker · 🟠 important · 🟡 nice-to-have.

## Open questions to resolve first (unblock the whole evaluation)

These are cheap to answer and change the decision. Answer them before building
more.

- 🔴 **Is HTML actually the backend interchange format for announcements?**
  The whole serialization design assumes it. Confirm against the LMS API /
  companion iOS app. If it's something else (Markdown, Delta, plain
  attributed data, a JSON block model), the converter strategy changes.
- 🔴 **What HTML subset does the backend/web accept and emit?** Tags, allowed
  inline styles vs classes, how it represents lists, alignment, images
  (inline base64 vs uploaded URL), and RTL (`dir` attribute vs CSS). Our output
  must match what the web renderer expects.
- 🟠 **Does the LMS web app already ship a rich-text editor?** If so, which one
  (Quill/CKEditor/TipTap/…)? Reusing it via `WKWebView` (Option C) could unify
  the format and eliminate the serialization mismatch entirely.
- 🟠 **Are images/videos meant to be uploaded (URL) or inlined (base64)?**
  Current code inlines base64, which bloats payloads badly (see C13). Real apps
  almost always upload and reference a URL.
- 🟡 **What's the minimum iOS the LMS app targets?** Governs whether the native
  SwiftUI rich `TextEditor` (Option D) ever becomes viable.

## Decision we owe an answer to

- 🟠 **Third-party editor library vs. fully custom — undecided.** The core call
  this spike exists to make: keep a 3rd-party core (RichTextKit), drop to native
  `UITextView`/`NSAttributedString`, or go `WKWebView` + a web editor. It hinges
  on the open questions above and the evaluation matrix. Track the analysis and
  record the final verdict in [THIRD_PARTY.md](THIRD_PARTY.md).

## Known gaps in the current harness

- 🔴 **No HTML → `NSAttributedString` path (C12).** You cannot re-open saved
  content for editing. Every real composer needs edit-existing. Until this exists,
  no approach on RichTextKit can be fully validated.
- 🟠 **`RichTextKitComposerView` (A2) is not routed** from `ContentView`. Add a
  route so the inline variant + diagnostics can actually be exercised.
- 🟠 **List robustness.** Marker-based lists (`ComposerListFormatter`) are
  fragile: test paste-into-list, editing mid-marker, deleting a marker, nested /
  indented lists, and **RTL marker placement** (does `• ` / `1. ` sit on the
  correct side in Arabic?). The HTML converter re-detects markers by regex — 
  confirm it matches the formatter's output exactly.
- 🟠 **Alignment is derived from the first paragraph only** in the HTML converter
  (`cssTextAlignment`). Mixed-alignment content won't serialize per block.
- 🟡 **No persistence.** Content resets on relaunch; can't test true round-trip
  without it.
- 🟡 **Dark mode untested** — app is pinned to `.light`.
- 🟡 **No tests / no CI / not a git repo.** At minimum: `git init` + Swift
  `.gitignore`; consider snapshot tests for the HTML converter (pure function,
  easy to cover).

## Research threads / experiments to run

1. 🔴 **Round-trip prototype (C12).** Pick the fidelity target: (a) custom
   HTML→attributed parser, or (b) benchmark `NSAttributedString`'s built-in
   `.html` `DocumentType` import/export for round-trip loss and RTL handling. This
   is the single most decision-relevant experiment.
2. 🟠 **RTL fidelity pass (C7/C8).** Systematic test of Arabic + mixed
   latin/numbers: caret behavior, alignment, list markers, and HTML `dir`
   rendering in the `WKWebView` preview.
3. 🟠 **Option C spike.** Minimal `WKWebView` + a web editor (Quill or the LMS
   web app's own editor) with a JS bridge; compare HTML fidelity, RTL, and effort
   against A. See [THIRD_PARTY.md](THIRD_PARTY.md).
4. 🟠 **Payload/size study (C13).** Measure HTML size for representative content
   with 0 / 1 / 3 images and a video; compare base64-inline vs a URL-reference
   design. Use the diagnostics panel's RTF byte count + the generated HTML length.
5. 🟡 **Option B benchmark.** Prototype a pure `UITextView` + native HTML
   round-trip to quantify what dropping RichTextKit would cost/save.
6. 🟡 **Accessibility & Dynamic Type pass (C16).** VoiceOver over the toolbar and
   editor; large text sizes.

## Things to consider before productionizing (whichever approach wins)

- Content sanitization / XSS: HTML from users must be sanitized on the way in and
  out; the current converter escapes text but there's no import sanitization.
- Consistent format contract shared with the **Android** counterpart and
  **web**, so all three read/write the same HTML.
- Link insertion/editing (not implemented; likely required for announcements).
- Media upload pipeline (URLs, not base64), size limits, and progress UI.
- Localization of the toolbar/format-sheet strings (currently English literals).
- Design-system fidelity vs the current approximation.

## How to record progress

- Fill in the verdict tables in [EVALUATION.md](EVALUATION.md) §4 as scenarios run.
- Note the final foundation decision in [THIRD_PARTY.md](THIRD_PARTY.md).
- Move resolved items out of this backlog into the relevant doc.
