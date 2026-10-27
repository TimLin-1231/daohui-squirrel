#!/usr/bin/env python3
"""Make DaoHui's macOS icons from the chosen branding set (design F).

usage: python tools/make_daohui_icons.py <branding dir> [--preview <png>]

<branding dir> is the input-method project's branding folder
(D:\\Document\\輸入法\\branding on the development machine). It is only read.

Writes, relative to the repository root:

  Assets.xcassets/DaoHui.appiconset/   app icon (ASSETCATALOG_COMPILER_APPICON_NAME
                                       = DaoHui). The PNGs are the branding files
                                       themselves, byte for byte: out/F/app-512.png,
                                       app-256.png, tauri/icons/32x32.png,
                                       128x128.png, and the 64 px and 1024 px
                                       entries of tauri/icons/icon.icns. Only the
                                       16 px image is re-encoded (the 16 px frame of
                                       out/F/weasel.ico, decoded to PNG).
  resources/daohui.pdf                 menu-bar / input-source icon. A template
                                       image (TISIconIsTemplate in Info.plist): a
                                       rounded badge with the brush 島 of
                                       concepts/F.svg knocked out, the negative
                                       look of design F. Vector, one path, even-odd.

--preview writes a PNG of daohui.pdf's path at 16, 32 and 64 px (on light and
dark backgrounds) rasterised here, for checking without a Mac.
"""
import json
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONSET = os.path.join(ROOT, 'Assets.xcassets', 'DaoHui.appiconset')
PDF = os.path.join(ROOT, 'resources', 'daohui.pdf')

# Template icon geometry, in PDF points.
PAGE_W, PAGE_H = 16.0, 16.0      # artboard (Squirrel's rime.pdf: 22 x 16)
BADGE = (0.5, 0.5, 15.5, 15.5)   # x0, y0, x1, y1
BADGE_R = 3.5                    # corner radius
GLYPH_BOX = 12.4                 # the glyph's larger side


def read_icns(path):
    data = open(path, 'rb').read()
    assert data[:4] == b'icns', path
    out, i = {}, 8
    while i < len(data):
        tag = data[i:i + 4].decode('ascii')
        n = struct.unpack('>I', data[i + 4:i + 8])[0]
        out[tag] = data[i + 8:i + n]
        i += n
    return out


def png_size(data):
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    return struct.unpack('>II', data[16:24])


def make_iconset(branding):
    from PIL import Image
    f = os.path.join(branding, 'out', 'F')
    icns = read_icns(os.path.join(f, 'tauri', 'icons', 'icon.icns'))
    files = {
        'daohui-32.png': open(os.path.join(f, 'tauri', 'icons', '32x32.png'), 'rb').read(),
        'daohui-64.png': icns['ic12'],
        'daohui-128.png': open(os.path.join(f, 'tauri', 'icons', '128x128.png'), 'rb').read(),
        'daohui-256.png': open(os.path.join(f, 'app-256.png'), 'rb').read(),
        'daohui-512.png': open(os.path.join(f, 'app-512.png'), 'rb').read(),
        'daohui-1024.png': icns['ic10'],
    }
    os.makedirs(ICONSET, exist_ok=True)
    for name, data in files.items():
        want = int(re.search(r'-(\d+)\.png$', name).group(1))
        assert png_size(data) == (want, want), (name, png_size(data))
        open(os.path.join(ICONSET, name), 'wb').write(data)
    ico = Image.open(os.path.join(f, 'weasel.ico'))
    small = ico.ico.getimage((16, 16)).convert('RGBA')
    assert small.size == (16, 16)
    small.save(os.path.join(ICONSET, 'daohui-16.png'), optimize=True)

    slots = [('16x16', '1x', 16), ('16x16', '2x', 32), ('32x32', '1x', 32), ('32x32', '2x', 64),
             ('128x128', '1x', 128), ('128x128', '2x', 256), ('256x256', '1x', 256),
             ('256x256', '2x', 512), ('512x512', '1x', 512), ('512x512', '2x', 1024)]
    contents = {
        'images': [{'filename': 'daohui-%d.png' % px, 'idiom': 'mac', 'scale': scale, 'size': size}
                   for size, scale, px in slots],
        'info': {'author': 'xcode', 'version': 1},
    }
    with open(os.path.join(ICONSET, 'Contents.json'), 'w', encoding='utf-8', newline='\n') as fp:
        fp.write(json.dumps(contents, indent=2, separators=(',', ' : ')) + '\n')
    print('wrote', ICONSET)


