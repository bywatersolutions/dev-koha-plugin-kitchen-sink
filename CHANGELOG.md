# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.6.1] - 2025-08-14
### Changed
- Modernize build system with Gulp 4.x and async/await patterns
- Replace increment_version.js with npm version workflow for automated releases
- Update package.json with modern npm scripts and clean dependencies
- Remove legacy deploy.sh script in favor of GitHub Actions releases
- Add comprehensive development documentation to README
- Simplify and modernize gulpfile.js structure
- Add proper .gitignore for node_modules and build artifacts

### Added
- npm scripts for version management and kpz filename generation
- Automated version updating in plugin files via preversion hook
- Development and release workflow documentation

### Removed
- increment_version.js (replaced by npm version workflow)
- deploy.sh (replaced by GitHub Actions)
- Unused dependencies and package.json overrides

## [2.6.0] - 2025-08-14
### Changed
- Modernize GitHub Actions workflow
- Update actions/checkout from v1 to v4
- Update bywatersolutions/github-action-koha-get-version-by-label from @master to @v2
- Update bywatersolutions/github-action-koha-plugin-create-kpz from @master to @v3
- Replace deprecated ::set-output with $GITHUB_OUTPUT syntax
- Migrate from manual Docker setup to koha-testing-docker (KTD)
- Improve test execution with prove recursive and shuffle options
- Add proper error handling and container lifecycle management
- Remove extensive debug output for cleaner CI logs
- Eliminate all GitHub Actions deprecation warnings
- Update workflow and scripts to use main as default branch instead of master

## [2.1.43] - 2021-03-01
### Changed
- Updated Koha community git repo address
- Added plugin hook for nightly actions

## [2.1.37] - 2020-04-15
### Changed
- A bug in github-action-koha-plugin-create-kpz meant the README.md and CHANGELOG.md files were not added to the kpz file. This should now be fixed.

## [2.1.36] - 2020-04-15
### Added
- Added CHANGELOG.md and README.md to release artifacts.

### Changed
- A bug in github-action-koha-plugin-create-kpz meant the README.md and CHANGELOG.md files were not added to the kpz file. This should now be fixed.

## [2.1.35] - 2020-04-15
### Added
- Added this changelog.

### Changed
- No changes in this release.

### Removed
- No removals in this release.
