<p align="center">
  <img src=".github/storyfox-hero.png" width="520" alt="StoryFox — AI-powered illustrated children's storybooks" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.7.1-D4654A" alt="Version" />
  <img src="https://img.shields.io/badge/platform-macOS%2026-blue" alt="Platform" />
  <img src="https://img.shields.io/badge/swift-6.2-F05138" alt="Swift" />
  <img src="https://img.shields.io/badge/Apple%20Intelligence-required-black?logo=apple" alt="Apple Intelligence" />
</p>

<p align="center">
  <a href="https://github.com/jakerains/StoryFox/releases/latest/download/StoryFox.dmg">
    <img src="https://img.shields.io/badge/%E2%AC%87%EF%B8%8F_Download_for_Mac-StoryFox.dmg-D4654A?style=for-the-badge&logo=apple&logoColor=white" alt="Download for Mac" />
  </a>
</p>
<p align="center">
  <sub>Signed &amp; notarized &bull; Requires macOS 26 on Apple Silicon &bull; <a href="https://storyfox.app">storyfox.app</a> &bull; <a href="https://storyfox.app/changelog">Changelog</a></sub>
</p>

---

StoryFox generates complete illustrated children's storybooks using a blend of on-device and cloud AI. Type a story idea, pick a style, and get a fully illustrated book with text, cover art, and export to PDF or EPUB — all in minutes.

## How It Works

```
  Your idea          Two-pass text generation       AI image generation       Finished book
 +-----------+      +------------------------+     +--------------------+    +--------------+
 | "A brave  |      | Pass 1: Story text     |     | ImagePlayground    |    |  Title page  |
 |  little   | ---> | Pass 2: Art direction  | --> | Hugging Face FLUX  | -->|  8+ pages    |
 |  robot"   |      | (full narrative context)|    |                    |    |  Cover art   |
 +-----------+      +------------------------+     +--------------------+    |  PDF / EPUB  |
                     FoundationModels | MLX | HF                             +--------------+
```

1. **Describe your story** — a concept, theme, or opening line
2. **Choose your settings** — page count (4-16), book format, illustration style
3. **Watch it generate** — text streams in real-time, then illustrations render concurrently
4. **Read and export** — flip through pages, then export as print-ready PDF or fixed-layout EPUB

## Features

### Two-Pass Story Generation

Every text generator uses a two-pass pipeline for higher-quality illustrations:

- **Pass 1** — The AI writes the complete story text, character descriptions, and narrative arc
- **Pass 2** — With the full manuscript in hand, the AI writes illustration prompts that maintain visual consistency across all pages

This means page 1's illustration knows what happens on page 8 — characters look the same throughout, and visual motifs thread cohesively through the story.

### Guided Creation

Switch between **Quick** mode (type and go) and **Guided** mode, where the AI asks follow-up questions across multiple rounds to flesh out characters, plot, and tone before generating.

### Text Generation

| Provider | Type | Description |
|----------|------|-------------|
| **Apple FoundationModels** | On-device | Apple's ~3B parameter LLM via `@Generable` structured output — no API key needed |
| **MLX Swift** | On-device | Run open-weight models locally (Qwen3, LFM2.5) via Hugging Face Hub |
| **Hugging Face Inference** | Cloud | Access larger cloud models (GPT-OSS 120B, Qwen3 32B, DeepSeek V3, and more) |

### Image Generation

| Provider | Type | Description |
|----------|------|-------------|
| **Image Playground** | On-device | Apple's built-in diffusion model — illustration, animation, and sketch styles |
| **Hugging Face Inference** | Cloud | FLUX.1-schnell, HunyuanImage 3.0, SD 3.5 Medium, and more via HF's native inference endpoint |

### Character Consistency

StoryFox generates a character sheet before creating illustrations. Each character's species, colors, clothing, and distinguishing features are mechanically injected into every image prompt — so your brave little fox looks the same on every page.

If the AI returns weak character descriptions, an async validator repairs them using Foundation Model or heuristic fallback extraction.

### Book Formats

| Format | Size | Best For |
|--------|------|----------|
| Standard Square | 8.5" x 8.5" | Classic picture books |
| Landscape | 11" x 8.5" | Panoramic illustrations |
| Portrait | 8.5" x 11" | Tall storybooks |
| Small Square | 6" x 6" | Mini board books |

### Illustration Styles

- **Illustration** — classic children's book art with painterly details and soft shading
- **Animation** — Pixar-inspired cartoon style with rounded shapes and cinematic lighting
- **Sketch** — hand-drawn pencil lines with gentle watercolor fill

### Export

- **PDF** — 300 DPI print-ready with embedded cover, story pages, and end page
- **EPUB** — Fixed-layout EPUB 3.0 for Apple Books, Kindle, and other readers
- Save anywhere via the macOS system file picker

### Auto-Update

