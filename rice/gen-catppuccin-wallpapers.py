"""Generate abstract Catppuccin Mocha wallpapers as SVG, one per orientation."""
import math, random, sys, os

C = dict(crust="#11111b", mantle="#181825", base="#1e1e2e", s0="#313244", s1="#45475a",
         s2="#585b70", mauve="#cba6f7", blue="#89b4fa", lav="#b4befe", pink="#f5c2e7",
         peach="#fab387", teal="#94e2d5", sapph="#74c7ec", flam="#f2cdcd", red="#f38ba8",
         green="#a6e3a1", yellow="#f9e2af", rose="#f5e0dc")


def svg(w, h, body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
            f'<defs>{defs}</defs><rect width="{w}" height="{h}" fill="{C["base"]}"/>{body}</svg>')


def waves(w, h):
    """Stacked soft waves rising from the bottom."""
    cols = [C["s0"], C["s1"], C["lav"], C["mauve"], C["pink"]]
    ops = [1, 1, .35, .45, .55]
    out = []
    n = len(cols)
    for i, (c, o) in enumerate(zip(cols, ops)):
        y0 = h * (0.45 + 0.11 * i)
        amp = min(w, h) * 0.05
        ph = i * 1.3
        pts = [(x, y0 + amp * math.sin(x / w * 2 * math.pi * 1.2 + ph)
                + amp * .5 * math.sin(x / w * 2 * math.pi * 2.7 + ph * 2)) for x in range(0, w + 21, 20)]
        d = f"M0 {h} " + " ".join(f"L{x:.0f} {y:.1f}" for x, y in pts) + f" L{w} {h} Z"
        out.append(f'<path d="{d}" fill="{c}" fill-opacity="{o}"/>')
    return svg(w, h, "".join(out))


def stripes(w, h):
    """A band of thick rounded diagonal bars across the screen."""
    cols = [C["mauve"], C["pink"], C["flam"], C["peach"], C["yellow"], C["green"], C["teal"], C["blue"]]
    m = min(w, h)
    sw = m * 0.045
    gap = sw * 1.6
    cx, cy = w / 2, h / 2
    L = min(w, h) * 1.3
    out = []
    for i, c in enumerate(cols):
        off = (i - (len(cols) - 1) / 2) * gap
        # line direction 45deg, offset perpendicular
        dx, dy = math.cos(math.pi / 4), -math.sin(math.pi / 4)
        px, py = -dy * off, dx * off
        x1, y1 = cx + px - dx * L * .25, cy + py - dy * L * .25
        x2, y2 = cx + px + dx * L * .25, cy + py + dy * L * .25
        out.append(f'<line x1="{x1:.0f}" y1="{y1:.0f}" x2="{x2:.0f}" y2="{y2:.0f}" stroke="{c}" stroke-width="{sw:.0f}" stroke-linecap="round" stroke-opacity=".9"/>')
    return svg(w, h, "".join(out))


def contours(w, h):
    """Topographic rings: nested wobbly loops in fading surface tones."""
    random.seed(7)
    m = min(w, h)
    out = []
    for cx, cy, n, col in [(0.28, 0.32, 14, C["lav"]), (0.78, 0.74, 11, C["mauve"])]:
        harm = [(k, random.uniform(.03, .08), random.uniform(0, 6.28)) for k in (2, 3, 5)]
        for i in range(n):
            r = m * (0.04 + i * 0.045)
            pts = []
            for a in range(0, 361, 3):
                t = math.radians(a)
                rr = r * (1 + sum(amp * math.sin(k * t + ph + i * .15) for k, amp, ph in harm))
                pts.append(f"{cx*w + rr*math.cos(t):.1f} {cy*h + rr*math.sin(t):.1f}")
            o = 0.85 * (1 - i / n) + 0.15
            out.append(f'<path d="M{" L".join(pts)} Z" fill="none" stroke="{col}" stroke-width="3" stroke-opacity="{o:.2f}"/>')
    return svg(w, h, "".join(out))


