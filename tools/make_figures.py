#!/usr/bin/env python3
"""Draws the help figures of the EquaForgeAerospace blocks.

    python tools/make_figures.py

writes symbol-only SVG figures into Resources/Documentation/figures/, with the drawing kit of
EquaForge's tools/make_library_figures.py (found through EF_SOURCE_DIR, or the app checkout
this folder sits in, toolboxes/EquaForgeAerospace). The profile figures (the standard
atmosphere, the hover-slam, the orbit) are computed from the same equations as the blocks.
Edit this file and run it again rather than editing the SVG files.
"""

import math
import os
import sys
from pathlib import Path

TOOLBOX = Path(__file__).resolve().parents[1]
APP = Path(os.environ.get("EF_SOURCE_DIR") or TOOLBOX.parents[1])
if not (APP / "tools" / "make_library_figures.py").is_file():
    sys.exit(f"no EquaForge checkout at {APP}: set EF_SOURCE_DIR")
sys.path.insert(0, str(APP / "tools"))
from make_library_figures import FONT, Figure, body_outline, mb, mi, rot, write  # noqa: E402,F401

Figure.generator = "tools/make_figures.py"
ROOT = TOOLBOX / "Resources" / "Documentation" / "figures"


def j2():
    f = Figure(440, 320)
    cx, cy, rx, ry = 160, 175, 118, 100
    f.path(f"M{cx - rx} {cy}A{rx} {ry} 0 1 0 {cx + rx} {cy}A{rx} {ry} 0 1 0 {cx - rx} {cy}Z")
    f.line(cx - rx - 20, cy, cx + rx + 30, cy, dash=True, width=1.2)
    f.arrow(cx, cy + ry + 20, cx, cy - ry - 50)
    f.text(cx - 10, cy - ry - 52, mi("z"), anchor="end")
    f.circle(cx, cy, 3, fill=True)
    lat = 38
    r = 230
    px, py = cx + r * math.cos(math.radians(lat)), cy - r * math.sin(math.radians(lat))
    f.arrow(cx, cy, px, py)
    f.circle(px, py, 6, fill=True)
    f.text(cx + 0.72 * (px - cx) - 10, cy + 0.72 * (py - cy) - 8, mb("r"), anchor="end")
    f.arc(cx, cy, 70, 0, lat)
    f.text(cx + 82, cy - 16, mi("φ"), anchor="start")
    # gravity at the satellite, bent towards the equatorial bulge
    gx, gy = cx + 10, cy + 40
    n = math.hypot(gx - px, gy - py)
    f.arrow(px, py, px + 70 * (gx - px) / n, py + 70 * (gy - py) / n)
    f.text(px - 12, py + 58, mb("g"), anchor="start")
    # equatorial radius
    f.arrow(cx, cy + 26, cx + rx, cy + 26, size=9, both=True, width=1.5)
    f.sym(cx + rx / 2, cy + 56, mi("R"), "e")
    return f


