# Sprite Processing Guide

Skills for processing game sprites, learned from building this cat app.

## Key Principle: Use HEAD SIZE, Not Bounding Box

**The Golden Rule**: Don't scale sprites by bounding box height/width. The bounding box changes wildly based on pose (limbs extended, tail position).

**Better metrics** (from Gemini Pro consultation):
1. **Head/Skull diameter** - Most rigid part, doesn't change with pose
2. **Shoulder-to-hip distance** - Spine length is relatively constant
3. **Body width** - Less affected by vertical pose changes

## Workflow: Storyboard First

**Always create a visual storyboard** before finalizing sprites:

```python
from PIL import Image, ImageDraw

def create_storyboard(animations, assets_dir, output_path):
    """
    Create side-by-side comparison of all animation frames.

    animations: [(name, prefix, frame_count), ...]
    """
    margin, cell_w, cell_h = 8, 140, 120

    rows = len(animations)
    cols = max(count for _, _, count in animations) + 1

    width = cols * cell_w + margin * (cols + 1)
    height = rows * cell_h + margin * (rows + 1)

    storyboard = Image.new("RGBA", (width, height), (30, 30, 30, 255))
    draw = ImageDraw.Draw(storyboard)

    for row, (name, prefix, count) in enumerate(animations):
        y_base = margin + row * (cell_h + margin)
        ground_y = y_base + cell_h - 15

        # Draw ground line
        draw.line([(cell_w, ground_y), (width - margin, ground_y)],
                  fill=(80, 80, 80), width=1)

        # Row label
        draw.text((margin + 5, y_base + cell_h//2), name, fill=(200, 200, 200))

        # Frames
        for col in range(count):
            sprite = Image.open(f"{assets_dir}/{prefix}_{col}.png").convert("RGBA")
            sprite.thumbnail((cell_w - 10, cell_h - 20), Image.LANCZOS)

            x = margin + (col + 1) * (cell_w + margin)
            paste_y = ground_y - sprite.height

            storyboard.paste(sprite, (x + (cell_w - sprite.width) // 2, paste_y), sprite)

            # Height label
            bbox = sprite.getbbox()
            if bbox:
                draw.text((x + 5, y_base + 2), f"{bbox[3]-bbox[1]}", fill=(100, 100, 100))

    storyboard.save(output_path)
```

## Background Removal (Checkered Pattern)

Many sprite sheets have checkered gray backgrounds:

```python
def remove_checkered_background(img):
    """Remove gray checkered pattern - detects by color uniformity"""
    img = img.convert("RGBA")
    pixels = img.load()

    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = pixels[x, y]

            # Check if pixel is grayish (R, G, B similar)
            max_diff = max(abs(r-g), abs(g-b), abs(r-b))
            if max_diff < 40:
                avg = (r + g + b) // 3
                # Gray range (not pure white/black)
                if 35 <= avg <= 210:
                    pixels[x, y] = (0, 0, 0, 0)

    return img
```

## Scaling Strategy

### For Consistent Source (same artist, same scale)
Use **uniform scaling** - find scale factor once, apply to all frames:

```python
# Pick reference frame, calculate scale, apply to ALL
ref_height = get_height(reference_frame)
scale = target_height / ref_height

for frame in animation:
    scaled = frame.resize((int(w * scale), int(h * scale)), Image.LANCZOS)
```

### For Inconsistent Source (mixed sizes)
Use **pose-aware scaling** - different targets for different pose types:

```python
# Group frames by pose type
FRAME_TARGETS = {
    # Leaping/horizontal poses - slightly shorter
    0: 385, 1: 385,
    # Upright poses - match baseline
    4: 385, 5: 385, 6: 385, 7: 385,
    # Transition poses - in between
    2: 400, 3: 400,
}

for i, frame in enumerate(frames):
    current_h = get_height(frame)
    target_h = FRAME_TARGETS[i]
    scale = target_h / current_h
    # Scale individually
```

