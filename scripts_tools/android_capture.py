"""Encode and inspect the same raw Android 14 screencap frame without dependencies.

The API 34 raw format is width/height/pixel-format/colorspace (four little-endian
uint32 values), followed by tightly packed rows. Source:
https://github.com/aosp-mirror/platform_frameworks_base/blob/android-14.0.0_r1/cmds/screencap/screencap.cpp
This only rejects blank captures; it does not replace human visual review.
"""
import struct
import zlib


def capture_png(raw):
    if len(raw) < 16:
        raise ValueError("Truncated raw Android screenshot")
    width, height, pixel_format, colorspace = struct.unpack_from("<4I", raw)
    if pixel_format not in (1, 2) or not 1 <= width <= 4096 or not 1 <= height <= 4096:
        raise ValueError(f"Unsupported Android screenshot format: {(width, height, pixel_format)}")
    pixels = raw[16:]
    stride = width * 4
    if len(pixels) != stride * height:
        raise ValueError("Raw Android screenshot byte count differs from its dimensions")
    if pixel_format == 2:  # RGBX: the unused channel is not alpha.
        pixels = bytearray(pixels)
        pixels[3::4] = b"\xff" * (width * height)
    samples = [bytes(pixels[(y * width + x) * 4:(y * width + x) * 4 + 3])
               for y in range(0, height, 16) for x in range(0, width, 16)]
    fraction = sum(max(color) > 24 for color in samples) / len(samples)
    colors = len(set(samples))
    stats = {"width": width, "height": height, "pixel_format": pixel_format,
             "colorspace": colorspace, "sampled_colors": colors,
             "non_dark_fraction": round(fraction, 6),
             "has_visible_content": fraction >= 0.05 and colors >= 8}

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

    rows = b"".join(b"\0" + pixels[y * stride:(y + 1) * stride] for y in range(height))
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">2I5B", width, height, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b""))
    return png, stats
