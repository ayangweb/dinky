# PDF compression in Dinky

## Pipelines

- **Flatten (default for new installs)** — Each page is rasterized with PDFKit and re-encoded as JPEG (ImageIO). This is the path that most often produces a smaller file on scans, photos-in-PDF, and mixed documents. Tradeoff: no selectable text or live links.
- **Preserve text and links** — Dinky runs bundled **qpdf** (stream recompression, object streams, optional image optimization) when available, then falls back to a **PDFKit** rewrite. Output is only kept when it is **strictly smaller** than the source. Many exports from modern apps are already optimized; **no size gain is normal** for this mode.

**Skip-if-savings-below (Settings)** applies to **images and video only**, not PDFs: any strictly smaller PDF output is kept so small but real wins (common on preserve) are not discarded.

## Success criteria (product / QA)

| Mode | Expectation |
|------|-------------|
| Flatten | On a **typical camera scan or image-heavy PDF**, output should be smaller than the source with default or Smart Quality. Use fixture types in `tools/pdf_fixtures/README.md` for manual checks. |
| Preserve | Smaller output is **best-effort**. Zero-gain is acceptable when the PDF has little structural slack. |

## Metrics logging

In **Console.app**, select the Dinky process and enable **Debug** logs for the app’s subsystem. Filter for `pdf_metrics`.

- `outcome` — Every successful write from `compressPDF` (includes `savedPct`, `bailout` for flatten tiers).
- `rejected` — Zero-gain after the full attempt chain (`reason` explains which). PDFs are not logged as rejected for sub-threshold savings; that path is image/video-only.

Use this for regression checks before changing DPI/JPEG tiers or Smart Quality heuristics.

## Ship / scope decision

If flatten routinely fails to shrink a representative set of real-world PDFs (see fixtures README), treat that as a release blocker for marketing PDF as “compression.” Options then: further flatten tuning, an additional optimizer, or de-emphasizing PDF in positioning.

Apple does not provide a public, quality-preserving PDF “optimizer” API; structure-preserving wins beyond qpdf typically require specialized tools or accepting flatten.
