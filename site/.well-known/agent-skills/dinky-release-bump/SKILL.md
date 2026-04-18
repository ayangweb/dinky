---
name: dinky-release-bump
description: Checklist for keeping Dinky release strings in sync across repo and site.
---

# Dinky — release string bump

When shipping a new **X.Y.Z** DMG to GitHub Releases, update every pinned reference together:

1. **site/index.html** — `<title>`, meta descriptions, JSON-LD `downloadUrl` / `softwareVersion`, download button `href`, visible version line.
2. **site/llms.txt** — “Download v…” link.
3. **site/homepage.md** — Download bullet and version line.
4. **README.md** — if it embeds a specific DMG URL (optional; prefer `releases/latest` in prose when possible).

Search the repo for the **previous** version number to catch stragglers.
