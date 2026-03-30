# AI Agents Instruction

Canonical instructions for all AI coding assistants. Tool-specific files are symlinks to this file:
- `CLAUDE.md` → `AGENTS.md`
- `.cursorrules` → `AGENTS.md`
- `.github/copilot-instructions.md` → `AGENTS.md`

## Project Overview

Personal website/blog at https://volatilethunk.com, built with [Haunt](https://dthompson.us/projects/haunt.html) 0.3.0, a functional static site generator written in GNU Guile (Scheme). Licensed under GNU AGPL v3.

## Build

All builds run inside Docker — no local Guile/Haunt installation required.

```sh
# Build the Docker image (only needed once or after Dockerfile changes)
docker build -t site-build --load .

# Generate the site into site/
docker run --rm -v "$PWD:/home/user/workspace" site-build

# Publish to S3
aws s3 sync 'site/' 's3://volatilethunk.com' --delete
```

The generated output lands in `site/` (git-ignored). CI runs these steps automatically on push via `.gitlab-ci.yml`.

## Architecture

Everything lives in `haunt.scm`. Haunt's data flow is: **Readers** parse files in `posts/` into `Post` objects (metadata alist + SXML body) → **Builders** receive a `Site` and `Post` list and produce `Artifact` objects → `build-site` writes artifacts to `site/`.

### `haunt.scm` structure

- **Site metadata** (top): `site-title`, `site-domain`, `author`, path prefixes
- **`base-template`**: `<head>` with W3C/OpenGraph/Schema.org meta tags, CSS/feed links
- **`page-template`**: wraps body in site header + nav + `<main>`
- **`volatile-thunk-theme`**: Haunt `theme` object wiring `layout`, `post-template`, `collection-template`
- **`index-page`**: custom landing page built via `serialized-artifact` (not a builder)
- **`volatile-thunk-redirects`**: legacy URL mappings from the old website
- **`(site #:builders ...)`**: registers all builders in order

### Builders registered

1. `index-page` — custom static landing page
2. `blog` — generates individual post pages + the "Articles" collection at `/posts.html`
3. `flat-pages` — renders `pages/` directory (About, Contact) using theme layout
4. `atom-feed` + `atom-feeds-by-tag` — Atom feeds
5. `rss-feed` — RSS at `/index.xml`
6. `static-directory` — copies `static/` to site root
7. `redirects` — generates redirect pages for legacy URLs

### URL structure

Path prefixes (`/posts`, `/pages`) deliberately override Haunt's defaults to match the old website's URL structure and preserve SEO. Posts land at `/posts/<slug>.html`, pages at `/pages/<name>.html`.

## Content Authoring

**New post** — add a Markdown file to `posts/`:

```
title: Your Post Title
date: YYYY-MM-DD HH:MM
tags: tag1, tag2
---
Content in CommonMark Markdown.
```

**New page** (appears in nav) — add a Markdown file to `pages/` with the same metadata format. The filename becomes the URL slug.

**Static assets** go in `static/`; they are copied to the site root. The CV PDF is tracked via Git LFS.

## Haunt-Specific Guidance

### Editing the theme

The theme is pure Scheme returning SXML data structures — not a templating language. `sxml->html` (from `(haunt html)`) serialises SXML to HTML output. CSS lives in `static/style.css` (supports light/dark via `prefers-color-scheme`).

SXML uses S-expressions for HTML. `(p "text")` becomes `<p>text</p>`. Attributes use `@`: `(a (@ (href "/")) "Home")` becomes `<a href="/">Home</a>`. Splicing uses `,@` with quasiquoting.

### Theme template signatures

The `theme` record from `(haunt builder blog)` expects these procedures:

- **`layout`**: `(site title body) → sxml` — outer page wrapper
- **`post-template`**: `(post #:key post-link) → sxml` — single post rendering
- **`collection-template`**: `(site title posts prefix) → sxml` — post listing page
- **`pagination-template`** (optional): adds page navigation when `#:posts-per-page` is set on the `blog` builder

### Available Haunt modules

Key imports already used in this project and available for extension:

| Module | Purpose |
|---|---|
| `(haunt site)` | `site` constructor, accessors (`site-title`, `site-domain`, etc.) |
| `(haunt post)` | `post-ref`, `post-date`, `post-tags`, `post-sxml`, `posts/reverse-chronological`, `posts/group-by-tag` |
| `(haunt reader commonmark)` | `commonmark-reader` for Markdown files |
| `(haunt builder blog)` | `blog`, `theme` constructors |
| `(haunt builder flat-pages)` | `flat-pages` for non-blog pages |
| `(haunt builder atom)` | `atom-feed`, `atom-feeds-by-tag` |
| `(haunt builder rss)` | `rss-feed` |
| `(haunt builder assets)` | `static-directory` |
| `(haunt builder redirects)` | `redirects` builder |
| `(haunt artifact)` | `serialized-artifact`, `make-artifact`, `verbatim-artifact` |
| `(haunt html)` | `sxml->html` serialisation |
| `(haunt asset)` | `directory-assets` (lower-level; prefer `static-directory`) |

### Custom builders

Any procedure `(lambda (site posts) ...)` returning a list of artifacts can be a builder. For one-off pages (like `index-page`), use `serialized-artifact` with `sxml->html` as the serialiser. For copying files, use `verbatim-artifact`.

### Legacy redirects

Extend `volatile-thunk-redirects` in `haunt.scm`. Use the `redirect` helper lambda for standard date-based paths (`/posts/YYYY/MM/DD/slug/post.html` → `/posts/slug.html`). Specify source and destination manually for non-standard path formats. New posts do not need redirect entries.

### Post metadata

Haunt parses `key: value` lines before the `---` separator. Built-in metadata parsers handle `tags` (comma-separated) and `date` (via `string->date*`). Custom parsers can be added with `register-metadata-parser!` from `(haunt post)`. The `post-slug` procedure generates URL slugs from titles by lowercasing and replacing spaces with hyphens.

### Gotchas

- The `(srfi srfi-19)` import is duplicated in `haunt.scm` (both comments say different things); only dates/times is actually used.
- `flat-pages` reuses the blog theme's layout via `theme-layout`, so changes to `page-template` affect both blog posts and flat pages.
- The `static-dest-path` is set to `"."` so `static/` contents land at the site root, not under a `static/` subdirectory.
- Haunt's default `make-slug` can differ from `post-slug-v2`; this project uses the default slug generation, which keeps consecutive hyphens (e.g. "go--rust" stays as-is).