def bauhaus(w, h):
    """A loose grid of flat geometric tiles: circles, half circles, quarter arcs."""
    random.seed(3)
    cols = [C["mauve"], C["blue"], C["pink"], C["peach"], C["teal"], C["lav"], C["s1"], C["s0"]]
    cell = min(w, h) / 6
    nx, ny = math.ceil(w / cell), math.ceil(h / cell)
    ox, oy = (w - nx * cell) / 2, (h - ny * cell) / 2
    out = []
    for j in range(ny):
        for i in range(nx):
            x, y = ox + i * cell, oy + j * cell
            s = cell * 0.86
            px, py = x + (cell - s) / 2, y + (cell - s) / 2
            c = random.choice(cols)
            k = random.random()
            if k < .25:
                out.append(f'<circle cx="{px+s/2:.0f}" cy="{py+s/2:.0f}" r="{s/2:.0f}" fill="{c}" fill-opacity=".8"/>')
            elif k < .55:
                rot = random.choice([0, 90, 180, 270])
                out.append(f'<path d="M{px:.0f} {py+s:.0f} A{s:.0f} {s:.0f} 0 0 1 {px+s:.0f} {py:.0f} L{px+s:.0f} {py+s:.0f} Z" '
                           f'fill="{c}" fill-opacity=".8" transform="rotate({rot} {px+s/2:.0f} {py+s/2:.0f})"/>')
            elif k < .75:
                rot = random.choice([0, 90, 180, 270])
                out.append(f'<path d="M{px:.0f} {py+s/2:.0f} A{s/2:.0f} {s/2:.0f} 0 0 1 {px+s:.0f} {py+s/2:.0f} Z" '
                           f'fill="{c}" fill-opacity=".8" transform="rotate({rot} {px+s/2:.0f} {py+s/2:.0f})"/>')
            else:
                out.append(f'<rect x="{px:.0f}" y="{py:.0f}" width="{s:.0f}" height="{s:.0f}" rx="{s*.12:.0f}" fill="{C["s0"]}" fill-opacity=".6"/>')
    return svg(w, h, "".join(out))


def ridges(w, h):
    """Layered angular mountain ridges, dark at the back to lavender at the front."""
    random.seed(11)
    cols = [C["mantle"], C["s0"], C["s1"], C["s2"], "#6c7086", "#7f849c"]
    m = min(w, h)
    out = []
    for i, c in enumerate(cols):
        y0 = h * (0.42 + 0.1 * i)
        x, pts = 0, []
        while x < w + m * .2:
            pts.append((x, y0 - random.uniform(0, m * .14)))
            x += random.uniform(m * .08, m * .2)
        d = f"M0 {h} " + " ".join(f"L{x:.0f} {y:.0f}" for x, y in pts) + f" L{w} {h} Z"
        out.append(f'<path d="{d}" fill="{c}"/>')
    return svg(w, h, "".join(out))


def halftone(w, h):
    """Dot grid that swells towards one corner, shifting mauve to blue."""
    m = min(w, h)
    step = m / 28
    out = []
    y = step / 2
    while y < h:
        x = step / 2
        while x < w:
            t = min(1, math.hypot(w - x, h - y) / math.hypot(w, h) * 1.5)  # 0 at bottom-right
            r = step * 0.42 * (1 - t) ** 1.4
            if r > 0.8:
                c = C["mauve"] if (x / w + y / h) < 1.4 else C["blue"]
                out.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r:.1f}" fill="{c}" fill-opacity="{.35 + .6*(1-t):.2f}"/>')
            x += step
        y += step
    return svg(w, h, "".join(out))


def flowlines(w, h):
    """Many thin horizontal lines bent by a shared swell, coloured top to bottom."""
    cols = [C["mauve"], C["pink"], C["flam"], C["peach"], C["yellow"], C["green"], C["teal"], C["sapph"], C["blue"], C["lav"]]
    m = min(w, h)
    n = 46
    out = []
    for i in range(n):
        y0 = h * (0.15 + 0.7 * i / (n - 1))
        c = cols[int(i / n * len(cols))]
        pts = []
        for x in range(0, w + 11, 10):
            u = (x / w - 0.5) * 2
            bump = math.exp(-(u * 1.6) ** 2) * m * 0.12 * math.sin(i / n * math.pi)
            pts.append(f"{x} {y0 - bump + m*0.015*math.sin(x/w*6 + i*.25):.1f}")
        out.append(f'<path d="M{" L".join(pts)}" fill="none" stroke="{c}" stroke-width="3" stroke-opacity=".95"/>')
    return svg(w, h, "".join(out))


