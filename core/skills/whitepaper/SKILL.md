---
tools:
  render_whitepaper: core/tools/render_whitepaper.py
---

# whitepaper

Render Markdown documents to consulting-grade PDF whitepapers with professional typography, cover pages, and table of contents.

## Usage

```bash
# Basic rendering — title, subtitle, TOC auto-extracted from markdown
DYLD_LIBRARY_PATH=/opt/homebrew/lib uv run --with weasyprint,markdown,jinja2 \
  core/tools/render_whitepaper.py input.md -o output.pdf

# With metadata overrides
DYLD_LIBRARY_PATH=/opt/homebrew/lib uv run --with weasyprint,markdown,jinja2 \
  core/tools/render_whitepaper.py input.md -o output.pdf \
  --organization "Acme Corp" --date "March 2026" --authors "Jane Doe"

# Custom branding colors
DYLD_LIBRARY_PATH=/opt/homebrew/lib uv run --with weasyprint,markdown,jinja2 \
  core/tools/render_whitepaper.py input.md -o output.pdf \
  --primary-color "#147B58" --accent-color "#147B58"

# Executive summary (auto-detected cover label from ## heading)
DYLD_LIBRARY_PATH=/opt/homebrew/lib uv run --with weasyprint,markdown,jinja2 \
  core/tools/render_whitepaper.py docs/whitepaper/executive-summary.md \
  -o build/executive-summary.pdf --cover-label "Executive Summary"

# No TOC, no cover
DYLD_LIBRARY_PATH=/opt/homebrew/lib uv run --with weasyprint,markdown,jinja2 \
  core/tools/render_whitepaper.py input.md -o output.pdf --no-toc --no-cover
```

## When to Use

- Rendering whitepapers, executive summaries, or technical briefs from markdown
- Producing client-facing PDF deliverables with professional typography
- Generating branded documents with custom colors and metadata

## Markdown Format

The tool auto-extracts metadata from the markdown structure:

```markdown
# Document Title           ← becomes cover title
**Subtitle text here**     ← becomes cover subtitle (bold or italic)
## Document Type           ← becomes cover label (e.g., "Executive Summary")
---                        ← separator (stripped from body)

## 1. First Section        ← H2 headings become TOC entries + section dividers
### Subsection             ← H3 headings become indented TOC entries

Body text, tables, code blocks, blockquotes (rendered as callout boxes).

---                        ← section dividers (visual only, no page breaks)

## 2. Second Section
...
```

## Design System

- **Typography**: Libre Franklin (headings), Source Serif 4 (body), Source Code Pro (code)
- **Color palette**: Navy primary (#1e3a5f), blue accent (#2251ff) — customizable
- **Page layout**: A4, 25mm margins, running headers, page numbers
- **Cover page**: Navy background with blue accent bar, white text
- **Tables**: Dark navy header, alternating row shading, horizontal borders only
- **Callout boxes**: Blockquotes styled with blue left border + light background
- **Code blocks**: Dark background with monospace font

## Requirements

- macOS: `brew install pango` (WeasyPrint system dependency)
- Linux: `apt install libpango-1.0-0 libpangocairo-1.0-0`
- No persistent venv needed — `uv run --with` resolves dependencies on-demand
- On macOS: prefix commands with `DYLD_LIBRARY_PATH=/opt/homebrew/lib`

## Output

- Professional PDF with cover page, optional TOC, styled body content
- Running headers (document title left, section title right)
- Page numbers (centered bottom)
- Embedded variable fonts (no system font dependency for rendering)

## CLI Options

| Option | Description |
|--------|-------------|
| `--title` | Override document title (default: first H1) |
| `--subtitle` | Override subtitle |
| `--cover-label` | Label above title on cover (default: "Whitepaper") |
| `--authors` | Author name(s) |
| `--organization` | Organization name |
| `--date` | Publication date |
| `--version-label` | Version label (e.g., "v1.0") |
| `--primary-color` | Primary brand color (hex) |
| `--accent-color` | Accent color (hex) |
| `--custom-css` | Path to additional CSS for brand overrides |
| `--no-toc` | Omit table of contents |
| `--no-cover` | Omit cover page |
| `--template-dir` | Custom template directory |
