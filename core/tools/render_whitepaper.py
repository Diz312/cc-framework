#!/usr/bin/env python3
"""
render_whitepaper.py — Consulting-grade PDF whitepaper renderer.

Converts Markdown whitepapers to professionally styled PDFs using
WeasyPrint, Jinja2, and python-markdown. Designed for enterprise
engineering whitepapers with McKinsey/BCG/Deloitte-grade aesthetics.

Usage (via uv):
    uv run --with weasyprint,markdown,jinja2 core/tools/render_whitepaper.py \\
        docs/whitepaper/full-whitepaper.md -o output.pdf

    uv run --with weasyprint,markdown,jinja2 core/tools/render_whitepaper.py \\
        docs/whitepaper/executive-summary.md -o exec-summary.pdf \\
        --cover-label "Executive Summary"

Metadata extraction:
    The tool extracts title, subtitle, and metadata from the markdown content:
    - Title: first H1 heading
    - Subtitle: first bold/italic line after title, or first H2
    - Sections: H2 headings for TOC generation
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import jinja2
import markdown
import weasyprint


# ---------------------------------------------------------------------------
# Markdown → HTML conversion
# ---------------------------------------------------------------------------

MARKDOWN_EXTENSIONS = [
    "tables",
    "fenced_code",
    "footnotes",
    "toc",
    "attr_list",
    "md_in_html",
    "smarty",
]

MARKDOWN_EXTENSION_CONFIGS = {
    "toc": {
        "permalink": False,
        "toc_depth": "2-3",
    },
    "smarty": {
        "smart_quotes": True,
        "smart_dashes": True,
    },
}


def convert_markdown(md_text: str) -> tuple[str, list[dict[str, str]]]:
    """Convert markdown to HTML and extract TOC items.

    Returns:
        Tuple of (html_body, toc_items) where toc_items is a list of
        dicts with keys: id, text, level, number.
    """
    md = markdown.Markdown(
        extensions=MARKDOWN_EXTENSIONS,
        extension_configs=MARKDOWN_EXTENSION_CONFIGS,
    )
    html = md.convert(md_text)

    # Extract TOC items from the generated toc_tokens
    toc_items: list[dict[str, str]] = []
    h2_counter = 0

    def _walk_tokens(tokens: list[dict]) -> None:
        nonlocal h2_counter
        for token in tokens:
            if token["level"] == 2:
                h2_counter += 1
                toc_items.append(
                    {
                        "id": token["id"],
                        "text": token["name"],
                        "level": "h2",
                        "number": str(h2_counter),
                    }
                )
            elif token["level"] == 3:
                toc_items.append(
                    {
                        "id": token["id"],
                        "text": token["name"],
                        "level": "h3",
                        "number": "",
                    }
                )
            if token.get("children"):
                _walk_tokens(token["children"])

    if hasattr(md, "toc_tokens"):
        _walk_tokens(md.toc_tokens)

    return html, toc_items


# ---------------------------------------------------------------------------
# Markdown preprocessing — strip cover material from body
# ---------------------------------------------------------------------------


def preprocess_markdown(md_text: str) -> tuple[str, dict[str, str]]:
    """Strip the header block from markdown and extract metadata.

    The header block consists of:
    - The first H1 heading (becomes cover title)
    - An optional bold/italic subtitle line
    - An optional H2 that serves as the document type label
    - The first --- separator

    These are all represented on the cover page, so they should not
    appear in the body content.

    Returns:
        Tuple of (cleaned_markdown, metadata_dict).
    """
    metadata: dict[str, str] = {}
    lines = md_text.strip().split("\n")
    body_start = 0

    # Phase 1: Find and extract the H1 title
    for i, line in enumerate(lines):
        if line.startswith("# ") and not line.startswith("## "):
            metadata["title"] = line.lstrip("# ").strip()
            body_start = i + 1
            break

    # Phase 2: Skip blank lines, then look for subtitle or H2
    i = body_start
    while i < len(lines) and not lines[i].strip():
        i += 1

    if i < len(lines):
        clean = lines[i].strip()
        # Bold subtitle: **A Framework for...**
        if clean.startswith("**") and clean.endswith("**"):
            metadata["subtitle"] = clean.strip("*").strip()
            i += 1
        # Italic subtitle
        elif clean.startswith("*") and clean.endswith("*") and not clean.startswith("**"):
            metadata["subtitle"] = clean.strip("*").strip()
            i += 1

    # Phase 3: Skip blanks, then check for H2 (doc type) + --- separator
    while i < len(lines) and not lines[i].strip():
        i += 1

    if i < len(lines) and lines[i].startswith("## "):
        h2_text = lines[i].lstrip("# ").strip()
        # Use H2 as cover_label if it looks like a document type
        # (e.g., "Executive Summary", not a numbered section like "1. The Case...")
        if not re.match(r"^\d+\.", h2_text):
            metadata["cover_label"] = h2_text
            i += 1

    # Phase 4: Skip blanks + the first --- separator
    while i < len(lines) and not lines[i].strip():
        i += 1

    if i < len(lines) and lines[i].strip().startswith("---"):
        i += 1

    body_start = i

    # Phase 5: Strip trailing --- + whitespace + short final lines
    # (e.g., "*Full whitepaper available: ...*")
    body_end = len(lines)
    # Walk backwards from end
    j = len(lines) - 1
    while j > body_start and not lines[j].strip():
        j -= 1

    # Check if last non-empty line is a standalone --- or very short reference
    if j > body_start and lines[j].strip().startswith("---"):
        body_end = j
        # Also check if the line before --- is short italic text
        k = j - 1
        while k > body_start and not lines[k].strip():
            k -= 1
        # Don't strip — that could be real content
    elif j > body_start:
        # Check for trailing italic reference line after a ---
        # Pattern: "---\n\n*Full whitepaper...*"
        pass

    cleaned = "\n".join(lines[body_start:body_end])

    return cleaned, metadata


# ---------------------------------------------------------------------------
# HTML post-processing
# ---------------------------------------------------------------------------


def post_process_html(html: str) -> str:
    """Apply post-processing to the generated HTML.

    - Remove the first <hr> if it would create a blank page
    - Strip empty leading content
    """
    # Remove leading whitespace/newlines
    html = html.strip()

    # If the HTML starts with an <hr>, remove it (would create blank first page)
    html = re.sub(r"^\s*<hr\s*/?\s*>\s*", "", html)

    # Remove trailing <hr> (would create blank last page)
    html = re.sub(r"\s*<hr\s*/?\s*>\s*$", "", html)

    return html


# ---------------------------------------------------------------------------
# Template rendering
# ---------------------------------------------------------------------------


def render_html(
    body_html: str,
    toc_items: list[dict[str, str]],
    metadata: dict[str, str],
    template_dir: Path,
    cli_args: argparse.Namespace,
) -> str:
    """Render the full HTML document from template + content."""
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(str(template_dir)),
        autoescape=False,
    )
    template = env.get_template("whitepaper.html")

    # Resolve CSS path relative to template directory
    css_path = (template_dir / "whitepaper.css").as_uri()

    # Determine title
    title = cli_args.title or metadata.get("title", "Whitepaper")

    # Determine cover label
    cover_label = cli_args.cover_label
    if cover_label == "Whitepaper" and "cover_label" in metadata:
        cover_label = metadata["cover_label"]

    # Build template context
    context = {
        "title": title,
        "subtitle": cli_args.subtitle or metadata.get("subtitle", ""),
        "short_title": cli_args.short_title or title,
        "cover_label": cover_label,
        "authors": cli_args.authors,
        "organization": cli_args.organization,
        "date": cli_args.date,
        "version": cli_args.version_label,
        "css_path": css_path,
        "custom_css_path": cli_args.custom_css,
        "primary_color": cli_args.primary_color,
        "primary_dark_color": cli_args.primary_dark_color,
        "accent_color": cli_args.accent_color,
        "toc_items": toc_items if not cli_args.no_toc else [],
        "body_html": body_html,
    }

    return template.render(**context)


# ---------------------------------------------------------------------------
# PDF generation
# ---------------------------------------------------------------------------


def generate_pdf(html: str, output_path: Path, template_dir: Path) -> None:
    """Generate PDF from HTML using WeasyPrint."""
    base_url = str(template_dir) + "/"
    doc = weasyprint.HTML(string=html, base_url=base_url)
    doc.write_pdf(str(output_path))


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Render Markdown whitepapers to consulting-grade PDFs.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s whitepaper.md -o whitepaper.pdf
  %(prog)s whitepaper.md -o out.pdf --title "My Report" --cover-label "Technical Brief"
  %(prog)s whitepaper.md -o out.pdf --primary-color "#147B58" --accent-color "#147B58"
        """,
    )

    parser.add_argument(
        "input",
        type=Path,
        help="Input Markdown file",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        required=True,
        help="Output PDF file path",
    )

    # Metadata overrides
    meta = parser.add_argument_group("metadata")
    meta.add_argument("--title", help="Override document title (default: first H1)")
    meta.add_argument("--subtitle", help="Override subtitle")
    meta.add_argument("--short-title", help="Short title for running header")
    meta.add_argument(
        "--cover-label",
        default="Whitepaper",
        help="Label above title on cover (default: Whitepaper)",
    )
    meta.add_argument("--authors", help="Author name(s)")
    meta.add_argument("--organization", help="Organization name")
    meta.add_argument("--date", help="Publication date")
    meta.add_argument("--version-label", help="Version label (e.g., 'v1.0')")

    # Styling overrides
    style = parser.add_argument_group("styling")
    style.add_argument("--primary-color", help="Primary brand color (hex, e.g., #1e3a5f)")
    style.add_argument("--primary-dark-color", help="Primary dark variant (hex)")
    style.add_argument("--accent-color", help="Accent color (hex)")
    style.add_argument(
        "--custom-css",
        type=Path,
        help="Path to additional CSS file for brand overrides",
    )

    # Layout options
    layout = parser.add_argument_group("layout")
    layout.add_argument(
        "--no-toc",
        action="store_true",
        help="Omit table of contents",
    )
    layout.add_argument(
        "--no-cover",
        action="store_true",
        help="Omit cover page",
    )

    # Template override
    parser.add_argument(
        "--template-dir",
        type=Path,
        help="Path to custom template directory (must contain whitepaper.html + whitepaper.css)",
    )

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    # Validate input
    if not args.input.exists():
        print(f"Error: Input file not found: {args.input}", file=sys.stderr)
        return 1

    # Resolve template directory
    if args.template_dir:
        template_dir = args.template_dir.resolve()
    else:
        # Default: templates/ directory next to this script's skill
        script_dir = Path(__file__).resolve().parent
        template_dir = script_dir.parent / "skills" / "whitepaper" / "templates"
        if not template_dir.exists():
            # Fallback: check relative to cwd in cc-framework structure
            template_dir = Path.cwd() / "core" / "skills" / "whitepaper" / "templates"

    if not template_dir.exists():
        print(f"Error: Template directory not found: {template_dir}", file=sys.stderr)
        print("Use --template-dir to specify the template location.", file=sys.stderr)
        return 1

    # Read markdown
    md_text = args.input.read_text(encoding="utf-8")

    # Preprocess: strip header block, extract metadata
    cleaned_md, metadata = preprocess_markdown(md_text)

    # Convert cleaned markdown to HTML
    body_html, toc_items = convert_markdown(cleaned_md)

    # Post-process HTML
    body_html = post_process_html(body_html)

    # Render full HTML
    full_html = render_html(body_html, toc_items, metadata, template_dir, args)

    # Ensure output directory exists
    args.output.parent.mkdir(parents=True, exist_ok=True)

    # Generate PDF
    print(f"Rendering {args.input.name} → {args.output.name} ...", file=sys.stderr)
    generate_pdf(full_html, args.output, template_dir)
    print(f"Done: {args.output}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