def mosaic(w, h):
    """Low-poly triangle field in dark tones with a few lit accent shards."""
    random.seed(5)
    m = min(w, h)
    cell = m / 7
    nx, ny = math.ceil(w / cell) + 1, math.ceil(h / cell) + 1
    jit = cell * .3
    P = [[(i * cell + random.uniform(-jit, jit) * (0 < i < nx - 1 or 0),
           j * cell + random.uniform(-jit, jit) * (0 < j < ny - 1 or 0)) for i in range(nx)] for j in range(ny)]
    tones = [C["crust"], C["mantle"], C["base"], C["s0"]]
    accents = [C["mauve"], C["lav"], C["blue"], C["pink"]]
    out = []
    for j in range(ny - 1):
        for i in range(nx - 1):
            a, b, c, d = P[j][i], P[j][i + 1], P[j + 1][i], P[j + 1][i + 1]
            for tri in ((a, b, c), (b, d, c)):
                if random.random() < .06:
                    col, op = random.choice(accents), .55
                else:
                    shade = (tri[0][0] / w * .5 + tri[0][1] / h * .5)
                    col, op = tones[min(3, int(shade * 3 + random.random()))], 1
                pts = " ".join(f"{x:.0f},{y:.0f}" for x, y in tri)
                out.append(f'<polygon points="{pts}" fill="{col}" fill-opacity="{op}" stroke="{C["crust"]}" stroke-width="1.5"/>')
    return svg(w, h, "".join(out))


def ribbons(w, h):
    """Three wide translucent ribbons sweeping across the screen."""
    m = min(w, h)
    portrait = h > w
    out = []
    for k, (c, o) in enumerate([(C["blue"], .35), (C["mauve"], .4), (C["pink"], .35)]):
        pts_a, pts_b = [], []
        L = h if portrait else w
        for s in range(0, L + 11, 10):
            u = s / L
            mid = 0.5 + 0.22 * math.sin(u * math.pi * 1.6 + k * 1.1)
            thick = m * (0.05 + 0.04 * math.sin(u * math.pi * 2 + k))
            if portrait:
                pts_a.append(f"{mid*w - thick:.1f} {s}"); pts_b.append(f"{mid*w + thick:.1f} {s}")
            else:
                pts_a.append(f"{s} {mid*h - thick:.1f}"); pts_b.append(f"{s} {mid*h + thick:.1f}")
        d = "M" + " L".join(pts_a) + " L" + " L".join(reversed(pts_b)) + " Z"
        out.append(f'<path d="{d}" fill="{c}" fill-opacity="{o}"/>')
    return svg(w, h, "".join(out))


def blocks(w, h):
    """Overlapping rounded cards in a tilted stack, slightly off centre."""
    m = min(w, h)
    cols = [C["s0"], C["s1"], C["lav"], C["mauve"], C["pink"], C["peach"]]
    out = []
    for i, c in enumerate(cols):
        bw, bh = m * .55, m * .32
        cx = w * .5 + (i - 2.5) * m * .045
        cy = h * .5 + (i - 2.5) * m * .045
        a = math.radians(-18)
        corners = [(-bw/2, -bh/2), (bw/2, -bh/2), (bw/2, bh/2), (-bw/2, bh/2)]
        pts = " ".join(f"{cx + x*math.cos(a) - y*math.sin(a):.0f},{cy + x*math.sin(a) + y*math.cos(a):.0f}" for x, y in corners)
        out.append(f'<polygon points="{pts}" fill="{c}" fill-opacity="{.95 if i < 2 else .75}" '
                   f'stroke="{c}" stroke-opacity="{.95 if i < 2 else .75}" stroke-width="{m*.03:.0f}" stroke-linejoin="round"/>')
    return svg(w, h, "".join(out))


DESIGNS = (waves, stripes, contours, bauhaus, ridges, halftone, flowlines, mosaic, ribbons, blocks)

if __name__ == "__main__":
    outdir = sys.argv[1]
    for fn in DESIGNS:
        for tag, (w, h) in (("landscape", (1920, 1080)), ("portrait", (1080, 1920))):
            with open(os.path.join(outdir, f"{fn.__name__}-{tag}.svg"), "w") as f:
                f.write(fn(w, h))
