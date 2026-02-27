# Julia Registry Release & Registration

This project is prepared for registration in a Julia registry (General or a private registry).

## One-time repository setup

Set these GitHub Actions secrets in your repository settings:

- `DOCUMENTER_KEY` (SSH private key) for docs deployment on tag builds and TagBot tag pushes.
- `COMPATHELPER_PRIV` (SSH private key) for CompatHelper pull requests.

Already configured workflows:

- `CI` (`.github/workflows/ci.yml`) runs tests on PRs and pushes.
- `Documentation` (`.github/workflows/docs.yml`) builds docs and deploys on `main` and tags.
- `TagBot` (`.github/workflows/TagBot.yml`) creates Git tags/releases after registry merges.
- `CompatHelper` (`.github/workflows/CompatHelper.yml`) opens compatibility update PRs.

## Pre-registration checklist

- Ensure `Project.toml` has `name`, `uuid`, `version`, and `[compat]` bounds.
- Run tests locally:

```julia
using Pkg
Pkg.test()
```

- Push changes to the default branch (`main`).

## Register a release with Registrator

1. Bump `version` in `Project.toml` (for example, from `0.1.0` to `0.1.1`).
2. Commit and push the version bump.
3. Open the commit or PR on GitHub and comment:

```text
@JuliaRegistrator register
```

Optional release notes:

```text
@JuliaRegistrator register
Release notes:
- Add CI + TagBot + CompatHelper workflows
- Improve registration documentation
```

4. Wait for the registry PR to be opened and merged.
5. After merge, TagBot creates the corresponding tag/release.

## For private registries

Use the same process but point Registrator to your registry in the comment, e.g.:

```text
@JuliaRegistrator register registry=YourOrg/YourRegistry
```