def us76_profile():
    """Temperature to 86 km and density (log) to 300 km, as AtmosphereUS76 computes them."""
    R, r0, g0 = 287.05287, 6356766.0, 9.80665
    Hb = [0, 11000, 20000, 32000, 47000, 51000, 71000, 84852]
    Lb = [-0.0065, 0, 0.001, 0.0028, 0, -0.0028, -0.002]
    Tb = [288.15, 216.65, 216.65, 228.65, 270.65, 270.65, 214.65, 186.946]
    pb = [101325, 22632.06, 5474.889, 868.0187, 110.9063, 66.93887, 3.956420, 0.3733835]
    hu = [86000, 100000, 150000, 200000, 300000, 400000, 500000, 600000, 700000, 800000, 900000, 1000000]
    rho_u = [6.958e-6, 5.604e-7, 2.076e-9, 2.541e-10, 1.916e-11, 2.803e-12, 5.215e-13, 1.137e-13,
             3.070e-14, 1.136e-14, 5.759e-15, 3.561e-15]

    def lower(h):
        H = r0 * h / (r0 + h)
        i = max(k for k in range(7) if H >= Hb[k] or k == 0)
        T = Tb[i] + Lb[i] * (min(H, Hb[7]) - Hb[i])
        p = pb[i] * (Tb[i] / T) ** (g0 / (R * Lb[i])) if Lb[i] else pb[i] * math.exp(-g0 * (H - Hb[i]) / (R * Tb[i]))
        return T, p / (R * T)

    def rho(h):
        if h < hu[0]:
            return lower(h)[1]
        for i in range(11):
            if h <= hu[i + 1]:
                w = (h - hu[i]) / (hu[i + 1] - hu[i])
                return math.exp(math.log(rho_u[i]) + w * (math.log(rho_u[i + 1]) - math.log(rho_u[i])))
        return rho_u[-1]

    f = Figure(540, 320)
    # panel 1: T against h, 0..90 km
    x0, x1, y0, y1 = 60, 230, 270, 40
    tmin, tmax, hmax = 180.0, 300.0, 90e3
    X = lambda T: x0 + (T - tmin) / (tmax - tmin) * (x1 - x0)
    Y = lambda h: y0 - h / hmax * (y0 - y1)
    f.arrow(x0, y0, x1 + 16, y0)
    f.arrow(x0, y0, x0, y1 - 16)
    for h in (0, 20e3, 40e3, 60e3, 80e3):
        f.line(x0 - 5, Y(h), x0, Y(h), width=1.2)
        f.text(x0 - 9, Y(h) + 6, f"{h / 1e3:.0f}", 15, "end")
    for T in (200, 250, 300):
        f.line(X(T), y0, X(T), y0 + 5, width=1.2)
        f.text(X(T), y0 + 22, f"{T}", 15)
    for H in Hb[1:7]:
        f.line(x0, Y(H * r0 / (r0 - H)), x1, Y(H * r0 / (r0 - H)), dash="3 4", width=0.8)
    f.polyline([(X(lower(h)[0]), Y(h)) for h in range(0, 86001, 500)], width=2.5)
    f.text(x1 + 22, y0 + 8, mi("T"), anchor="start")
    f.text(x0 - 6, y1 - 20, mi("h"), anchor="end")
    # panel 2: log density against h, 0..300 km
    u0, u1 = 320, 490
    hmax2 = 300e3
    lmin, lmax = -12.0, 1.0
    U = lambda r: u0 + (math.log10(r) - lmin) / (lmax - lmin) * (u1 - u0)
    V = lambda h: y0 - h / hmax2 * (y0 - y1)
    f.arrow(u0, y0, u1 + 16, y0)
    f.arrow(u0, y0, u0, y1 - 16)
    for h in (0, 100e3, 200e3, 300e3):
        f.line(u0 - 5, V(h), u0, V(h), width=1.2)
        f.text(u0 - 9, V(h) + 6, f"{h / 1e3:.0f}", 15, "end")
    for e in (-12, -8, -4, 0):
        f.line(U(10.0 ** e), y0, U(10.0 ** e), y0 + 5, width=1.2)
        f.text(U(10.0 ** e), y0 + 22, f"10{''.join('⁰¹²³⁴⁵⁶⁷⁸⁹'[int(d)] if d.isdigit() else '⁻' for d in str(e))}", 15)
    f.polyline([(U(rho(h)), V(h)) for h in range(0, 300001, 2000)], width=2.5)
    f.text(u1 + 22, y0 + 8, mi("ρ"), anchor="start")
    f.text(u0 - 6, y1 - 20, mi("h"), anchor="end")
    return f


