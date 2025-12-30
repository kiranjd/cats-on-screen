#!/usr/bin/env python3
"""
Sprite Adjustment Script
Generated from Sprite Alignment Tool
Front sprite grounding fix: Y:-120 global, F4 needs extra Y:-150
"""

from PIL import Image
import os

ASSETS_DIR = "Sources/CatOnScreen/Resources/Assets"

# Sprite metadata
SPRITE_INFO = {
    "walking": {"prefix": "cat_walking", "count": 7},
    "running": {"prefix": "cat_running", "count": 8},
    "front": {"prefix": "cat_front", "count": 8},
    "sitdown": {"prefix": "cat_sitdown", "count": 8},
    "wave": {"prefix": "cat_wave", "count": 8},
    "yarn": {"prefix": "cat_yarn", "count": 4},
    "belly": {"prefix": "cat_belly", "count": 4},
}

# Global adjustments (apply to all frames of a sprite)
GLOBAL_ADJUSTMENTS = {
    "front": {
        "yOffset": -120, "xOffset": 0, "scale": 1.0,
        "cropTop": 0, "cropBottom": 0,
        "cropLeft": 0, "cropRight": 0
    },
}

# Per-frame adjustments (apply to specific frames only)
# Note: Per-frame OVERRIDES global, so must include all values
PER_FRAME_ADJUSTMENTS = {
    "front_2": {
        "yOffset": -120, "xOffset": -15, "scale": 1.0,
        "cropTop": 0, "cropBottom": 0,
        "cropLeft": 0, "cropRight": 0
    },
    "front_3": {
        "yOffset": -120, "xOffset": -15, "scale": 1.0,
        "cropTop": 0, "cropBottom": 0,
        "cropLeft": 0, "cropRight": 0
    },
    "front_4": {
        "yOffset": -150, "xOffset": 0, "scale": 1.0,
        "cropTop": 0, "cropBottom": 0,
        "cropLeft": 0, "cropRight": 0
    },
}

def get_adjustment(sprite_name, frame_idx):
    """Get adjustment for a specific frame (per-frame override or global)"""
    key = f"{sprite_name}_{frame_idx}"
    if key in PER_FRAME_ADJUSTMENTS:
        return PER_FRAME_ADJUSTMENTS[key]
    if sprite_name in GLOBAL_ADJUSTMENTS:
        return GLOBAL_ADJUSTMENTS[sprite_name]
    return None

def apply_adjustment(img, adj):
    """Apply adjustment to an image and return modified image"""
    changes = []

    # Apply crop first
    cropT = adj.get("cropTop", 0)
    cropB = adj.get("cropBottom", 0)
    cropL = adj.get("cropLeft", 0)
    cropR = adj.get("cropRight", 0)
    if cropT or cropB or cropL or cropR:
        new_w = img.width - cropL - cropR
        new_h = img.height - cropT - cropB
        img = img.crop((cropL, cropT, img.width - cropR, img.height - cropB))
        changes.append(f"Cropped to {new_w}x{new_h}")

    # Apply scale
    scale = adj.get("scale", 1.0)
    if scale != 1.0:
        new_w = int(img.width * scale)
        new_h = int(img.height * scale)
        img = img.resize((new_w, new_h), Image.LANCZOS)
        changes.append(f"Scaled to {img.size}")

    # Apply offset (create canvas and paste)
    yOffset = adj.get("yOffset", 0)
    xOffset = adj.get("xOffset", 0)
    if yOffset != 0 or xOffset != 0:
        canvas = Image.new('RGBA', img.size, (0, 0, 0, 0))
        paste_x = xOffset
        paste_y = -yOffset  # Positive Y = move up = negative paste_y
        canvas.paste(img, (paste_x, paste_y), img)
        img = canvas
        changes.append(f"Offset Y:{yOffset} X:{xOffset}")

    return img, changes

def apply_all_adjustments():
    print(f"Applying {len(GLOBAL_ADJUSTMENTS) + len(PER_FRAME_ADJUSTMENTS)} adjustment(s)...")

    for sprite_name, info in SPRITE_INFO.items():
        prefix = info["prefix"]
        count = info["count"]

        for i in range(count):
            adj = get_adjustment(sprite_name, i)
            if adj is None:
                continue

            filename = f'{ASSETS_DIR}/{prefix}_{i}.png'
            if not os.path.exists(filename):
                print(f"  {sprite_name}_{i}: File not found")
                continue

            img = Image.open(filename).convert('RGBA')
            img, changes = apply_adjustment(img, adj)

            if changes:
                print(f"  {sprite_name}_{i}: {', '.join(changes)}")
                img.save(filename)

    print("\nDone! Adjustments applied.")

if __name__ == "__main__":
    apply_all_adjustments()