# ---------------------------------------------------------------- template PDF

def glyph_subpaths(svg_path):
    """The 島 of concepts/F.svg: the even-odd path filled with the paper colour.
    Returns a list of subpaths, each a list of ('M'|'L', (x, y)) / ('Q', c, p)."""
    svg = open(svg_path, encoding='utf-8').read()
    paths = re.findall(r'<path ([^>]*)/>', svg)
    glyph = [p for p in paths if 'fill-rule="evenodd"' in p and 'fill="#F3EFE5"' in p]
    assert len(glyph) == 1, 'glyph path not found in ' + svg_path
    d = re.search(r'\bd="([^"]*)"', glyph[0]).group(1)
    tokens = re.findall(r'[MLQZ]|-?\d+(?:\.\d+)?', d)
    subs, cur, i = [], None, 0
    num = lambda k: float(tokens[k])
    while i < len(tokens):
        t = tokens[i]
        if t == 'M':
            cur = [('M', (num(i + 1), num(i + 2)))]
            subs.append(cur)
            i += 3
        elif t == 'L':
            cur.append(('L', (num(i + 1), num(i + 2))))
            i += 3
        elif t == 'Q':
            cur.append(('Q', (num(i + 1), num(i + 2)), (num(i + 3), num(i + 4))))
            i += 5
        elif t == 'Z':
            i += 1
        else:
            raise ValueError('unexpected token %r' % t)
    return subs


def bbox(subs):
    xs, ys = [], []
    for sp in subs:
        for seg in sp:
            for pt in seg[1:]:
                xs.append(pt[0])
                ys.append(pt[1])
    return min(xs), min(ys), max(xs), max(ys)


def template_geometry(svg_path):
    """Badge and glyph in PDF space (y up), as lists of segments:
    ('M', p) ('L', p) ('C', c1, c2, p); one list per closed subpath."""
    subs = glyph_subpaths(svg_path)
    x0, y0, x1, y1 = bbox(subs)
    k = GLYPH_BOX / max(x1 - x0, y1 - y0)
    bx0, by0, bx1, by1 = BADGE
    cx, cy = (bx0 + bx1) / 2, (by0 + by1) / 2
    gx, gy = (x0 + x1) / 2, (y0 + y1) / 2

    def tr(p):
        return (cx + (p[0] - gx) * k, cy - (p[1] - gy) * k)

    out = []
    # rounded rectangle, counter-clockwise (the fill rule is even-odd anyway)
    r, kap = BADGE_R, 0.5522847498 * BADGE_R
    out.append([
        ('M', (bx0 + r, by0)), ('L', (bx1 - r, by0)),
        ('C', (bx1 - r + kap, by0), (bx1, by0 + r - kap), (bx1, by0 + r)),
        ('L', (bx1, by1 - r)),
        ('C', (bx1, by1 - r + kap), (bx1 - r + kap, by1), (bx1 - r, by1)),
        ('L', (bx0 + r, by1)),
        ('C', (bx0 + r - kap, by1), (bx0, by1 - r + kap), (bx0, by1 - r)),
        ('L', (bx0, by0 + r)),
        ('C', (bx0, by0 + r - kap), (bx0 + r - kap, by0), (bx0 + r, by0)),
    ])
    for sp in subs:
        seg_out, cur = [], None
        for seg in sp:
            if seg[0] in 'ML':
                cur = tr(seg[1])
                seg_out.append((seg[0], cur))
            else:  # quadratic -> cubic
                q, p = tr(seg[1]), tr(seg[2])
                c1 = (cur[0] + 2 / 3 * (q[0] - cur[0]), cur[1] + 2 / 3 * (q[1] - cur[1]))
                c2 = (p[0] + 2 / 3 * (q[0] - p[0]), p[1] + 2 / 3 * (q[1] - p[1]))
                seg_out.append(('C', c1, c2, p))
                cur = p
        out.append(seg_out)
    return out