def bodyaero():
    f = Figure(580, 270)
    bx, by = 80, 135
    body_outline(f, bx, by, 0, 330, 28, 50)
    f.circle(bx, by, 3.5, fill=True)
    f.arrow(bx, by, bx + 58, by)
    f.arrow(bx, by, bx, by + 58)
    f.sym(bx + 60, by - 8, mi("x"), "b", anchor="start")
    f.sym(bx - 8, by + 60, mi("y"), "b", anchor="end")
    # airspeed at the nose and the angle of attack
    tx = bx + 380
    f.line(tx, by, tx + 100, by, dash=True, width=1.2)
    a = math.radians(24)
    f.arrow(tx, by, tx + 100 * math.cos(a), by + 100 * math.sin(a))
    f.text(tx + 104 * math.cos(a) + 8, by + 104 * math.sin(a) + 14, mb("v"), anchor="start")
    f.arc(tx, by, 66, 0, -24)
    f.sym(tx + 74, by + 20, mi("α"), "t", anchor="start")
    # forces at the centre of pressure
    px = bx + 220
    f.circle(px, by, 6)
    f.circle(px, by, 2, fill=True)
    f.arrow(px, by, px - 76, by)
    f.text(px - 84, by - 8, mi("A"), anchor="end")
    f.arrow(px, by, px, by - 92)
    f.text(px + 10, by - 76, mi("N"), anchor="start")
    # place of the centre of pressure
    f.line(bx, by + 40, bx, by + 70, width=1.2)
    f.line(px, by + 20, px, by + 70, width=1.2)
    f.arrow(bx + 2, by + 62, px - 2, by + 62, size=9, both=True, width=1.5)
    f.sym((bx + px) / 2, by + 92, mi("x"), "cp")
    return f


def tank():
    f = Figure(330, 360)
    x0, x1, top, bot, r = 100, 220, 50, 310, 30
    f.path(f"M{x0} {top + r}A{(x1 - x0) / 2} {r} 0 0 1 {x1} {top + r}L{x1} {bot - r}"
           f"A{(x1 - x0) / 2} {r} 0 0 1 {x0} {bot - r}Z")
    lvl = 175
    f.path(f"M{x0} {lvl}L{x1} {lvl}L{x1} {bot - r}A{(x1 - x0) / 2} {r} 0 0 1 {x0} {bot - r}Z", fill=0.16, width=1.2)
    f.sym(160, 118, mi("p"), "", 22)
    f.sym(160, 146, mi("m"), "g")
    f.sym(160, 248, mi("m"), "l")
    # outlet, pressurant and vent
    f.arrow(160, bot, 160, bot + 42)
    f.mdot(172, bot + 40, "m", "out", anchor="start")
    f.arrow(130, top - 32, 130, top + 6)
    f.mdot(124, top - 18, "m", "press", anchor="end")
    f.arrow(192, top + 6, 192, top - 32)
    f.mdot(200, top - 18, "m", "vent", anchor="start")
    # heat through the wall
    f.arrow(300, 230, x1 + 4, 230)
    f.mdot(268, 222, "Q", "", anchor="middle")
    # liquid level
    f.line(x0 - 28, lvl, x0 - 6, lvl, width=1.2)
    f.line(x0 - 28, bot, x0 - 6, bot, width=1.2)
    f.arrow(x0 - 18, bot - 2, x0 - 18, lvl + 2, size=9, both=True, width=1.5)
    f.text(x0 - 26, (lvl + bot) / 2 + 8, "ℓ", anchor="end")
    # settling acceleration
    f.arrow(30, 270, 30, 190)
    f.sym(38, 196, mi("a"), "x", anchor="start")
    return f


def nozzle():
    f = Figure(520, 250)
    cy = 125
    for s in (-1, 1):  # the upper and the lower wall: chamber, throat, bell
        f.path(f"M80 {cy + 70 * s}L170 {cy + 70 * s}L220 {cy + 22 * s}Q240 {cy + 18 * s} 260 {cy + 30 * s}"
               f"Q330 {cy + 75 * s} 400 {cy + 92 * s}")
    f.line(80, 55, 80, 2 * cy - 55)
    f.line(400, cy - 100, 400, cy + 100, dash=True, width=1.2)
    f.sym(125, cy + 8, mi("p"), "c")
    f.sym(365, cy - 18, mi("p"), "e")
    f.sym(408, cy + 128 - 10, mi("A"), "e", anchor="start")
    # ambient pressure on the exit plane, the exhaust, the thrust
    for y in (cy - 62, cy + 62):
        f.arrow(470, y, 406, y, size=9, width=1.5)
    f.sym(476, cy - 54, mi("p"), "a", anchor="start")
    f.arrow(300, cy + 8, 372, cy + 8, size=9, width=1.5)
    f.sym(330, cy + 36, mi("v"), "e")
    f.arrow(74, cy, 14, cy)
    f.text(30, cy - 14, mi("F"))
    return f


