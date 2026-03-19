#!/usr/bin/env python3
"""
Generate placeholder icon PNGs for the ATLAS.OS Arma 3 mod.

NOTE: These PNG files are placeholders for development and previewing.
Before they will work in-game, they MUST be converted to Arma 3's PAA
texture format. You can do this with:

  1. HEMTT (recommended) -- If your .hemtt/project.toml has the paa
     preprocessing step enabled, HEMTT will auto-convert PNGs to PAA
     during the build process.

  2. Arma 3 Tools / TexView2 -- Open each PNG in TexView2 and export
     as PAA manually. Batch conversion is also supported.

Usage:
    python tools/generate_icons.py

Run from the project root (P:/ATLAS.OS).

Requires: Pillow (pip install Pillow)
"""

import math
import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("ERROR: Pillow is not installed.")
    print("Install it with:  pip install Pillow")
    print("Or:               python -m pip install Pillow")
    sys.exit(1)

# ---------------------------------------------------------------------------
# Project root — resolve relative to this script so it works from anywhere
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

# ---------------------------------------------------------------------------
# Module definitions: (addon_name, abbreviation, hex_color)
# ---------------------------------------------------------------------------
MODULES = [
    ("atlas_main",        "CO", "#4a9eff"),
    ("atlas_profile",     "PF", "#22c55e"),
    ("atlas_opcom",       "OP", "#ef4444"),
    ("atlas_logcom",      "LG", "#f59e0b"),
    ("atlas_ato",         "AT", "#3b82f6"),
    ("atlas_cqb",         "CQ", "#dc2626"),
    ("atlas_placement",   "PL", "#16a34a"),
    ("atlas_civilian",    "CV", "#a855f7"),
    ("atlas_persistence", "PS", "#06b6d4"),
    ("atlas_orbat",       "OB", "#84cc16"),
    ("atlas_c2",          "C2", "#6366f1"),
    ("atlas_support",     "SP", "#f97316"),
    ("atlas_insertion",   "IN", "#14b8a6"),
    ("atlas_gc",          "GC", "#78716c"),
    ("atlas_ai",          "AI", "#e11d48"),
    ("atlas_weather",     "WX", "#0ea5e9"),
    ("atlas_tasks",       "TK", "#8b5cf6"),
    ("atlas_stats",       "ST", "#10b981"),
    ("atlas_admin",       "AD", "#f43f5e"),
    ("atlas_markers",     "MK", "#eab308"),
    ("atlas_reports",     "RP", "#64748b"),
    ("atlas_cargo",       "CG", "#d97706"),
    ("atlas_compat",      "CM", "#737373"),
]

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------

def hex_to_rgb(h):
    """Convert '#rrggbb' to (r, g, b)."""
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def darken(rgb, factor=0.65):
    """Return a darker version of an RGB tuple."""
    return tuple(max(0, int(c * factor)) for c in rgb)


def lighten(rgb, factor=0.3):
    """Return a lighter (toward white) version of an RGB tuple."""
    return tuple(min(255, int(c + (255 - c) * factor)) for c in rgb)


# ---------------------------------------------------------------------------
# Try to load a TrueType font; fall back to the built-in bitmap font.
# ---------------------------------------------------------------------------

def _load_font(size):
    """Try common system fonts, fall back to default."""
    candidates = [
        "arialbd.ttf",        # Windows bold
        "arial.ttf",          # Windows
        "Arial Bold.ttf",     # macOS
        "DejaVuSans-Bold.ttf",# Linux
        "LiberationSans-Bold.ttf",
    ]
    for name in candidates:
        try:
            return ImageFont.truetype(name, size)
        except (OSError, IOError):
            continue
    # Absolute fallback
    return ImageFont.load_default()


# ---------------------------------------------------------------------------
# 32x32 module icon generation
# ---------------------------------------------------------------------------

def generate_module_icon(abbrev, color_hex, out_path):
    """Create a 32x32 module icon with rounded-rect background and text."""
    size = 32
    bg_rgb = hex_to_rgb(color_hex)
    border_rgb = darken(bg_rgb, 0.6)

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Rounded rectangle background
    draw.rounded_rectangle(
        [1, 1, size - 2, size - 2],
        radius=5,
        fill=bg_rgb,
        outline=border_rgb,
        width=1,
    )

    # White abbreviation text
    font = _load_font(14)
    bbox = draw.textbbox((0, 0), abbrev, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (size - tw) / 2 - bbox[0]
    ty = (size - th) / 2 - bbox[1]
    draw.text((tx, ty), abbrev, fill=(255, 255, 255, 255), font=font)

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path, "PNG")


# ---------------------------------------------------------------------------
# Logo generation (512x512 and 256x256)
# ---------------------------------------------------------------------------

def _draw_hex_grid(draw, width, height, hex_size, color):
    """Draw a subtle hexagonal grid pattern."""
    dx = hex_size * 1.5
    dy = hex_size * math.sqrt(3)
    cols = int(width / dx) + 2
    rows = int(height / dy) + 2

    for row in range(-1, rows + 1):
        for col in range(-1, cols + 1):
            cx = col * dx
            cy = row * dy + (hex_size * math.sqrt(3) / 2 if col % 2 else 0)
            points = []
            for k in range(6):
                angle = math.radians(60 * k + 30)
                px = cx + hex_size * math.cos(angle)
                py = cy + hex_size * math.sin(angle)
                points.append((px, py))
            if len(points) >= 3:
                draw.polygon(points, outline=color)


