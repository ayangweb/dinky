# Compression Binaries

Place arm64 macOS CLI binaries here. Dinky expects them at:

```
Dinky.app/Contents/Resources/bin/
├── cjpeg      ← MozJPEG
├── cwebp      ← libwebp / Google WebP
├── oxipng     ← OxiPNG
└── avifenc    ← libavif
```

After placing binaries, make them executable:
```bash
chmod +x bin/cjpeg bin/cwebp bin/oxipng bin/avifenc
```

Then remove quarantine (required for unsigned binaries on macOS):
```bash
xattr -d com.apple.quarantine bin/cjpeg bin/cwebp bin/oxipng bin/avifenc
```

---

## Download links (arm64 / Apple Silicon)

### cjpeg (MozJPEG)
Build from source or grab a prebuilt binary from:
- https://github.com/mozilla/mozjpeg/releases
- Homebrew: `brew install mozjpeg` → binary at `/opt/homebrew/opt/mozjpeg/bin/cjpeg`

### cwebp (WebP)
- https://developers.google.com/speed/webp/download
- Homebrew: `brew install webp` → binary at `/opt/homebrew/bin/cwebp`

### oxipng
- https://github.com/shssoichiro/oxipng/releases
- Grab `oxipng-*-aarch64-apple-darwin.tar.gz`
- Homebrew: `brew install oxipng`

### avifenc (libavif)
- https://github.com/AOMediaCodec/libavif/releases
- Homebrew: `brew install libavif` → binary at `/opt/homebrew/bin/avifenc`

---

## Quick setup via Homebrew

```bash
brew install mozjpeg webp oxipng libavif

cp /opt/homebrew/opt/mozjpeg/bin/cjpeg  bin/
cp /opt/homebrew/bin/cwebp               bin/
cp /opt/homebrew/bin/oxipng             bin/
cp /opt/homebrew/bin/avifenc            bin/

chmod +x bin/*
xattr -d com.apple.quarantine bin/* 2>/dev/null || true
```