def cluster():
    f = Figure(320, 280)
    cx, cy, rr = 150, 145, 72
    f.circle(cx, cy, rr, dash=True, width=1.2)
    f.arrow(cx, cy, cx + 125, cy, size=10, width=1.5)
    f.arrow(cx, cy, cx, cy - 125, size=10, width=1.5)
    f.text(cx + 130, cy + 8, mi("y"), anchor="start")
    f.text(cx + 10, cy - 116, mi("z"), anchor="start")
    phi = 90
    angles = [phi, phi + 120, phi + 240]
    for k, a in enumerate(angles):
        ex, ey = cx + rr * math.cos(math.radians(a)), cy - rr * math.sin(math.radians(a))
        f.circle(ex, ey, 22)
        if k == 0:
            f.line(ex - 15, ey - 15, ex + 15, ey + 15, width=3)
            f.line(ex - 15, ey + 15, ex + 15, ey - 15, width=3)
    f.arc(cx, cy, 34, 0, phi - 18)
    f.text(cx + 34, cy - 30, mi("φ"), anchor="start")
    a = math.radians(angles[1])
    f.line(cx, cy, cx + (rr - 22) * math.cos(a), cy - (rr - 22) * math.sin(a), width=1.2)
    f.text(cx - 40, cy + 2, mi("r"), anchor="end")
    s = rr / 2
    f.arrow(cx, cy, cx, cy + s, size=9)
    f.circle(cx, cy + s, 4, fill=True)
    f.text(cx + 12, cy + s + 6, mi("Δ"), anchor="start")
    f.circle(cx, cy, 3, fill=True)
    return f