StoryFox uses Sparkle 2 for automatic updates. New versions are signed with EdDSA, notarized by Apple, and delivered as DMGs via GitHub Releases. The app checks for updates on launch — no manual action needed.

### Issue Reporting

When Image Playground's safety filters reject illustrations, a **Report Issue** button appears in the reader toolbar. It bundles the story, images, and diagnostic logs into a zip and uploads them for investigation.

## Requirements

- **macOS 26** (Tahoe) on Apple Silicon
- **Apple Intelligence** enabled on your device
- **Xcode 26** with macOS 26 SDK (to build from source)
- **XcodeGen** — `brew install xcodegen`

Cloud features (optional):
- Free Hugging Face account for cloud text and image generation
- Supports both API tokens and OAuth device flow login

## Quick Start

### Download (macOS)

Grab the latest signed & notarized DMG from [Releases](https://github.com/jakerains/StoryFox/releases/latest), mount it, and drag StoryFox to Applications.

### Build from Source

```bash
# Clone
git clone https://github.com/jakerains/StoryFox.git
cd StoryFox

# Check your toolchain
make doctor

# Build and run
make run
```

## Make Commands

| Command | Description |
|---------|-------------|
| `make help` | List all available targets |
| `make doctor` | Check toolchain and SDK readiness |
| `make build` | Build Debug for macOS |
| `make run` | Build and launch Debug app |
| `make build-release` | Build Release for macOS |
| `make run-release` | Build and launch Release app |
| `make dmg` | Full distribution pipeline: sign, notarize, staple, package DMG |
| `make clean` | Clean Xcode build artifacts |
| `make appcast` | Regenerate `appcast.xml` from DMGs in `dist/` |
| `make sparkle-setup` | One-time EdDSA key pair generation for Sparkle signing |
| `make purge-image-cache` | Remove cached Diffusers model data |

## Architecture

```
StoryFoxApp.swift                       App entry point + NavigationSplitView routing
+-- Shared/
|   +-- Models/                         StoryBook (@Generable), BookFormat, IllustrationStyle,
|   |                                   TextOnlyStoryBook, ImagePromptSheet (two-pass structs)
|   +-- Generation/                     Text & image generators, two-pass pipeline, PDF/EPUB,
|   |                                   prompt templates, content safety, prompt enrichment
|   +-- ViewModels/                     CreationViewModel, BookReaderViewModel
|   +-- Views/Components/              Theme colors, glass-morphism UI, shared controls
|   +-- Utilities/                      Keychain, OAuth, settings, diagnostics, issue reports
+-- macOS/
|   +-- Views/                          Creation, reader, settings, export, test harness
|   +-- SoftwareUpdateManager.swift     Sparkle 2 auto-update wrapper
|   +-- PDFRenderer+macOS.swift         Core Graphics PDF rendering at 300 DPI
+-- landing/                            Next.js 15 landing page (storyfox.app)
```

### Key Patterns

- **`@Observable`** classes with **`@MainActor`** isolation (not `ObservableObject`)
- **`@Generable` + `@Guide`** macros for structured LLM output — no JSON parsing
- **`@Bindable`** in child views (not `@ObservedObject`)
- **Two-pass pipeline**: Pass 1 generates story text, Pass 2 generates image prompts with full narrative context
- **Dual-path cloud**: Hugging Face uses native inference endpoints; other providers use an OpenAI-compatible client
- **Glass-morphism design system** with `SettingsPanelCard`, `sjGlassChip`, and themed color tokens

### Generation Pipeline

```
.creation  -->  .generating  -->  .reading
   |                |                 |
   |  Story idea    |  Pass 1: text   |  Page-by-page reader
   |  Format pick   |  Pass 2: art    |  PDF / EPUB export
   |  Style pick    |  Images render  |  Edit & regenerate
   |  Guided Q&A    |  Progress grid  |  Issue reporting
```

## Signing & Distribution

The `make dmg` target produces a fully signed and notarized DMG:

1. Regenerate project with XcodeGen
2. Archive with Developer ID signing + hardened runtime
3. Export signed `.app`
4. Notarize with Apple (`notarytool submit --wait`)
5. Staple notarization ticket
6. Package DMG with Applications symlink
7. Notarize and staple the DMG itself

Auto-updates are delivered via a [Sparkle 2](https://sparkle-project.org/) appcast hosted on this repo. Use `./scripts/release.sh <version>` for the full automated release pipeline.

## Landing Page

The [storyfox.app](https://storyfox.app) landing page lives in `landing/` and auto-deploys to Vercel on push to main. Built with Next.js 15, Tailwind CSS v4, and Framer Motion, with a design system that mirrors the native app's "Warm Library at Dusk" color palette.

## License

This project is not currently published under an open-source license. All rights reserved.

---

<p align="center">
  Built with SwiftUI, FoundationModels, ImagePlayground, and MLX Swift.<br/>
  <sub>Made with love by <a href="https://jakerains.com">Jake Rains</a></sub>
</p>