def _draw_reticle(draw, cx, cy, radius, color):
    """Draw a crosshair / tactical reticle centered at (cx, cy)."""
    # Outer circle
    draw.ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        outline=color, width=2,
    )
    # Inner circle
    inner = radius * 0.45
    draw.ellipse(
        [cx - inner, cy - inner, cx + inner, cy + inner],
        outline=color, width=1,
    )
    # Cross lines with a gap in the center
    gap = radius * 0.2
    line_w = 1
    # Top
    draw.line([(cx, cy - radius - 8), (cx, cy - gap)], fill=color, width=line_w)
    # Bottom
    draw.line([(cx, cy + gap), (cx, cy + radius + 8)], fill=color, width=line_w)
    # Left
    draw.line([(cx - radius - 8, cy), (cx - gap, cy)], fill=color, width=line_w)
    # Right
    draw.line([(cx + gap, cy), (cx + radius + 8, cy)], fill=color, width=line_w)

    # Tick marks at 45-degree angles
    tick_inner = radius * 0.75
    tick_outer = radius * 0.92
    for angle_deg in [45, 135, 225, 315]:
        a = math.radians(angle_deg)
        x1 = cx + tick_inner * math.cos(a)
        y1 = cy + tick_inner * math.sin(a)
        x2 = cx + tick_outer * math.cos(a)
        y2 = cy + tick_outer * math.sin(a)
        draw.line([(x1, y1), (x2, y2)], fill=color, width=line_w)


def generate_logo(size, out_path):
    """Generate the ATLAS.OS mod logo at the given square size."""
    bg_color = hex_to_rgb("#0f172a")
    accent = hex_to_rgb("#4a9eff")
    grid_color = (255, 255, 255, 18)  # very subtle white
    reticle_color = (*accent, 60)       # semi-transparent accent

    img = Image.new("RGBA", (size, size), (*bg_color, 255))
    draw = ImageDraw.Draw(img)

    # Hex grid
    hex_size = max(20, size // 16)
    _draw_hex_grid(draw, size, size, hex_size, grid_color)

    # Reticle behind text
    reticle_radius = int(size * 0.30)
    _draw_reticle(draw, size // 2, int(size * 0.44), reticle_radius, reticle_color)

    # --- Text ---
    # "ATLAS"
    atlas_font_size = int(size * 0.20)
    atlas_font = _load_font(atlas_font_size)

    # ".OS"
    os_font_size = int(size * 0.20)
    os_font = _load_font(os_font_size)

    atlas_text = "ATLAS"
    os_text = ".OS"

    atlas_bbox = draw.textbbox((0, 0), atlas_text, font=atlas_font)
    os_bbox = draw.textbbox((0, 0), os_text, font=os_font)
    atlas_w = atlas_bbox[2] - atlas_bbox[0]
    os_w = os_bbox[2] - os_bbox[0]
    total_w = atlas_w + os_w

    start_x = (size - total_w) / 2 - atlas_bbox[0]
    text_y = size * 0.37
    # Adjust vertical offset from bbox
    atlas_y_off = atlas_bbox[1]

    draw.text(
        (start_x, text_y - atlas_y_off),
        atlas_text,
        fill=(255, 255, 255, 255),
        font=atlas_font,
    )
    draw.text(
        (start_x + atlas_w, text_y - atlas_y_off),
        os_text,
        fill=(*accent, 255),
        font=os_font,
    )

    # Subtitle
    sub_font_size = max(10, int(size * 0.04))
    sub_font = _load_font(sub_font_size)
    subtitle = "ADVANCED TACTICAL LIFECYCLE"
    sub_bbox = draw.textbbox((0, 0), subtitle, font=sub_font)
    sub_w = sub_bbox[2] - sub_bbox[0]
    sub_x = (size - sub_w) / 2 - sub_bbox[0]
    sub_y = text_y + atlas_font_size + size * 0.03
    draw.text(
        (sub_x, sub_y),
        subtitle,
        fill=(255, 255, 255, 120),
        font=sub_font,
    )

    # Thin accent line under subtitle
    line_y = int(sub_y + sub_font_size + size * 0.02)
    line_half = int(size * 0.25)
    draw.line(
        [(size // 2 - line_half, line_y), (size // 2 + line_half, line_y)],
        fill=(*accent, 80),
        width=1,
    )

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path, "PNG")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print("=" * 60)
    print("  ATLAS.OS Icon Generator")
    print("=" * 60)
    print(f"  Project root: {PROJECT_ROOT}")
    print()

    # --- Root logos ---
    logo_512 = os.path.join(PROJECT_ROOT, "logo_ca.png")
    logo_256 = os.path.join(PROJECT_ROOT, "logo_co.png")

    print("[logo] Generating logo_ca.png (512x512) ...")
    generate_logo(512, logo_512)
    print(f"       -> {logo_512}")

    print("[logo] Generating logo_co.png (256x256) ...")
    generate_logo(256, logo_256)
    print(f"       -> {logo_256}")

    print()

    # --- Module icons ---
    for addon, abbrev, color in MODULES:
        icon_dir = os.path.join(PROJECT_ROOT, "addons", addon, "ui")
        icon_path = os.path.join(icon_dir, "icon.png")
        print(f"[icon] {addon:20s}  {abbrev}  {color}  -> {icon_path}")
        generate_module_icon(abbrev, color, icon_path)

    print()
    print("-" * 60)
    print(f"  Done. Generated 2 logos + {len(MODULES)} module icons.")
    print()
    print("  REMINDER: Convert PNGs to PAA format before use in-game.")
    print("  Use HEMTT (auto-convert) or Arma 3 Tools / TexView2.")
    print("-" * 60)


if __name__ == "__main__":
    main()