### When to Use Each
- **Uniform**: Professional sprite sheets, consistent art
- **Pose-aware**: AI-generated sprites, mixed sources, inconsistent art

## Direction Flipping

Sprites often face one direction. Flip for the other:

```python
# Python (PIL)
flipped = img.transpose(Image.FLIP_LEFT_RIGHT)

# Swift (NSImage)
func flipImageHorizontally(_ image: NSImage) -> NSImage {
    let flipped = NSImage(size: image.size)
    flipped.lockFocus()
    let transform = NSAffineTransform()
    transform.translateX(by: image.size.width, yBy: 0)
    transform.scaleX(by: -1, yBy: 1)
    transform.concat()
    image.draw(at: .zero, from: NSRect(origin: .zero, size: image.size),
               operation: .sourceOver, fraction: 1.0)
    flipped.unlockFocus()
    return flipped
}
```

## Canvas Positioning

All sprites should be on same-size canvas, bottom-aligned (grounded):

```python
CANVAS = (576, 439)

def ground_sprite(img):
    """Center horizontally, align to bottom"""
    # Get content bounds
    bbox = img.getbbox()
    if not bbox:
        return img

    sprite = img.crop(bbox)
    sw, sh = sprite.size

    # Create canvas
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))

    # Position: center X, bottom Y
    paste_x = (CANVAS[0] - sw) // 2
    paste_y = CANVAS[1] - sh

    if paste_y >= 0 and paste_x >= 0:
        canvas.paste(sprite, (paste_x, paste_y), sprite)

    return canvas
```

## Original Source Location

Keep original source files for reprocessing:
```
/Users/jd/things/director/beta/to-be-processed/
  upload-1766996366869_*.png  # Running (8 frames)
  upload-1766996634344_*.png  # Front-facing (8 frames)
  upload-1766994070429_*.png  # Wave (8 frames)
  upload-1766993877492_*.png  # Yarn/Belly (8 frames)
```

## Naming Convention

```
cat_{activity}_{frame}.png

Activities:
- walking (7 frames) - horizontal movement
- running (8 frames) - fast horizontal movement
- sitdown (8 frames) - sit and scratch nose
- yarn (4 frames) - play with yarn
- belly (4 frames) - belly rub / roll
- wave (8 frames) - wave paw
- front (8 frames) - face user
```

## Audit Command

Quick dimension check:
```bash
cd Sources/CatOnScreen/Resources/Assets
for f in cat_*_0.png; do
  sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null
done
```

## Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Cat looks smaller in some frames | Scaled by height, pose varies | Use head width or pose-aware scaling |
| Ears cut off | Canvas overflow, cropped from top | Use larger temp canvas, crop from bottom |
| Background artifacts | Checkered pattern baked in | Use gray color detection |
| Cat floats above ground | Sprite not bottom-aligned | Use canvas positioning |
| Animation jumpy | Inconsistent source sizes | Create storyboard, adjust per-frame |
| Wrong direction | Source faces opposite way | Flip horizontally |

## Template Matching (Advanced)

For automated head detection, use OpenCV template matching:

```python
import cv2
import numpy as np

def find_scale_by_head(source_sprite, head_template):
    """Find scale factor that makes head_template match source best"""
    img_gray = cv2.cvtColor(source_sprite, cv2.COLOR_BGR2GRAY)
    template_gray = cv2.cvtColor(head_template, cv2.COLOR_BGR2GRAY)

    best_match = None

    for scale in np.linspace(0.2, 1.5, 20)[::-1]:
        resized = cv2.resize(img_gray, None, fx=scale, fy=scale)

        if (resized.shape[0] < template_gray.shape[0] or
            resized.shape[1] < template_gray.shape[1]):
            break

        result = cv2.matchTemplate(resized, template_gray, cv2.TM_CCOEFF_NORMED)
        _, max_val, _, _ = cv2.minMaxLoc(result)

        if best_match is None or max_val > best_match[0]:
            best_match = (max_val, scale)

    return 1.0 / best_match[1]  # Inverse to get scaling factor
```