def fmt(v):
    s = '%.3f' % v
    s = s.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def pdf_bytes(geom):
    ops = ['q', '0 0 0 rg']
    for sp in geom:
        for seg in sp:
            pts = ' '.join(fmt(c) for p in seg[1:] for c in p)
            ops.append(pts + {'M': ' m', 'L': ' l', 'C': ' c'}[seg[0]])
        ops.append('h')
    ops += ['f*', 'Q']
    content = ('\n'.join(ops) + '\n').encode('ascii')
    objs = [
        b'<< /Type /Catalog /Pages 2 0 R >>',
        b'<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
        ('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %s %s] /Resources << >> /Contents 4 0 R >>'
         % (fmt(PAGE_W), fmt(PAGE_H))).encode('ascii'),
        b'<< /Length %d >>\nstream\n' % len(content) + content + b'endstream',
        b'<< /Title (DaoHui menu-bar template icon) /Producer (tools/make_daohui_icons.py) >>',
    ]
    out = bytearray(b'%PDF-1.4\n%\xe2\xe3\xcf\xd3\n')
    offsets = []
    for n, body in enumerate(objs, 1):
        offsets.append(len(out))
        out += b'%d 0 obj\n' % n + body + b'\nendobj\n'
    xref = len(out)
    out += b'xref\n0 %d\n0000000000 65535 f \n' % (len(objs) + 1)
    for off in offsets:
        out += b'%010d 00000 n \n' % off
    out += (b'trailer\n<< /Size %d /Root 1 0 R /Info 5 0 R >>\nstartxref\n%d\n%%%%EOF\n'
            % (len(objs) + 1, xref))
    return bytes(out)


def check_pdf(data):
    """Re-read the xref table and make sure every offset points at its object."""
    sx = int(re.search(rb'startxref\n(\d+)\n%%EOF\n$', data).group(1))
    assert data[sx:sx + 4] == b'xref'
    lines = data[sx:].split(b'\n')
    count = int(lines[1].split()[1])
    for n in range(1, count):
        off = int(lines[2 + n][:10])
        assert data[off:].startswith(b'%d 0 obj' % n), n
    m = re.search(rb'/Length (\d+) >>\nstream\n', data)
    start = m.end()
    assert data[start + int(m.group(1)):].startswith(b'endstream'), 'bad /Length'


def flatten(geom, scale, steps=12):
    polys = []
    for sp in geom:
        pts, cur = [], None
        for seg in sp:
            if seg[0] in 'ML':
                cur = seg[1]
                pts.append(cur)
            else:
                c1, c2, p = seg[1:]
                for s in range(1, steps + 1):
                    t = s / steps
                    u = 1 - t
                    pts.append((u ** 3 * cur[0] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t ** 3 * p[0],
                                u ** 3 * cur[1] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t ** 3 * p[1]))
                cur = p
        polys.append([(x * scale, (PAGE_H - y) * scale) for x, y in pts])
    return polys


def raster(geom, px, ss=8):
    """Even-odd fill of the path at px x px (alpha mask), supersampled."""
    from PIL import Image, ImageChops, ImageDraw
    big = px * ss
    acc = Image.new('1', (big, big), 0)
    for poly in flatten(geom, big / PAGE_W):
        m = Image.new('1', (big, big), 0)
        ImageDraw.Draw(m).polygon(poly, fill=1)
        acc = ImageChops.logical_xor(acc, m)
    return acc.convert('L').resize((px, px), Image.LANCZOS)


def preview(geom, path):
    from PIL import Image
    sizes = [16, 32, 64]
    w = sum(sizes) * 2 + 10 * 7
    img = Image.new('RGB', (w, 64 + 20), (255, 255, 255))
    x = 10
    for bg, fg in (((236, 236, 236), (30, 30, 30)), ((40, 40, 40), (235, 235, 235))):
        for s in sizes:
            mask = raster(geom, s)
            tile = Image.new('RGB', (s, s), bg)
            tile.paste(Image.new('RGB', (s, s), fg), (0, 0), mask)
            img.paste(tile, (x, 10))
            x += s + 10
    img.save(path)
    print('wrote', path)


def main(argv):
    if len(argv) < 2:
        raise SystemExit(__doc__)
    branding = argv[1]
    make_iconset(branding)
    geom = template_geometry(os.path.join(branding, 'concepts', 'F.svg'))
    data = pdf_bytes(geom)
    check_pdf(data)
    open(PDF, 'wb').write(data)
    print('wrote', PDF, len(data), 'bytes')
    if '--preview' in argv:
        preview(geom, argv[argv.index('--preview') + 1])


if __name__ == '__main__':
    main(sys.argv)
