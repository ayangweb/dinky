# Publishing testimonials on dinkyfiles.com

Quotes come from [GitHub Discussions — Reviews](https://github.com/heyderekj/dinky/discussions/categories/reviews). Only add entries where the author checked the consent box on the discussion form.

## One-time GitHub setup (repo maintainer)

1. **Settings → General → Features** — enable **Discussions**.
2. **Discussions → Categories** — create a category named **Reviews**, slug `reviews`, format **Open-ended discussion** (so it can use the template in `.github/DISCUSSION_TEMPLATE/review.yml`).
3. Optionally pin a welcome post in that category with a short intro and link to [leave a review](https://github.com/heyderekj/dinky/discussions/new?category=reviews).

## Adding a quote to the site

1. Open a discussion you’re happy to feature (consent checked).
2. Append an object to [`data/testimonials.json`](data/testimonials.json):

| Field | Required | Notes |
|-------|----------|--------|
| `rating` | yes | Integer 1–5 (maps to stars on the page). |
| `quote` | yes | Short testimonial text. |
| `githubUser` | yes | GitHub username — used for the avatar at `https://github.com/<username>.png`. |
| `name` | no | Display name; falls back to `githubUser`. |
| `handle` | no | Shown under the name; if it doesn’t start with `@`, it’s linked as `https://<handle>` unless `handleURL` is set. |
| `handleURL` | no | Overrides the auto link for `handle`. |
| `sourceURL` | no | Link to the discussion; shown as “via GitHub”. |
| `date` | no | For your own records (not rendered today). |

3. Commit and push. Netlify redeploys `site/`; the reviews block appears when the JSON array has at least one entry. An empty array `[]` keeps the section hidden.

Example:

```json
[
  {
    "rating": 5,
    "quote": "Dinky shaved 70% off my hero image without me even thinking about it.",
    "name": "Alex Chen",
    "handle": "alexbuilds.dev",
    "handleURL": "https://alexbuilds.dev",
    "githubUser": "alexc",
    "sourceURL": "https://github.com/heyderekj/dinky/discussions/42",
    "date": "2026-04-18"
  }
]
```