## Current Sprite Stats

**Canvas**: 700x550 (cropped to remove bottom padding - content touches canvas bottom)

| Activity | Frames | Heights | Notes |
|----------|--------|---------|-------|
| walking | 7 | 357-439 | Baseline reference (head ~479px) |
| running | 8 | 494-570 | Head-matched to walking |
| sitdown | 8 | 385-414 | OK |
| yarn | 4 | 265-398 | Frame 2 small (lying pose) |
| belly | 4 | 340-348 | Shorter (lying) |
| wave | 8 | 423-429 | Consistent |
| front | 8 | 534-583 | Head-matched to walking |

## Fixing "Kitten" Problem

When sprites from different sources look like different-sized cats:

1. **Measure baseline head width** (walking frame 0 = 479px)
2. **Scale new sprites so head matches baseline** - NOT by bounding box height
3. **Use larger canvas if needed** - scaled sprites may be taller than baseline
4. **Fix outlier frames manually** - poses like leaping may need explicit scale factors
5. **Create storyboard comparison** - visual check is essential

## Animation Alignment with Gemini Flash

When animation frames jump around (cat position changes between frames):

### The Problem
Source images may have the subject at different positions within the frame. Simple centering after cropping doesn't work because each frame's bounding box is different.

### Solution: Use AI for Anchor Point Detection

1. **Send all frames to Gemini Flash** with prompt:
```
I have N sprite images. For each image, I need the PIXEL COORDINATES (x, y)
of the [ANCHOR POINT - e.g., cat's nose]. Image dimensions: WxH pixels.
Return coordinates in format: Frame 1: (x, y)
```

2. **Group frames by position patterns** - frames may fall into groups with similar anchor positions

3. **Calculate group-specific target offsets**:
```python
# If Group A has anchor at Y~545 and Group B at Y~440
# Calculate offset to align both groups on canvas
TARGET_Y_GROUP_A = 500  # Adjust based on desired position
TARGET_Y_GROUP_B = 416  # Offset to compensate for source difference
```

4. **Align each frame**:
```python
for frame in frames:
    anchor_x, anchor_y = GEMINI_COORDS[frame]
    target_y = TARGET_Y_GROUP_A if frame in group_a else TARGET_Y_GROUP_B

    paste_x = TARGET_ANCHOR_X - int(anchor_x * scale)
    paste_y = target_y - int(anchor_y * scale)

    canvas.paste(scaled_sprite, (paste_x, paste_y))
```

### Key Insight
Don't crop to bounding box before positioning. Scale the FULL source image to preserve relative positioning, then use anchor coordinates to align frames precisely.

### Verification
After alignment, all frames should have similar `bbox_top` values:
```
Frame 0: bbox_top= 78
Frame 1: bbox_top= 76
...
Frame 7: bbox_top= 76
```
Variance of <10px = good alignment.

## Running Animation: Bottom Alignment

For movement animations (running, walking), align by **feet** (bottom) rather than by anchor point:

```python
TARGET_BOTTOM = 580  # All frames will have bottom at this Y

for frame in frames:
    # Scale and flip
    scaled = img.resize((new_w, new_h)).transpose(FLIP_LEFT_RIGHT)

    # Find sprite bounds
    bbox = scaled.getbbox()
    sprite_bottom = bbox[3]
    sprite_center_x = (bbox[0] + bbox[2]) // 2

    # Align bottom to target, center horizontally
    paste_x = TARGET_CENTER_X - sprite_center_x
    paste_y = TARGET_BOTTOM - sprite_bottom

    canvas.paste(scaled, (paste_x, paste_y))
```

This ensures feet stay grounded while allowing natural height variation for leaping poses.

### Direction Matching
If running sprite faces opposite direction from walking, flip horizontally:
```python
scaled = scaled.transpose(Image.FLIP_LEFT_RIGHT)
```
