# AGENTS.md

This repository's agent/assistant instructions live in **[CLAUDE.md](CLAUDE.md)**.

Short version: `RichTextFieldTest` is a **SwiftUI iOS evaluation spike** for a
rich-text announcement composer with **Arabic/RTL as a first-class requirement**.
It is not production code. Before making changes, read
[docs/EVALUATION.md](docs/EVALUATION.md) (goals) and
[CLAUDE.md](CLAUDE.md) (build commands + architecture map).

Ground rules:
- Preserve **LTR + RTL parity** — every screen is driven by `ComposerDirection`.
- Add new editing approaches as **new routes/variants** so they can be compared,
  don't replace existing ones.
- No test target/CI yet; verify manually in the simulator.
- Never add Claude/Anthropic co-author trailers to commits or PRs.