def orbit():
    """Orbital elements, a = 1, e = 0.25, i = 40 deg, RAAN = 50 deg, argument of periapsis 70 deg."""
    S = 125
    ex, ey = (-0.55, 0.42), (1.0, 0.0)
    origin = [0.0, 0.0]

    def P(v):
        X, Y, Z = v
        return origin[0] + S * (X * ex[0] + Y * ey[0]), origin[1] + S * (X * ex[1] + Y * ey[1] - Z)

    def Rz(t, v):
        c, s = math.cos(t), math.sin(t)
        return (c * v[0] - s * v[1], s * v[0] + c * v[1], v[2])

    def Rx(t, v):
        c, s = math.cos(t), math.sin(t)
        return (v[0], c * v[1] - s * v[2], s * v[1] + c * v[2])

    a, e, inc, raan, argp, nu = 1.0, 0.25, math.radians(40), math.radians(50), math.radians(70), math.radians(118)
    p = a * (1 - e * e)

    def orbit_pt(t, rr=None):
        r = p / (1 + e * math.cos(t)) if rr is None else rr
        return Rz(raan, Rx(inc, Rz(argp, (r * math.cos(t), r * math.sin(t), 0))))

    def plane_pt(u, rr):  # in the orbit plane, angle u from the node
        return Rz(raan, Rx(inc, (rr * math.cos(u), rr * math.sin(u), 0)))

    # fit the page to the drawing: the orbit, the equator and the axes with their labels
    extent = [P(orbit_pt(k * math.pi / 90)) for k in range(181)]
    extent += [P((math.cos(k * math.pi / 30), math.sin(k * math.pi / 30), 0)) for k in range(61)]
    extent += [P((1.5, 0, 0)), P((0, 1.6, 0)), P((0, 0, 1.4))]
    margin = 30
    xs, ys = [q[0] for q in extent], [q[1] for q in extent]
    origin[0], origin[1] = margin - min(xs), margin - min(ys)
    f = Figure(int(max(xs) - min(xs) + 2 * margin), int(max(ys) - min(ys) + 2 * margin))

    # the equator, the axes
    f.polyline([P((math.cos(t), math.sin(t), 0)) for t in [k * math.pi / 60 for k in range(121)]], dash=True, width=1.2)
    for v, lab in (((1.35, 0, 0), "x"), ((0, 1.45, 0), "y"), ((0, 0, 1.25), "z")):
        f.arrow(*P((0, 0, 0)), *P(v), size=10, width=1.5)
        x, y = P(tuple(1.08 * c for c in v))
        f.text(x + (-10 if lab == "x" else 8), y + (10 if lab == "x" else 0), mi(lab), anchor="end" if lab == "x" else "start")
    # the orbit
    f.polyline([P(orbit_pt(t)) for t in [k * math.pi / 90 for k in range(181)]], width=2.5)
    # line of nodes and of apsides
    node = Rz(raan, (1, 0, 0))
    f.line(*P((0, 0, 0)), *P(tuple(1.3 * c for c in node)), dash=True, width=1.2)
    peri = orbit_pt(0)
    f.line(*P((0, 0, 0)), *P(peri), dash=True, width=1.2)
    f.circle(*P(peri), 3.5, fill=True)
    # the vehicle
    sat = orbit_pt(nu)
    f.arrow(*P((0, 0, 0)), *P(sat))
    f.circle(*P(sat), 6, fill=True)
    x, y = P(tuple(0.55 * c for c in sat))
    f.text(x - 4, y + 26, mb("r"))
    # angular momentum
    hdir = Rz(raan, Rx(inc, (0, 0, 1)))
    f.arrow(*P((0, 0, 0)), *P(tuple(1.05 * c for c in hdir)))
    x, y = P(tuple(1.12 * c for c in hdir))
    f.text(x - 6, y, mb("h"), anchor="end")
    # angles: RAAN in the equator, argument of periapsis and true anomaly in the orbit plane
    f.polyline([P((0.42 * math.cos(t), 0.42 * math.sin(t), 0)) for t in [raan * k / 20 for k in range(21)]], width=1.5)
    x, y = P((0.55 * math.cos(raan / 2), 0.55 * math.sin(raan / 2), 0))
    f.text(x, y + 16, mi("Ω"))
    f.polyline([P(plane_pt(argp * k / 20, 0.35)) for k in range(21)], width=1.5)
    x, y = P(plane_pt(argp / 2, 0.47))
    f.text(x + 6, y + 4, mi("ω"))
    f.polyline([P(plane_pt(argp + nu * k / 20, 0.62)) for k in range(21)], width=1.5)
    x, y = P(plane_pt(argp + nu / 2, 0.50))
    f.text(x + 4, y + 10, mi("ν"))
    # inclination at the node: between the equator and the orbit
    nx, ny, nz = tuple(1.0 * c for c in node)
    east = Rz(raan, (0, 1, 0))
    along = Rz(raan, Rx(inc, (0, 1, 0)))
    pts = []
    for k in range(13):
        t = inc * k / 12
        d = tuple(math.cos(t) * east[j] + math.sin(t) * (along[j] - math.cos(inc) * east[j]) / math.sin(inc) for j in range(3))
        pts.append(P(tuple((nx, ny, nz)[j] + 0.28 * d[j] for j in range(3))))
    f.polyline(pts, width=1.5)
    f.line(*P(node), *P(tuple(node[j] + 0.42 * east[j] for j in range(3))), width=1.2)
    x, y = pts[6]
    f.text(x + 14, y + 24, mi("i"), anchor="start")
    return f


