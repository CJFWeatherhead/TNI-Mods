# Tower Networking Inc - Website Setup Guide

This document explains the Hugo-based website implementation for the TNI-Mods repository.

## Overview

The website is built with Hugo static site generator and uses the Terminal theme for a retro, terminal-style aesthetic. It automatically generates documentation pages for all mods from their metadata.yaml files.

## Website Structure

```
https://tower.networking.ink/
├── /                          # Homepage with project overview
├── /mods/                     # Mods listing page
│   ├── /2x-bandwidth-switches/
│   ├── /all-proposals/
│   ├── /device-tweaker/
│   ├── /floor-reward-scaling/
│   ├── /inverse-prices/
│   ├── /modapi-diagnostic/
│   ├── /money-cheat/
│   ├── /random-warranties/
│   ├── /user-floor-addressing/
│   └── /tools/
│       └── /modmanager/       # Mod Manager documentation
└── /github                    # Link to repository
```

## Repository Structure

```
docs/
├── hugo.toml                  # Hugo configuration
├── generate_mod_pages.py      # Script to generate mod pages
├── README.md                  # Documentation for the website
├── .gitignore                 # Exclude build artifacts
├── content/                   # Markdown content
│   ├── _index.md             # Homepage
│   └── mods/
│       ├── _index.md         # Mods listing
│       ├── *.md              # Individual mod pages (auto-generated)
│       └── tools/
│           ├── _index.md     # Tools listing
│           └── modmanager.md # Mod Manager guide
├── themes/
│   └── terminal/             # Terminal theme (git submodule)
└── public/                   # Built site (ignored by git)
```

## How It Works

### 1. Mod Page Generation

The `docs/generate_mod_pages.py` script:
- Scans all directories in `lua/`
- Reads each mod's `metadata.yaml` file
- Generates a Hugo markdown page with:
  - Mod description and features
  - Author and version info
  - Download links
  - Configuration parameters
  - Full README content
  - Installation instructions

### 2. Hugo Site Building

Hugo processes:
- The Terminal theme for styling
- Markdown content files
- Configuration from `hugo.toml`
- Generates static HTML/CSS/JS in `public/`

### 3. Automatic Deployment

The GitHub Actions workflow (`.github/workflows/deploy-website.yml`):
1. Triggers on pushes to `main` or `beta` branches
2. Sets up Hugo and Python
3. Runs `generate_mod_pages.py` to create mod pages
4. Builds the Hugo site
5. Deploys to Cloudflare Pages

## Setup Instructions

### Prerequisites

1. **Hugo Extended** (v0.139.4 or later)
   - Download from: https://github.com/gohugoio/hugo/releases
   - Must be the "extended" version for SCSS support

2. **Python 3** with PyYAML
   ```bash
   pip install pyyaml
   ```

3. **Git** with submodules initialized
   ```bash
   git submodule update --init --recursive
   ```

### Local Development

```bash
# Navigate to docs directory
cd docs

# Generate mod pages from metadata
python3 generate_mod_pages.py

# Build the site
hugo

# Or run development server
hugo server
# Visit http://localhost:1313
```

### Deployment Setup

#### Cloudflare Pages

1. **Create Cloudflare Pages Project**
   - Log in to Cloudflare Dashboard
   - Go to Pages > Create a project
   - Connect your GitHub repository
   - Project name: `tower-networking-ink`

2. **Configure GitHub Secrets**
   - Go to repository Settings > Secrets and variables > Actions
   - Add these secrets:
     - `CLOUDFLARE_API_TOKEN`: API token with Cloudflare Pages permissions
     - `CLOUDFLARE_ACCOUNT_ID`: Your Cloudflare account ID

3. **Custom Domain**
   - In Cloudflare Pages project settings
   - Add custom domain: `tower.networking.ink`
   - Configure DNS records as instructed

## Adding New Mods

When you add a new mod:

1. Create the mod directory in `lua/<mod-name>/`
2. Add required files:
   - `metadata.yaml` (following the schema)
   - `README.md`
   - `entry.lua`
3. Push to GitHub
4. The website will automatically regenerate and deploy

The mod page will appear at: `https://tower.networking.ink/mods/<mod-name>/`

## Updating Existing Mods

To update a mod's documentation:

1. Edit `lua/<mod-name>/metadata.yaml` or `README.md`
2. Commit and push changes
3. The website automatically rebuilds and deploys

## Updating Website Content

### Homepage
Edit `docs/content/_index.md`

### Mods Listing
Edit `docs/content/mods/_index.md`

### Mod Manager Guide
Edit `docs/content/mods/tools/modmanager.md`

### Theme Settings
Edit `docs/hugo.toml`

## Troubleshooting

### Mod pages not generating
- Check that `metadata.yaml` is valid YAML
- Ensure required fields are present (Name, Description, Author, etc.)
- Run `python3 generate_mod_pages.py` and check for errors

### Hugo build fails
- Verify Hugo version: `hugo version` (should be 0.139.4+)
- Check for theme issues: `cd themes/terminal && git status`
- Ensure submodules are initialized: `git submodule update --init --recursive`

### Deployment fails
- Check GitHub Actions logs
- Verify secrets are set correctly
- Ensure Cloudflare API token has proper permissions

### Local preview not working
- Clear Hugo cache: `rm -rf resources/ public/`
- Rebuild: `hugo server --disableFastRender`

## Maintenance

### Updating the Theme

```bash
cd docs/themes/terminal
git pull origin master
cd ../../..
git add docs/themes/terminal
git commit -m "Update Terminal theme"
```

### Regenerating All Pages

```bash
cd docs
python3 generate_mod_pages.py
```

This will scan all mods in `lua/` and regenerate their pages.

## Features

- ✅ Automatic mod page generation from metadata
- ✅ Responsive Terminal theme design
- ✅ Full-text search (via Hugo)
- ✅ Fast static site (no backend required)
- ✅ SEO-friendly URLs and metadata
- ✅ Automatic deployment on git push
- ✅ Version control for all content
- ✅ Markdown-based content (easy to edit)
- ✅ Support for all parameter types (boolean, integer, number, string, select)

## Security

- No security vulnerabilities detected by CodeQL
- Static site (no dynamic code execution)
- All content version-controlled
- HTTPS via Cloudflare

## Support

For issues:
- Website content: Edit files in `docs/content/`
- Mod pages: Check `lua/*/metadata.yaml`
- Theme issues: Check Terminal theme repository
- Deployment: Review GitHub Actions logs

---

**Website**: https://tower.networking.ink
**Repository**: https://github.com/CJFWeatherhead/TNI-Mods
**Theme**: https://github.com/panr/hugo-theme-terminal
