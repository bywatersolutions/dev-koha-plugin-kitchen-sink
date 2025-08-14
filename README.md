# Introduction

The Kitchen Sink plugin for Koha is meant to be an exhaustive example of all the features a Koha plugin can posses.

If you find any plugin hooks are missing, please let us know by filing a GitHub Issue!

# Downloading

From the [release page](https://github.com/bywatersolutions/koha-plugin-kitchen-sink/releases) you can download the relevant *.kpz file

# Installing

Koha's Plugin System allows for you to add additional tools and reports to Koha that are specific to your library. Plugins are installed by uploading KPZ ( Koha Plugin Zip ) packages. A KPZ file is just a zip file containing the perl files, template files, and any other files necessary to make the plugin work.

The plugin system needs to be turned on by a system administrator.

To set up the Koha plugin system you must first make some changes to your install.

* Change `<enable_plugins>0<enable_plugins>` to `<enable_plugins>1</enable_plugins>` in your koha-conf.xml file
* Confirm that the path to `<pluginsdir>` exists, is correct, and is writable by the web server
* Restart your webserver

Once set up is complete you will need to alter your UseKohaPlugins system preference. On the Tools page you will see the Tools Plugins and on the Reports page you will see the Reports Plugins.

# Development

## Building the Plugin

The plugin uses a modern Gulp-based build system:

```bash
# Install dependencies
npm install

# Build the plugin kpz file
npm run build
```

## Available npm Scripts

- `npm run kpz` - Print the kpz filename for the current version
- `npm run print-name` - Print the package name
- `npm run build` - Build the plugin (via Gulp)

# Releasing New Versions

This plugin supports two release workflows: **Command Line** (recommended for developers) and **GitHub UI** (for maintainers).

## Method 1: Command Line Release (Recommended)

Use `npm version` for automated release management. This approach ensures consistent versioning and eliminates manual errors.

### Creating a Release

```bash
# Create a new patch release (e.g., 2.6.0 -> 2.6.1)
npm version patch

# Create a new minor release (e.g., 2.6.0 -> 2.7.0)
npm version minor

# Create a new major release (e.g., 2.6.0 -> 3.0.0)
npm version major
```

### What Happens Automatically

When you run `npm version`, the following occurs automatically:

1. **Version Update**: Updates the version in `package.json`
2. **Plugin File Update**: Updates the `$VERSION` variable in the main plugin file
3. **Git Commit**: Creates a commit with the version change
4. **Git Tag**: Creates a git tag for the new version

### Publishing the Release

After running `npm version`, push the changes and tag to trigger the automated release:

```bash
# Push changes and tags to GitHub
git push origin main --follow-tags
```

This will trigger the GitHub Actions workflow to:
1. Run tests on all supported Koha versions
2. Build the kpz file
3. Create a GitHub release with the kpz file attached

## Method 2: GitHub UI Release

Maintainers can also create releases directly through GitHub's web interface:

1. **Go to Releases**: Navigate to the [Releases page](https://github.com/bywatersolutions/koha-plugin-kitchen-sink/releases)
2. **Create Release**: Click "Create a new release"
3. **Set Tag**: Create a new tag following the format `v2.6.2` (with 'v' prefix)
4. **Add Details**: Fill in release title and description
5. **Publish**: Click "Publish release"

### What Happens Automatically

When you create a release through GitHub UI:

1. **Version Sync**: GitHub Actions automatically syncs the version to `package.json` and plugin file
2. **Build**: Builds the kpz file
3. **Upload**: Attaches the kpz file to the release

**Note**: The version sync workflow will commit the version changes back to the main branch.

## Version Guidelines

- **Patch** (x.x.1): Bug fixes, small improvements
- **Minor** (x.1.x): New features, backwards-compatible changes  
- **Major** (1.x.x): Breaking changes, major rewrites

## Tag Format

- **Command Line**: Creates tags like `v2.6.1` automatically
- **GitHub UI**: Use format `v2.6.1` (with 'v' prefix) for consistency

The automated workflows ensure that every release is properly tested, versioned, and documented regardless of which method you choose.
