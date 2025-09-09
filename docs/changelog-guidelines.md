# Changelog Guidelines

These are the rules for maintaining `CHANGELOG.md` in this project.  
They are written for both humans and AI tools that will help generate and update changelog entries.

---

## Purpose
- The changelog is for **users of the tool**, not contributors.
- It should describe **what changed in usage**, not how the code was implemented.
- Every release must have an entry.

---

## File Location
- Always keep the changelog at the repository root as `CHANGELOG.md`.

---

## Format
- Follow [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) style.
- Use **reverse chronological order** (newest release at the top).
- Each entry has the format:

```markdown
## [x.y.z] - YYYY-MM-DD
### Added
- ...
### Changed
- ...
### Fixed
- ...
### Removed
- ...
### Deprecated
- ...
### Security
- ...
```

- Use **ISO 8601 dates** (`YYYY-MM-DD`).
- If a release is broken or retracted, mark it as `[YANKED]`.

---

## Sections
- **Added**: New features, commands, options.
- **Changed**: Changes to existing features or defaults.
- **Fixed**: Bug fixes that affect user-visible behavior.
- **Removed**: Features, commands, or options that were removed.
- **Deprecated**: Features still present but discouraged; note migration paths.
- **Security**: Vulnerability fixes or security-related changes.

---

## What to Include
✅ Include:
- New commands or flags
- Changed defaults or behaviors
- Breaking changes
- Bug fixes that affect usage
- Platform / compatibility changes
- Security fixes

❌ Exclude:
- Internal refactors, code cleanup
- Test changes, CI/CD changes
- Formatting, style, or non-user-facing modifications

---

## Unreleased Section
- Keep an **Unreleased** section at the top.
- Add entries there as changes are merged.
- On release, copy those entries into a new versioned section and clear Unreleased.

Example:

```markdown
## [Unreleased]

## [1.2.0] - 2025-09-08
### Added
- New `--dry-run` flag
### Fixed
- Crash when running `nnex release` offline
```

---

## References and Linking
- If possible, link PRs or issues: `[#123](https://github.com/owner/repo/pull/123)`.
- Keep links minimal and relevant.

---

## Style
- Write in **plain language**, oriented to users.  
- Use concise, single-sentence bullet points.  
- Start each entry with a verb in past tense (`Added`, `Fixed`, `Removed`).  
- Group similar changes together.  
- Be consistent.

---

## Release Workflow
1. Add user-facing changes to **Unreleased** as they are merged.  
2. On release:
   - Create a new versioned section with the release date.
   - Move Unreleased entries into it.
   - Ensure every release has a section, even if empty.  
3. Update GitHub Releases with the same version section text.

---

## Example Entry

```markdown
# Changelog

## [Unreleased]

## [1.4.0] - 2025-09-08
### Added
- New `nnex changelog` command for generating changelogs automatically.

### Changed
- `nnex release` now outputs binaries to `./dist` by default.

### Fixed
- Error when running `nnex test` without internet connection.
```
