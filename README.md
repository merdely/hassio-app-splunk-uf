# Splunk Universal Forwarder — Home Assistant Add-on Repository

[![Build & Publish Add-on](https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME/actions/workflows/build.yml/badge.svg)](https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME/actions/workflows/build.yml)

Home Assistant add-on repository for the **Splunk Universal Forwarder**.

Supported architectures: **amd64** · **aarch64 (arm64)**

---

## Adding this repository to Home Assistant

1. **Settings → Add-ons → Add-on Store → ⋮ → Repositories**
2. Paste your repository URL and click **Add → Close**
3. **Splunk Universal Forwarder** will appear in the store

---

## First-time setup

### 1. Fork / clone and replace placeholders

Find-and-replace `YOUR_GITHUB_USERNAME/YOUR_REPO_NAME` in:

- `repository.yaml`
- `splunk-universal-forwarder/config.yaml`

### 2. Push to `main`

GitHub Actions builds a multi-arch manifest (`linux/amd64` + `linux/arm64`)
and publishes it to:

```
ghcr.io/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME/splunk-universal-forwarder:latest
```

### 3. Make the package public

GitHub profile → **Packages** → `splunk-universal-forwarder` →
**Package settings → Change visibility → Public**

---

## Design notes

The add-on is a thin layer on top of the official `splunk/universalforwarder`
image (Red Hat UBI8-based). Rather than adding a second init system, it
delegates process management to the Splunk image's own
`/sbin/entrypoint.sh start-service`, which runs `splunkd` natively in the
foreground. The only addition is a small `run.sh` that reads Home Assistant's
`options.json` and exports the `SPLUNK_*` environment variables the official
entrypoint already understands.