def attitude():
    f = Figure(440, 290)
    ox, oy = 150, 220
    f.arrow(ox, oy, ox + 230, oy - 110, size=12, width=3)
    f.text(ox + 238, oy - 112, mb("x"), anchor="start")
    f.arrow(ox, oy, ox + 160, oy - 190, dash=True)
    f.sym(ox + 166, oy - 192, mb("x"), "t", anchor="start")
    a0 = math.degrees(math.atan2(110, 230))
    a1 = math.degrees(math.atan2(190, 160))
    f.arc(ox, oy, 110, a0, a1)
    x = ox + 124 * math.cos(math.radians((a0 + a1) / 2))
    y = oy - 124 * math.sin(math.radians((a0 + a1) / 2))
    f.text(x + 6, y + 4, mi("θ"), anchor="start")
    # the turn axis x × x_t points out of the page
    f.circle(ox, oy, 11)
    f.circle(ox, oy, 3, fill=True)
    f.text(ox + 4, oy + 38, mb("a"))
    # roll reference and the target's y axis
    f.arrow(ox, oy, ox - 82, oy - 150, dash="2 5")
    f.text(ox - 90, oy - 150, mb("r"), anchor="end")
    xt = (160 / math.hypot(160, 190), -190 / math.hypot(160, 190))
    rv = (-82, -150)
    d = rv[0] * xt[0] + rv[1] * xt[1]
    yt = (rv[0] - d * xt[0], rv[1] - d * xt[1])
    n = math.hypot(*yt)
    f.arrow(ox, oy, ox + 120 * yt[0] / n, oy + 120 * yt[1] / n, dash=True)
    f.sym(ox + 128 * yt[0] / n - 6, oy + 128 * yt[1] / n + 4, mb("y"), "t", anchor="end")
    return f


def entry():
    f = Figure(430, 290)
    cx, cy = 190, 160
    al = 60
    tx, ty = rot(-120, 0, cx, cy, al)
    pg = [rot(a, b, tx, ty, al) for a, b in ((0, -26), (200, -26), (240, 0), (200, 26), (0, 26))]
    f.path("M" + "L".join(f"{x:.1f} {y:.1f}" for x, y in pg) + "Z", width=1.2, dash="1 4")
    f.arrow(cx, cy, cx + 170, cy)
    f.sym(cx + 176, cy + 8, mb("e"), "v", anchor="start")
    f.arrow(cx, cy, cx, cy - 140, dash=True)
    f.text(cx - 10, cy - 128, mb("n"), anchor="end")
    nx, ny = rot(150, 0, cx, cy, al)
    f.arrow(cx, cy, nx, ny, size=12, width=3)
    f.text(nx + 10, ny + 4, mb("d"), anchor="start")
    bx, by = rot(110, 0, cx, cy, al - 90)
    f.arrow(cx, cy, bx, by, size=12, width=3)
    f.text(bx + 10, by + 10, mb("b"), anchor="start")
    f.arc(cx, cy, 70, 0, al)
    f.text(cx + 76, cy - 40, mi("α"), anchor="start")
    f.circle(cx, cy, 3.5, fill=True)
    return f


def impact():
    f = Figure(480, 300)
    ecx, ecy, R = 240, 1000, 820
    top = ecy - R

    def surf(x):
        return ecy - math.sqrt(R * R - (x - ecx) ** 2)

    f.polyline([(x, surf(x)) for x in range(20, 461, 10)], width=2.5)
    vx, vy = 110, 70
    ix = 330
    f.path(f"M{vx} {vy}Q{250} {-20} {ix} {surf(ix)}", dash=True)
    f.circle(vx, vy, 6, fill=True)
    f.arrow(vx, vy, vx + 80, vy - 34)
    f.text(vx + 88, vy - 36, mb("v"), anchor="start")
    f.line(ix - 8, surf(ix) - 8, ix + 8, surf(ix) + 8, width=3)
    f.line(ix - 8, surf(ix) + 8, ix + 8, surf(ix) - 8, width=3)
    # the target and the range to go along the ground
    tx = 410
    f.path(f"M{tx} {surf(tx)}L{tx} {surf(tx) - 34}L{tx + 22} {surf(tx) - 27}L{tx} {surf(tx) - 20}", width=2)
    pts = [(x, surf(x) + 18) for x in range(ix, tx + 1, 5)]
    f.polyline(pts, width=1.5)
    f.head(ix, surf(ix) + 18, -1, 0.06, 8)
    f.head(tx, surf(tx) + 18, 1, 0.1, 8)
    f.text((ix + tx) / 2, surf((ix + tx) / 2) + 46, mi("s"))
    return f


