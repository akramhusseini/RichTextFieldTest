# Third-party vs. custom

The build-vs-buy analysis for the editor foundation. This is a **living
recommendation** — update it as scenarios in [EVALUATION.md](EVALUATION.md) are
executed.

## Current state

We are **mixing**: a third-party editor core with a thick custom layer on top.

| Layer | Source | Notes |
|-------|--------|-------|
| Editor core (`RichTextEditor`, context, viewer, format sheet) | **3rd party** — RichTextKit 1.2.0 | MIT, actively maintained by Daniel Saidi |
| Keyboard toolbar UI | **Custom** | Matches Figma; drives RichTextKit's context |
| Lists (bullet/numbered/checklist) | **Custom** | Marker-based; RichTextKit has no list model |
| HTML serialization | **Custom** | `NSAttributedString → HTML`, one-way |
| Media insert + video embedding | **Custom** | `UIImagePickerController` + base64 |

So the question is not purely "third party or not" — it's **"is RichTextKit the
right core, and how much custom scaffolding are we signing up to own?"**

## Option A — Keep RichTextKit (current)

**What it gives us:** a SwiftUI-native `RichTextEditor`/`RichTextContext` over
`UITextView`, a ready format sheet (fonts, sizes, colors, indent, styles),
image attachment support, undo/redo, and a `RichTextViewer`. MIT-licensed, one
dependency, already integrated.

**What we still own:** lists, HTML in/out, media embedding, the toolbar, and RTL
correctness on top of it.

- 👍 Fast start; solves the fiddly `UITextView`/attributed-string plumbing.
- 👍 SwiftUI-first API fits the app.
- 👎 **No list model** → our fragile marker approach.
- 👎 **No HTML** in or out → we own serialization *and the missing deserialization*.
- 👎 RTL is only as good as the underlying `UITextView` + our paragraph handling;
  needs explicit validation (C7/C8).
- 👎 External dependency risk: single maintainer, our pinned `1.2.0`.

## Option B — Native `UITextView` only (drop RichTextKit)

Build directly on `UITextView` + `NSAttributedString`, no editor dependency.

- 👍 Zero third-party editor risk; full control; smallest dependency surface.
- 👍 `NSAttributedString` has **built-in HTML import/export**
  (`NSAttributedString.DocumentType.html`) — a real, if imperfect, round-trip
  path that directly addresses C11/C12.
- 👎 We reimplement what RichTextKit already gives us (toolbar wiring, selection
  state, format UI, image attachments).
- 👎 `NSAttributedString` HTML export is verbose/quirky and its import is
  main-thread + sanitization-sensitive — needs its own evaluation.

## Option C — WKWebView / `contenteditable` (HTML-native editor)

Embed a web-based editor (e.g. Quill, ProseMirror, Trix, CKEditor) in a
`WKWebView` and bridge via JS.

- 👍 **HTML is the native format** — no lossy attributed-string bridge; edit-existing
  (C12) is trivial.
- 👍 Mature RTL and list support in the browser; matches whatever the LMS **web**
  app already uses (worth checking — reusing the web composer could unify formats).
- 👍 Rich feature set (tables, links, embeds) largely for free.
- 👎 Native ↔ JS bridge complexity; keyboard/toolbar integration is more work.
- 👎 Heavier; native-feel and accessibility need care.
- 👎 New dependency of a different kind (JS bundle to vendor/maintain).

## Option D — SwiftUI-native rich `TextEditor`

iOS 18+/26 introduced `AttributedString`-backed rich text in SwiftUI's
`TextEditor`.

- 👍 First-party, no dependency, future direction of the platform.
- 👎 **Blocked by our deployment target (iOS 16.6).** Only reconsider if the LMS
  app raises its minimum iOS substantially. Not viable now.

## Decision framework

Weight by what actually matters for this product:

1. **HTML round-trip fidelity** (backend format) — favors **C**, then **B**.
2. **RTL / Arabic correctness** — favors **C** (browser) and **B**
   (native text engine); RichTextKit inherits native but is unproven here.
3. **Edit-existing content (C12)** — favors **C** and **B**; **A** has no path today.
4. **Time-to-ship / effort now** — favors **A** (already integrated).
5. **Long-term maintenance / dependency risk** — favors **B**, then **A**.
6. **Feature ceiling** (tables, links, embeds) — favors **C**.

## Recommendation (provisional — pending tests)

- **Continue with Option A to de-risk quickly**, but treat two things as
  blocking-unknowns that could flip the decision:
  - **C12 (HTML → editor)** — if RichTextKit + a custom deserializer can't
    round-trip HTML acceptably, A is not viable for edit-existing.
  - **C7/C8 (RTL fidelity)** — if RTL formatting/markers are shaky, revisit.
- **Spike Option C in parallel** as the strongest contender for an HTML-native,
  RTL-strong product — *especially if the LMS web app already ships a
  web-based editor we could reuse* (verify — see [BACKLOG.md](BACKLOG.md)).
- **Keep Option B in reserve** as the low-dependency fallback; specifically
  benchmark `NSAttributedString`'s native HTML import/export before dismissing it.
- **Defer Option D** until the deployment target allows it.

Record the final call here once the evaluation matrix in
[EVALUATION.md](EVALUATION.md) §4 is filled in.
