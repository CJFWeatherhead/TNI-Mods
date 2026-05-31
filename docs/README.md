# Tower Networking Inc - Website Documentation

This directory contains the Hugo-based website and documentation hub for the TNI-Mods repository.

## Structure

- `content/` - Markdown content for pages
  - `_index.md` - Homepage
  - `mods/` - Mod documentation pages
    - `_index.md` - Mods listing page
    - `<mod-name>.md` - Individual mod pages (auto-generated)
    - `tools/` - Tools documentation
      - `modmanager.md` - Mod Manager documentation
- `themes/terminal/` - Hugo Terminal theme (git submodule)
- `hugo.toml` - Hugo configuration
- `generate_mod_pages.py` - Script to generate mod pages from metadata.yaml files

## Building Locally

### Prerequisites

1. Install Hugo Extended (v0.139.4 or later):
   - Download from: https://github.com/gohugoio/hugo/releases
   - Ensure it's the "extended" version for SCSS support

2. Install Python 3 and PyYAML:
   ```bash
   pip install pyyaml
   ```

### Build Steps

1. Clone the repository with submodules:
   ```bash
   git clone --recursive https://github.com/CJFWeatherhead/TNI-Mods.git
   cd TNI-Mods
   ```

2. Generate mod pages from metadata:
   ```bash
   cd docs
   python3 generate_mod_pages.py
   ```

3. Build the site:
   ```bash
   hugo
   ```
   
   The built site will be in `docs/public/`

4. Or run a local development server:
   ```bash
   hugo server -D
   ```
   
   Then visit http://localhost:1313

## Deployment

The website is automatically deployed to Cloudflare Pages via GitHub Actions when:
- Changes are pushed to the `main` branch
- Changes affect the `docs/` or `mods/` directories
- The workflow is manually triggered

### Cloudflare Pages Setup

To set up deployment, you need to configure these GitHub secrets:

1. `CLOUDFLARE_API_TOKEN` - API token with Cloudflare Pages permissions
2. `CLOUDFLARE_ACCOUNT_ID` - Your Cloudflare account ID

The deployment workflow:
1. Checks out the repository with submodules
2. Sets up Hugo and Python
3. Generates mod pages from `mods/*/metadata.yaml` files
4. Builds the Hugo site
5. Deploys to Cloudflare Pages

## Adding/Updating Mods

Mod pages are automatically generated from the metadata in the `mods/` directory. To add or update a mod:

1. Create or update the mod folder in `mods/<mod-name>/`
2. Ensure it has:
   - `metadata.yaml` - Following the schema in `/mod-metadata-schema.yaml`
   - `README.md` - Detailed documentation
   - `entry.lua` - The mod code
3. Run `python3 generate_mod_pages.py` to regenerate pages
4. Commit and push - the website will auto-deploy

## Updating Documentation

To update the main pages:

1. Edit files in `docs/content/`:
   - `_index.md` - Homepage
   - `mods/_index.md` - Mods listing
   - `mods/tools/modmanager.md` - Mod Manager docs
2. Run `hugo server` to preview
3. Commit and push to deploy

## Theme Customization

The site uses the [Terminal theme](https://github.com/panr/hugo-theme-terminal). To customize:

1. Colors and basic settings: Edit `hugo.toml`
2. Advanced customization: Override theme templates in `layouts/`
3. CSS changes: Create custom styles in `assets/`

## URL Structure

- Homepage: `https://tower.networking.ink/`
- Mods listing: `https://tower.networking.ink/mods/`
- Individual mod: `https://tower.networking.ink/mods/<mod-name>/`
- Mod Manager: `https://tower.networking.ink/mods/tools/modmanager/`

## Maintenance

### Updating the Theme

The Terminal theme is a git submodule. To update:

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

This will scan all mods in `mods/` and regenerate their pages.

## Support

For issues with the website:
- Check Hugo logs: `hugo --verbose`
- Verify Python script: `python3 generate_mod_pages.py`
- Review GitHub Actions logs for deployment issues

For mod-specific issues, refer to the main [repository README](../README.md).