def hoverslam():
    """Sink rate against height: the fall, the braking curve of PoweredDescent and the burn."""
    g, a, v0, h0, vt = 9.81, 15.0, 60.0, 1500.0, 2.0
    hi = (v0 * v0 + 2 * g * h0 - vt * vt) / (2 * (a + g))
    vi = math.sqrt(vt * vt + 2 * a * hi)
    f = Figure(420, 300)
    x0, y0, x1, y1 = 60, 260, 380, 30
    vmax, hmax = 180.0, 1600.0
    X = lambda v: x0 + v / vmax * (x1 - x0)
    Y = lambda h: y0 - h / hmax * (y0 - y1)
    f.arrow(x0, y0, x1 + 16, y0)
    f.arrow(x0, y0, x0, y1 - 14)
    f.text(x1 + 22, y0 + 8, mi("v"), anchor="start")
    f.text(x0 - 8, y1 - 10, mi("h"), anchor="end")
    fall = [(X(math.sqrt(v0 * v0 + 2 * g * (h0 - h))), Y(h)) for h in [h0 - k * (h0 - hi) / 60 for k in range(61)]]
    brake = [(X(math.sqrt(vt * vt + 2 * a * h)), Y(h)) for h in [hi - k * hi / 60 for k in range(61)]]
    f.polyline(fall, width=2.5)
    f.polyline(brake, width=2.5)
    f.head(*fall[30], fall[31][0] - fall[29][0], fall[31][1] - fall[29][1])
    f.head(*brake[30], brake[31][0] - brake[29][0], brake[31][1] - brake[29][1])
    # what the fall would become without the burn, and the braking curve above the ignition
    f.polyline([(X(math.sqrt(v0 * v0 + 2 * g * (h0 - h))), Y(h)) for h in [hi - k * hi / 30 for k in range(31)]], dash="2 5", width=1.5)
    f.polyline([(X(math.sqrt(vt * vt + 2 * a * h)), Y(h)) for h in [hi + k * (h0 - hi) / 30 for k in range(31)]], dash=True, width=1.2)
    f.circle(X(vi), Y(hi), 5, fill=True)
    f.line(x0, Y(hi), X(vi) - 8, Y(hi), dash="2 4", width=1)
    f.sym(x0 - 8, Y(hi) + 6, mi("h"), "i", anchor="end")
    f.circle(X(vt), y0, 4, fill=True)
    f.sym(X(vt) + 16, y0 - 10, mi("v"), "t", anchor="start")
    f.circle(X(v0), Y(h0), 4, fill=True)
    x, y = brake[12]
    f.sym(x + 64, y + 10, mi("v"), "ref", anchor="start")
    return f


def stagnation():
    f = Figure(420, 240)
    ccx, cy, rn = 290, 120, 70
    f.path(f"M{ccx + 60} {cy - rn}L{ccx} {cy - rn}A{rn} {rn} 0 0 0 {ccx} {cy + rn}L{ccx + 60} {cy + rn}")
    f.path(f"M{ccx - 20} {cy - 110}Q{ccx - 125} {cy} {ccx - 20} {cy + 110}", dash=True, width=1.5)
    for dy in (-50, 0, 50):
        f.arrow(30, cy + dy, 100, cy + dy, size=10, width=1.5)
    f.text(64, cy - 64, mi("V"))
    f.text(64, cy + 88, mi("ρ"))
    f.circle(ccx, cy, 3, fill=True)
    sx = ccx - rn
    f.arrow(ccx, cy, sx + 6, cy, size=9, width=1.5)
    f.sym((ccx + sx) / 2 + 6, cy - 10, mi("R"), "n")
    f.circle(sx, cy, 5, fill=True)
    f.arrow(sx - 40, cy + 40, sx - 4, cy + 6, size=10)
    f.text(sx - 46, cy + 60, mi("q"), anchor="end")
    return f


FIGURES = {
    "j2.svg": j2,
    "us76.svg": us76_profile,
    "bodyaero.svg": bodyaero,
    "tank.svg": tank,
    "nozzle.svg": nozzle,
    "cluster.svg": cluster,
    "orbit.svg": orbit,
    "attitude.svg": attitude,
    "entry.svg": entry,
    "impact.svg": impact,
    "hoverslam.svg": hoverslam,
    "stagnation.svg": stagnation,
}


if __name__ == "__main__":
    write(FIGURES, ROOT)
