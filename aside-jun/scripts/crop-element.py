#!/usr/bin/env python3
"""Crop an Aside viewport source using measured CSS geometry; requires existing Pillow."""
import argparse
import json
import math
from pathlib import Path


def crop(source, geometry, output):
    from PIL import Image
    if source.resolve() == output.resolve():
        raise ValueError('output must not overwrite the viewport source')
    if output.exists():
        raise FileExistsError('output already exists; choose a new artifact path')
    box, viewport = geometry['box'], geometry['viewport']
    values = [box[key] for key in ('x', 'y', 'width', 'height')] + [viewport[key] for key in ('width', 'height')]
    if any(isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) for value in values):
        raise ValueError('geometry must contain finite numbers')
    x, y, width, height, vw, vh = values
    if x < 0 or y < 0 or min(width, height, vw, vh) <= 0 or x + width > vw or y + height > vh:
        raise ValueError('capture box must fit the measured viewport')
    with Image.open(source) as image:
        if image.format != 'PNG':
            raise ValueError('source must be a PNG viewport capture')
        sx, sy = image.width / vw, image.height / vh
        if abs(sx - sy) > max(sx, sy) * 0.01:
            raise ValueError('PNG aspect ratio differs from measured viewport')
        left, top = math.floor(x * sx), math.floor(y * sy)
        right, bottom = math.ceil((x + width) * sx), math.ceil((y + height) * sy)
        if not (0 <= left < right <= image.width and 0 <= top < bottom <= image.height):
            raise ValueError('pixel crop lies outside the source image')
        result = image.crop((left, top, right, bottom))
        output.parent.mkdir(parents=True, exist_ok=True)
        # Exclusive create preserves user artifacts even if a path appears after the check.
        with output.open('xb') as handle:
            try:
                result.save(handle, format='PNG')
            except BaseException:
                # This process exclusively created this file; never remove an older artifact.
                handle.close()
                output.unlink(missing_ok=True)
                raise
        return {'path': str(output.resolve()), 'width': result.width, 'height': result.height,
                'scaleX': sx, 'scaleY': sy, 'pixelBox': [left, top, right, bottom]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('geometry', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    try:
        result = crop(args.source, json.loads(args.geometry.read_text(encoding='utf-8')), args.output)
    except ImportError as error:
        parser.exit(1, 'Pillow is unavailable in this Python runtime; use an existing runtime with Pillow. No dependency was installed.\n')
    except (ValueError, OSError, KeyError, TypeError) as error:
        parser.exit(1, f'crop failed: {error}\n')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
