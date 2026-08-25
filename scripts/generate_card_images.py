#!/usr/bin/env python3
"""Generate lightweight 720 px WebP thumbnails for homepage model cards."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = ROOT / "models"
MODEL_DIR = ROOT / "model"
OUTPUT_DIR = SOURCE_DIR / "cards"
MAX_SIZE = (680, 680)

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

slugs = sorted(path.name for path in MODEL_DIR.iterdir() if (path / "index.html").is_file())
sources = [SOURCE_DIR / f"{slug}.webp" for slug in slugs]
missing = [path for path in sources if not path.is_file()]
if missing:
    raise SystemExit("Missing model images: " + ", ".join(path.name for path in missing))
for source in sources:
    destination = OUTPUT_DIR / source.name
    with Image.open(source) as image:
        image.thumbnail(MAX_SIZE, Image.Resampling.LANCZOS)
        image.save(destination, "WEBP", quality=60, method=6)

print(f"Generated {len(sources)} card images in {OUTPUT_DIR.relative_to(ROOT)}")
