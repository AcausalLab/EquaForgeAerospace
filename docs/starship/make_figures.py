#!/usr/bin/env python3
"""Draws the mission profile of the Starship-class tutorial from a run of FullMission.

    python docs/starship/make_figures.py

needs the equaforge Python package (PYTHONPATH and EQUAFORGE_DLL_DIR of a build, as for the
worksheets) and the drawing kit of EquaForge's tools/make_library_figures.py (found through
EF_SOURCE_DIR, or the app checkout this toolbox sits in). It writes mission-profile.svg beside
this file: the altitudes of the ship and of the booster against time, with the events numbered
as in the tutorial's caption. The figure is drawn in currentColor, so it takes the page's
colour in Studio's Help window; its words are in the caption, not in the figure.
"""

import os
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
TOOLBOX = HERE.parents[1]
APP = Path(os.environ.get("EF_SOURCE_DIR") or TOOLBOX.parents[1])
if not (APP / "tools" / "make_library_figures.py").is_file():
    sys.exit(f"no EquaForge checkout at {APP}: set EF_SOURCE_DIR")
sys.path.insert(0, str(APP / "tools"))
from make_library_figures import Figure, mi  # noqa: E402  (the help figures' drawing kit)

Figure.generator = "docs/starship/make_figures.py"


def run():
    import equaforge as ef
    source = TOOLBOX / "examples" / "starship_mission" / "StarshipMission.mo"
    r = ef.simulate(source, model="StarshipMission.FullMission", libraries=[TOOLBOX],
                    outputs=["*.airData.h", "*.computer.flight.phase"])
    t = np.asarray(r["time"])
    return t, {k: np.asarray(r[k]) for k in ("ship.airData.h", "booster.airData.h",
                                              "ship.computer.flight.phase",
                                              "booster.computer.flight.phase")}


def first(t, phase, k):
    i = int(np.argmax(phase >= k))
    return i if phase[i] >= k else None


def profile(t, d):
    hs, hb = d["ship.airData.h"] / 1e3, d["booster.airData.h"] / 1e3
    ps, pb = d["ship.computer.flight.phase"], d["booster.computer.flight.phase"]
    tm = t / 60
    caught = first(t, pb, 6)
    # the entry interface: the ship below 120 km after its deorbit burn
    deorbit = first(t, ps, 4)
    interface = deorbit + int(np.argmax(hs[deorbit:] < 120))
    # the events, in the order of the caption: (the vehicle's altitude, the sample)
    events = [(hb, first(t, pb, 1)), (hb, first(t, pb, 2)), (hb, first(t, pb, 3)),
              (hb, first(t, pb, 5)), (hb, caught), (hs, first(t, ps, 3)), (hs, deorbit),
              (hs, interface), (hs, first(t, ps, 6)), (hs, first(t, ps, 7)), (hs, first(t, ps, 8))]
    f = Figure(640, 330)
    top, bottom, hmax = 30, 280, 240.0
    Y = lambda h: bottom - h / hmax * (bottom - top)
    panels = [(70, 250, 0.0, 9.0, (0, 3, 6, 9)), (300, 610, 60.0, 110.0, (60, 70, 80, 90, 100, 110))]
    for x0, x1, a, b, ticks in panels:
        X = (lambda x0, x1, a, b: lambda m: x0 + (m - a) / (b - a) * (x1 - x0))(x0, x1, a, b)
        f.arrow(x0, bottom, x1 + 14, bottom)
        f.arrow(x0, bottom, x0, top - 12)
        for m in ticks:
            f.line(X(m), bottom, X(m), bottom + 5, width=1.2)
            f.text(X(m), bottom + 22, f"{m:g}", 15)
        for h in (0, 100, 200):
            f.line(x0 - 5, Y(h), x0, Y(h), width=1.2)
            if x0 == panels[0][0]:
                f.text(x0 - 9, Y(h) + 6, f"{h}", 15, "end")
        inside = (tm >= a) & (tm <= b)
        f.polyline([(X(m), Y(h)) for m, h in zip(tm[inside], hs[inside])], width=2.5)
        booster = inside & (np.arange(len(t)) <= (caught if caught is not None else len(t) - 1))
        if booster.any():
            f.polyline([(X(m), Y(h)) for m, h in zip(tm[booster], hb[booster])], dash=True, width=2)
        for n, (h, i) in enumerate(events, start=1):
            if i is None or not a <= tm[i] <= b:
                continue
            x, y = X(tm[i]), Y(h[i])
            f.circle(x, y, 3.5, fill=True)
            dx, dy = OFFSETS.get(n, (0, -22))
            f.circle(x + dx, y + dy, 10, width=1.2)
            f.text(x + dx, y + dy + 5, str(n), 14)
    f.text(panels[1][1] + 18, bottom + 8, mi("t"), anchor="start")
    f.text(panels[0][0] - 12, top + 2, mi("h"), anchor="end")
    # the break between the panels
    for x in (262, 270):
        f.line(x, bottom + 6, x + 12, bottom - 6, width=1.5)
    return f


# where each event's number sits relative to its point (page pixels)
OFFSETS = {1: (16, -18), 2: (-20, -16), 3: (18, -14), 4: (-22, -2), 5: (20, -16), 6: (-4, -24),
           7: (0, -24), 8: (22, -6), 9: (-26, -4), 10: (-2, -32), 11: (24, -26)}


def main():
    t, d = run()
    with open(HERE / "mission-profile.svg", "w", encoding="utf-8", newline="\n") as f:
        f.write(profile(t, d).svg())
    for name, phase, ks in (("booster", d["booster.computer.flight.phase"], range(1, 7)),
                            ("ship", d["ship.computer.flight.phase"], range(1, 9))):
        print(name, [round(float(t[first(t, phase, k)]), 1) if first(t, phase, k) is not None else None
                     for k in ks])
    print(HERE / "mission-profile.svg")


if __name__ == "__main__":
    main()
