# Folio – Ruby on Rails CMS Engine

Folio is an open-source engine that turns any Rails application into a modern, multi-site CMS with a beautiful admin console, modular content blocks, and a rich set of generators.

*Build pages from reusable blocks. Scaffold admin UIs in seconds. Keep full control of the code.*

---

## Why Folio?

• **Productive** – Generators for pages, components, mailers, blog, search, …  
• **Flexible** – Compose pages from CMS blocks (Atoms) rendered by ViewComponent.  
• **Modern** – Console UI built with Stimulus & ViewComponent, ready for Turbo.  
• **Ruby First** – 100 % Ruby / Slim / SASS, no proprietary DSLs.  
• **Upgrade-safe** – Override via `app/overrides/`, keep your customisations isolated.

---

## Development Setup

### System Requirements

**Core Requirements:**
- Ruby 3.0+ (recommended: 3.3+)
- Rails 7.0+
- PostgreSQL 12+ (with JSONB support)
- Redis (for background jobs and caching)
- Node.js 16+ (for React components)

### Image & Media Processing Tools

**Required:**
- `imagemagick` or `vips` - Image resizing and thumbnails

**Optional but recommended:**
- `exiftool` - EXIF/IPTC metadata extraction from images
- `gifsicle` - Animated GIF optimization
- `ffmpeg` - Video/audio file processing and thumbnails

**Installation on macOS:**
```bash
# Using Homebrew
brew install imagemagick vips gifsicle exiftool ffmpeg
```

**Installation on Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install imagemagick libvips-tools gifsicle libimage-exiftool-perl ffmpeg
```

**Installation on RedHat/CentOS:**
```bash
sudo yum install ImageMagick vips gifsicle perl-Image-ExifTool ffmpeg
```

**Optional Dependencies:**
- `exiftool` - Required only if you want automatic EXIF/IPTC metadata extraction
- `gifsicle` - Required only for animated GIF optimization
- `ffmpeg` - Required only for video/audio processing

**Cloud Storage (optional):**
- AWS S3 or compatible storage (MinIO, DigitalOcean Spaces, etc.) for file storage
- Configure with AWS credentials in your environment

**Testing Dependencies:**
- ChromeDriver or Selenium for system tests
- Additional test databases can be configured for parallel testing

**Verifying Installation:**
```bash
# Check installed tools
which convert      # ImageMagick
which vips        # Vips
which gifsicle    # Gifsicle
which exiftool    # ExifTool
which ffmpeg      # FFmpeg

# Check versions
convert -version
vips --version
gifsicle --version
exiftool -ver
ffmpeg -version
```

**Note:** Core image processing (thumbnails, resizing) requires either ImageMagick or Vips. Other tools are optional but recommended for full functionality.

### Installing Yarn (for React components)

The project includes React components in the `react/` directory. To work with these, you need Yarn package manager:

**Recommended (via Corepack):**
```bash
# Enable corepack (included with Node.js 16+)
corepack enable

# Install Yarn 1.x (compatible with existing yarn.lock)
corepack prepare yarn@1.22.22 --activate

# Install React dependencies
cd react && yarn install
```

**Alternative (via npm):**
```bash
npm install --legacy-peer-deps
```

**Note for macOS users:** If you encounter dependency conflicts, use the `--legacy-peer-deps` flag with npm or ensure you're using Yarn 1.x (not Yarn 4.x) to maintain compatibility with existing lockfiles.

### Working with React in Folio

React is used for administrating atoms. All React files are stored in the `react/` subfolder. Folio controls React via yarn as a regular SPA. Folio doesn't use webpacker or similar but expects you to build a dist version which is then included in the git repo as a regular asset.

**Developing React parts in Folio:**

To run the React development server:
```bash
cd react && yarn start
```

**Note for Node.js 17+ users:** If you encounter OpenSSL errors with newer Node.js versions, use:
```bash
cd react && NODE_OPTIONS="--openssl-legacy-provider" yarn start
```

When editing files, you should also run the linter and tests:
```bash
cd react && yarn standard  # Linter
cd react && yarn test      # Tests
```

For Rails to use the live React version, set the `REACT_DEV` environment variable:
```bash
REACT_DEV=1 rails s
```

**Building React for production:**

Once you're happy with the changes, you need to manually build the React SPA:
```bash
cd react && yarn build
```

**Note for Node.js 17+ users:** If build fails with OpenSSL errors, use:
```bash
cd react && NODE_OPTIONS="--openssl-legacy-provider" yarn build
```

This creates a dist version of the React SPA and copies the dist files to `app/assets/*/folio/console/react.*`.

---

## Quick Installation

```bash
bundle add folio dragonfly_libvips view_component
rails generate folio:install
rails db:migrate
rails server
```
Open <http://localhost:3000/console> and log in with the credentials printed by the installer seed.

---

## Documentation

Full English documentation lives in the `docs/` folder:

| Topic | File |
|-------|------|
| Overview | [docs/overview.md](docs/overview.md) |
| Architecture | [docs/architecture.md](docs/architecture.md) |
| Components | [docs/components.md](docs/components.md) |
| CMS Blocks (Atoms) | [docs/atoms.md](docs/atoms.md) |
| Admin Console | [docs/admin.md](docs/admin.md) |
| Help Documents | [docs/help_documents.md](docs/help_documents.md) |
| Files & Media | [docs/files.md](docs/files.md) |
| Forms | [docs/forms.md](docs/forms.md) |
| Emails & Templates | [docs/emails.md](docs/emails.md) |
| Configuration | [docs/configuration.md](docs/configuration.md) |
| Testing | [docs/testing.md](docs/testing.md) |
| Troubleshooting | [docs/troubleshooting.md](docs/troubleshooting.md) |
| Upgrade & Migration | [docs/upgrade.md](docs/upgrade.md) |
| Extending & Customisation | [docs/extending.md](docs/extending.md) |
| Concerns | [docs/concerns.md](docs/concerns.md) |
| Jobs | [docs/jobs.md](docs/jobs.md) |
| Seeding | [docs/seeding.md](docs/seeding.md) |
| Sitemaps | [docs/sitemap.md](docs/sitemap.md) |
| FAQ | [docs/faq.md](docs/faq.md) |

Start with the [Overview](docs/overview.md) and follow the *Quick Start* guide.

---

## Contributing

1. Fork the repo and create your branch (`git checkout -b feature/my-thing`).
2. Run the dummy app for development: `bundle exec rails app:folio:prepare_dummy_app`.
3. Commit your changes (`git commit -am 'Add new thing'`).
4. Push the branch (`git push origin feature/my-thing`).
5. Open a Pull Request.

See `docs/testing.md` for the test setup.

---

## License

Folio is released under the MIT License – see `LICENSE` for details.
