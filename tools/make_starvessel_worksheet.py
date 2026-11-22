#!/usr/bin/env python3
"""Writes the StarVessel mission study's worksheet,
examples/starvessel_mission/StarVesselMission_Analysis.ipynb (nbformat 4.5, no outputs), from the
cells below. `equaforge run` executes it (ctest examples.study.StarVesselMission_Analysis, with
EF_AEROSPACE_TOOLBOX_DIR set); its checks make a finished run a passing test.

    python3 tools/make_starvessel_worksheet.py [OUT.ipynb]
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "examples", "starvessel_mission", "StarVesselMission_Analysis.ipynb")

cells = []


def md(text):
    cells.append({"cell_type": "markdown", "id": f"ss-{len(cells):02d}", "metadata": {},
                  "source": text.strip("\n").splitlines(keepends=True)})


def code(text):
    cells.append({"cell_type": "code", "id": f"ss-{len(cells):02d}", "metadata": {},
                  "execution_count": None, "outputs": [],
                  "source": text.strip("\n").splitlines(keepends=True)})


md(r"""
# A StarVessel round trip: from the pad to orbit and back

Two reusable stages fly from a launch site at 26° N: the booster lifts the stack, cuts off with its return propellant, flips, burns back, falls tail-first and brakes into the arms of the tower it left; the ship flies on to a 185 × 225 km orbit, releases a 100 t payload, coasts most of an orbit, burns at the moment its ground track will bring it back over the launch site, enters belly-first, falls belly-first through the lower atmosphere and lands on its legs beside the tower. Everything is in **StarVesselMission.mo** beside this worksheet: 6-DOF vehicles with their propellant feed, engines, actuators, aerodynamics, heat shield and flight computers, on the turning Earth.

This worksheet looks at the mission the way its designers would:

1. the rocket equation and the staging, symbolically, against the masses of the model,
2. the ascent: propellant, gravity and drag losses, max-Q,
3. orbit planning: the orbit, Kepler and J2, a Hohmann raise, the ground track and the pass that comes home,
4. the booster's return: shooting the boostback, the hover-slam, the catch,
5. entry: the Sutton–Graves heat flux, the heat load and the heat shield,
6. the landing burn against the fuel-optimal one (`ef.optimal_control`),
7. the autopilot: `ef.linearize` of the landing ship's pitch and the margins of its loop,
8. Monte Carlo: the booster's catch under engine and load dispersions,
9. the whole mission in one run, its timeline and the 3-D animation.

The vehicle data are illustrative, rounded from public estimates for a fully reusable two-stage launcher; they are not any manufacturer's data. The **settings** cell holds the worksheet's choices: change it and run all again.
""")

code(r"""
# Settings
MC_RUNS = 12                   # Monte Carlo runs of the booster's return (section 8)
MC_THRUST, MC_RESERVE, MC_LOAD = 0.005, 0.01, 0.002   # 1-sigma: engine thrust, cutoff reserve, oxygen load
BIAS_SWEEP = (-550, -150, 5)   # boostback drag bias swept in section 4 (m): from, to, points
HOHMANN_TO = 400e3             # target of the Hohmann raise in section 3 (m)
DESCENT_TIMES = (16, 18, 20)   # final times of the fuel-optimal landing burn (s), section 6
LOOP_BANDWIDTH = 1.25          # attitude loop in the landing burn (rad/s): 2.5 x 0.5, as the model
""")

code(r"""
from pathlib import Path
import tempfile
import numpy as np
import matplotlib.pyplot as plt
import sympy as sp
from scipy.integrate import solve_ivp
from IPython.display import Markdown, display
import equaforge as ef

here = Path.cwd()  # the kernel runs in the worksheet's folder
source = here / "StarVesselMission.mo"
assert source.is_file(), "run this worksheet from its folder (StarVesselMission.mo beside it)"
# the blocks come from the EquaForgeAerospace toolbox: this study is its examples/starvessel_mission
toolbox = here.parents[1]
assert (toolbox / "library.json").is_file(), "keep this study in the toolbox's examples folder"
libraries = [toolbox]
out = Path(tempfile.mkdtemp(prefix="equaforge-starvessel-"))
MU, RE, J2, WE, G0 = 3.986004418e14, 6378137.0, 1.08262668e-3, 7.2921159e-5, 9.80665
DEG = 180 / np.pi

def sim(model, **kw):
    return ef.simulate(source, model="StarVesselMission." + model, libraries=libraries, **kw)

def first(mask):
    return int(np.argmax(mask)) if np.any(mask) else len(mask) - 1

def vec(r, name):
    return np.stack([r[f"{name}[{k}]"] for k in (1, 2, 3)], axis=1)
""")

md(r"""
## 1. The rocket equation and the staging

Each stage gains $\Delta v = I_{sp}\, g_0 \ln(m_0/m_f)$ from burning its propellant. With $N$ stages of equal structural ratio $\varepsilon$ (dry mass over stage mass) and the same exhaust speed, the payload fraction that a total $\Delta v$ leaves is largest when each stage gives the same share; SymPy writes it out below for two stages. The numbers that follow come from the model's own parameters.
""")

code(r"""
dv, c, eps, n = sp.symbols("Delta_v c varepsilon N", positive=True)
# each stage: m_f/m_0 = exp(-dv/(N c)); payload ratio per stage: (exp(-dv/(N c)) - eps)/(1 - eps)
per_stage = (sp.exp(-dv / (n * c)) - eps) / (1 - eps)
payload = per_stage**n
display(Markdown("Payload fraction of $N$ equal stages:"), sp.Eq(sp.Symbol("lambda"), payload))
lam2 = sp.lambdify((dv, c, eps), payload.subs(n, 2))
lam1 = sp.lambdify((dv, c, eps), payload.subs(n, 1))
for e in (0.05, 0.08):
    print(f"structural ratio {e}: payload fraction for 9.4 km/s at c = 3.5 km/s: "
          f"one stage {lam1(9400, 3500, e):.4f}, two stages {lam2(9400, 3500, e):.4f}")
# one stage cannot reach orbit with these numbers; two can
assert lam1(9400, 3500, 0.08) < 0 < lam2(9400, 3500, 0.08)
""")

code(r"""
booster_dry, booster_prop = 2.75e5, 2.661e6 + 7.39e5
ship_dry, ship_prop, payload_t = 1.4e5, 1.151e6 + 3.18e5 + 2.05e4 + 5.7e3, 1e5
m0 = booster_dry + booster_prop + ship_dry + ship_prop + payload_t
rows = [("Booster, dry", booster_dry), ("Booster, propellant", booster_prop),
        ("Ship, dry", ship_dry), ("Ship, propellant (main and header tanks)", ship_prop),
        ("Payload", payload_t), ("At lift-off", m0)]
display(Markdown("| Mass | t |\n|---|---|\n" + "\n".join(f"| {k} | {v/1e3:,.0f} |" for k, v in rows)))
print(f"lift-off weight {m0*G0/1e6:.1f} MN against 33 engines of about 2.45 MN at sea level: "
      f"thrust/weight {33*2.45e6/(m0*G0):.2f}")
""")

md(r"""
## 2. The ascent

`AscentToOrbit` flies the stack from the mount. Its result gives the propellant the stages burn, the speed they lose to gravity and drag, and the dynamic pressure the stack meets. The gravity loss is $\int g \sin\gamma\, dt$ along the flight path ($\gamma$ the flight-path angle), the drag loss $\int D/m\, dt$.
""")

code(r"""
asc = sim("AscentToOrbit")
t = asc.time
iMECO = first(asc["booster.computer.flight.phase"] >= 2)
iSECO = first(asc["ship.computer.flight.phase"] >= 3)
r_ship = np.linalg.norm(vec(asc, "ship.motion.r"), axis=1)
g = MU / r_ship**2
gamma = asc["ship.airData.flightPathAngle"]
gravity_loss = np.trapezoid((g * np.sin(gamma))[:iSECO], t[:iSECO])
m_stack = asc["booster.computer.mass"]
drag_loss = (np.trapezoid((asc["booster.aero.drag"] / m_stack)[:iMECO], t[:iMECO]) +
             np.trapezoid((asc["ship.aero.drag"] / asc["ship.shipMass.y.m"])[iMECO:iSECO], t[iMECO:iSECO]))
iq = int(np.argmax(asc["ship.airData.qbar"]))
v_seco = np.linalg.norm(vec(asc, "ship.motion.v")[iSECO])
display(Markdown(f"Main engine cutoff at **{t[iMECO]:.1f} s**, {asc['booster.airData.h'][iMECO]/1e3:.1f} km and "
                 f"{asc['booster.airData.speedGround'][iMECO]:.0f} m/s; the ship's cutoff at **{t[iSECO]:.1f} s**, "
                 f"{v_seco:.0f} m/s inertial. Max-Q **{asc['ship.airData.qbar'][iq]/1e3:.1f} kPa** at {t[iq]:.0f} s "
                 f"(Mach {asc['ship.airData.Mach'][iq]:.2f}). Gravity loss **{gravity_loss:.0f} m/s**, drag loss "
                 f"**{drag_loss:.0f} m/s**."))
fig, ax = plt.subplots(1, 3, figsize=(13, 3.4))
ax[0].plot(t, asc["ship.airData.h"] / 1e3, label="ship"); ax[0].plot(t, asc["booster.airData.h"] / 1e3, label="booster")
ax[0].set(xlabel="time (s)", ylabel="altitude (km)"); ax[0].legend()
ax[1].plot(t, asc["ship.airData.qbar"] / 1e3); ax[1].set(xlabel="time (s)", ylabel="dynamic pressure (kPa)", xlim=(0, 200))
ax[2].plot(t, asc["ship.feed.propellant"] / 1e3, label="ship"); ax[2].plot(t, asc["booster.feed.propellant"] / 1e3, label="booster")
ax[2].set(xlabel="time (s)", ylabel="propellant (t)"); ax[2].legend(); fig.tight_layout(); plt.show()
# gravity loss of a heavy launcher: 1.0 to 1.6 km/s
assert 1000 < gravity_loss < 1600, gravity_loss
""")

md(r"""
The propellant the booster's tanks lose up to cutoff is the flow its three engine rings drew, plus a little boil-off and the gas its pressurisation keeps in the tanks: an independent check of the feed system's mass balance.
""")

code(r"""
flow = sum(asc[f"booster.{ring}.mdot"] for ring in ("centerRing", "innerRing", "outerRing"))
burned = asc["booster.feed.propellant"][0] - asc["booster.feed.propellant"][iMECO]
drawn = np.trapezoid(flow[:iMECO + 1], t[:iMECO + 1])
print(f"booster to cutoff: tanks lost {burned/1e3:.1f} t, engines drew {drawn/1e3:.1f} t ({(burned - drawn)/burned:+.2%})")
assert abs(burned - drawn) < 5e-3 * burned
""")

md(r"""
## 3. Orbit planning

`OrbitPlanning` follows the ship from insertion as a point in the Earth's gravity with its J2 flattening, three orbits long. The vis-viva equation gives the semi-major axis from the insertion state alone; Kepler's third law the period, which the ascending-node crossings of the run measure. J2 turns the orbit's node at $\dot\Omega = -\tfrac32 n J_2 (R_e/p)^2 \cos i$, and the ground track can reach no higher latitude than the inclination.
""")

code(r"""
orb = sim("OrbitPlanning")
to = orb.time
r0, v0 = vec(orb, "ship.motion.r")[0], vec(orb, "ship.motion.v")[0]
a_visviva = 1 / (2 / np.linalg.norm(r0) - v0 @ v0 / MU)
z = orb["ship.motion.r[3]"]
nodes = np.array([to[i] - z[i] * (to[i + 1] - to[i]) / (z[i + 1] - z[i]) for i in range(len(z) - 1) if z[i] < 0 <= z[i + 1]])
a_mean, inc = orb["orbit.a"].mean(), orb["orbit.inclination"].mean()
T_kepler = 2 * np.pi * np.sqrt(a_mean**3 / MU)
raan = np.unwrap(orb["orbit.raan"])
rate_sim = np.polyfit(to, raan, 1)[0]
rate_theory = -1.5 * np.sqrt(MU / a_mean**3) * J2 * (RE / (a_mean * (1 - orb["orbit.e"].mean()**2)))**2 * np.cos(inc)
lat_max = np.max(np.abs(orb["track.latitude"]))
display(Markdown(f"Insertion: {orb['orbit.periapsis'][0]/1e3:.0f} × {orb['orbit.apoapsis'][0]/1e3:.0f} km at "
                 f"{inc*DEG:.2f}°; vis-viva a = {a_visviva/1e3:.1f} km (the block {orb['orbit.a'][0]/1e3:.1f} km). "
                 f"Period {T_kepler:.0f} s (Kepler), {np.diff(nodes).mean():.0f} s between ascending nodes. "
                 f"Node regression {rate_sim*DEG*86400:.2f}°/day (theory {rate_theory*DEG*86400:.2f}°/day)."))
assert abs(a_visviva - orb["orbit.a"][0]) < 1.0
assert abs(np.diff(nodes).mean() - T_kepler) < 5e-3 * T_kepler   # J2 shortens the nodal period a little
assert abs(rate_sim / rate_theory - 1) < 0.02
assert abs(lat_max - inc) < 0.1 / DEG
""")

md(r"""
An independent integration: SciPy's `solve_ivp` propagates the same insertion state with the point-mass and J2 accelerations written out here. After one orbit the two runs agree within metres.
""")

code(r"""
def j2_rhs(_, y):
    r, v = y[:3], y[3:]
    rn = np.linalg.norm(r); z2 = (r[2] / rn)**2
    k = 1.5 * J2 * MU * RE**2 / rn**5
    return np.concatenate([v, -MU * r / rn**3 + k * r * np.array([5*z2 - 1, 5*z2 - 1, 5*z2 - 3])])

t1 = to[0] + T_kepler
ref = solve_ivp(j2_rhs, (to[0], t1), np.concatenate([r0, v0]), rtol=1e-12, atol=1e-6, dense_output=True)
i1 = int(np.argmin(abs(to - t1)))
gap = np.linalg.norm(vec(orb, "ship.motion.r")[i1] - ref.sol(to[i1])[:3])
print(f"after one orbit the two propagations differ by {gap:.2f} m")
assert gap < 100
fig, ax = plt.subplots(figsize=(10, 4))
lon = np.unwrap(orb["track.longitude"]) * DEG
ax.plot(lon, orb["track.latitude"] * DEG, lw=1)
ax.plot(-1.69575 * DEG, 0.45373 * DEG, "r*", ms=12, label="launch and landing site")
ax.set(xlabel="longitude (deg, unwrapped)", ylabel="latitude (deg)", title="Ground track, three orbits"); ax.legend(); plt.show()
""")

md(r"""
A Hohmann transfer to a higher orbit: a prograde burn at apoapsis raises the opposite side to the target, a second one there circularises. The first burn, run in `OrbitPlanning` with its `tBurn` and `dvBurn`, lifts the apoapsis to the target the formula promises, within the some 10 km that J2 makes the osculating elements of this orbit wander.
""")

code(r"""
ra = RE + orb["orbit.apoapsis"][0]; rp = RE + orb["orbit.periapsis"][0]; rt = RE + HOHMANN_TO
a1 = (ra + rp) / 2; at_ = (ra + rt) / 2
dv1 = np.sqrt(MU * (2 / ra - 1 / at_)) - np.sqrt(MU * (2 / ra - 1 / a1))
dv2 = np.sqrt(MU / rt) - np.sqrt(MU * (2 / rt - 1 / at_))
# the first apoapsis: the sample nearest a true anomaly of half a turn, in the first orbit
one = orb.time < to[0] + T_kepler
i_apo = int(np.argmin(np.where(one, np.abs(np.angle(np.exp(1j * (orb["orbit.trueAnomaly"] - np.pi)))), np.inf)))
hoh = sim("OrbitPlanning", stop=to[0] + 2 * T_kepler, set={"tBurn": to[i_apo], "dvBurn": dv1})
after = first(hoh.time > to[i_apo] + 200)
print(f"Hohmann from {orb['orbit.apoapsis'][0]/1e3:.0f} km to {HOHMANN_TO/1e3:.0f} km: {dv1:.1f} + {dv2:.1f} m/s; "
      f"after the first burn the orbit reaches {hoh['orbit.apoapsis'][after]/1e3:.1f} km")
# the osculating elements of a J2 orbit wander by some 10 km around the orbit: the formula holds to that
assert abs(hoh["orbit.apoapsis"][after] - HOHMANN_TO) < 20e3
""")

md(r"""
### The pass that comes home

The ship has to come down beside the tower. Seen from the orbit, the landing site turns east with the Earth by about 22.6° an orbit, and the ground track only passes near it every so often. The deorbit time follows from the geometry of the descent: in `FullMission` the ship flies from its burn to touchdown through a fixed angle in its orbit plane and in a fixed time. Turning the orbital position at each candidate burn time by that angle and asking where the ground lies under it that much later shows which burn times bring the ship home; the earliest is on the first orbit, the next a day later.
""")

code(r"""
mission = sim("FullMission")
tm = mission.time
i_burn = first(mission["ship.computer.flight.phase"] >= 4)
i_down = first(mission["ship.landed"] > 0.5)
R = vec(mission, "ship.motion.r"); V = vec(mission, "ship.motion.v")
nh = np.cross(R[i_burn], V[i_burn]); nh /= np.linalg.norm(nh)
ub, ul = R[i_burn] / np.linalg.norm(R[i_burn]), R[i_down] / np.linalg.norm(R[i_down])
dtheta = np.arctan2(np.cross(ub, ul) @ nh, ub @ ul)
dt_down = tm[i_down] - tm[i_burn]
print(f"FullMission: burn at {tm[i_burn]:.1f} s, down at {tm[i_down]:.0f} s: {dt_down:.0f} s through {dtheta*DEG:.1f} deg of its orbit")
y900 = np.concatenate([R[first(tm >= 900)], V[first(tm >= 900)]])
coast = solve_ivp(j2_rhs, (tm[first(tm >= 900)], 1.3 * 86400), y900, rtol=1e-11, atol=1e-3, dense_output=True, max_step=60)
lat_pad, lon_pad = 0.45373, -1.69575
def landing_point(td):
    y = coast.sol(td); r, v = y[:3], y[3:]
    n_ = np.cross(r, v); n_ /= np.linalg.norm(n_); u = r / np.linalg.norm(r)
    ul_ = np.cos(dtheta) * u + np.sin(dtheta) * np.cross(n_, u)
    th = WE * (td + dt_down)
    x, yy = np.cos(th) * ul_[0] + np.sin(th) * ul_[1], -np.sin(th) * ul_[0] + np.cos(th) * ul_[1]
    return np.arcsin(ul_[2]), np.arctan2(yy, x)
cands = np.arange(1500, 1.25 * 86400, 10.0)
miss = []
for td in cands:
    la, lo = landing_point(td)
    dlo = (lo - lon_pad + np.pi) % (2 * np.pi) - np.pi
    miss.append(RE * np.arccos(np.clip(np.sin(la) * np.sin(lat_pad) + np.cos(la) * np.cos(lat_pad) * np.cos(dlo), -1, 1)))
miss = np.array(miss)
best = cands[np.argmin(np.where(cands < 10000, miss, np.inf))]
fig, ax = plt.subplots(figsize=(10, 3.2))
ax.semilogy(cands / 3600, miss / 1e3); ax.axvline(tm[i_burn] / 3600, color="r", lw=1, label="the model's deorbit time")
ax.set(xlabel="deorbit burn (h after lift-off)", ylabel="distance from the pad (km)"); ax.legend(); plt.show()
print(f"first-orbit opportunity: a burn at {best:.0f} s brings the ship within {np.min(miss[cands < 10000])/1e3:.1f} km; "
      f"the model burns at {tm[i_burn]:.1f} s")
assert abs(best - tm[i_burn]) < 60
""")

md(r"""
## 4. The booster's return

The boostback burn ends when the impact point predicted for a fall in vacuum (`ImpactPointPredictor`) has come back past the tower by a bias that allows for drag. The bias is the booster's main targeting parameter: `ef.translate` builds `BoosterReturn` once, and the runs below sweep it. The landing burn starts when braking at 60 % of thirteen engines' thrust would just stop the booster (the hover-slam), but no higher than 6 km: above that the air still brakes the fall for nothing. Three engines finish it into the arms.
""")

code(r"""
booster = ef.translate(source, model="StarVesselMission.BoosterReturn", libraries=libraries)
outs = ["booster.computer.flight.phase", "booster.computer.landing.offset", "booster.computer.landing.sinkRate",
        "booster.feed.propellant", "booster.computer.h", "booster.computer.landing.v_ref", "booster.airData.h",
        "booster.ipp.rangeToGo", "booster.ipp.crossRange"]
def catch(r):
    ph = r["booster.computer.flight.phase"]; i = first(ph >= 6)
    return ph[-1] >= 6, r["booster.computer.landing.offset"][i], r["booster.computer.landing.sinkRate"][i], r["booster.feed.propellant"][i]
biases = np.linspace(*BIAS_SWEEP)
sweep = []
for b in biases:
    caught, miss_b, sink, prop = catch(booster.simulate(stop=480, interval=0.5, outputs=outs, set={"booster.computer.rangeBias": b}))
    sweep.append((b, caught, miss_b, sink, prop))
display(Markdown("| bias (m) | caught | miss (m) | sink at the arms (m/s) | propellant left (t) |\n|---|---|---|---|---|\n" +
                 "\n".join(f"| {b:.0f} | {'yes' if c else 'no'} | {m:.1f} | {s:.2f} | {p/1e3:.1f} |" for b, c, m, s, p in sweep)))
nominal = booster.simulate(stop=480, interval=0.2, outputs=outs)
caught, miss_n, sink_n, prop_n = catch(nominal)
print(f"the model's bias (-350 m): caught {caught}, {miss_n:.1f} m from the catch point at {sink_n:.2f} m/s, {prop_n/1e3:.1f} t left")
assert caught and miss_n < 20
""")

code(r"""
tb = nominal.time
i5 = first(nominal["booster.computer.flight.phase"] >= 5)
h_ign, v_ign = nominal["booster.computer.h"][i5], nominal["booster.computer.landing.sinkRate"][i5]
# the hover-slam's stopping height at 60 % of thirteen engines, against gravity
m_burn = 2.75e5 + nominal["booster.feed.propellant"][i5]
a_net = 0.6 * 13 * (2.65e6 - 1.5 * 1.01e5) / m_burn - G0
stop_height = v_ign**2 / (2 * a_net)
print(f"landing burn lit at {h_ign:.0f} m and {v_ign:.0f} m/s: braking at {a_net:.1f} m/s2 alone would take "
      f"{stop_height:.0f} m, more than the 6 km the burn may start at; the dense air below makes up the rest")
fig, ax = plt.subplots(1, 2, figsize=(12, 3.6))
sel = tb > tb[i5] - 30
ax[0].plot(nominal["booster.computer.h"][sel], nominal["booster.computer.landing.sinkRate"][sel], label="sink rate")
ax[0].plot(nominal["booster.computer.h"][sel], nominal["booster.computer.landing.v_ref"][sel], "--", label="the three engines' plan")
ax[0].set(xlabel="height above the catch point (m)", ylabel="m/s", xlim=(0, 6000)); ax[0].legend()
ax[1].plot(tb, nominal["booster.ipp.crossRange"] / 1e3, label="cross-range")
ax[1].plot(tb, nominal["booster.ipp.rangeToGo"] / 1e3, label="range to go")
ax[1].set(xlabel="time (s)", ylabel="impact point from the tower (km)", xlim=(120, 170), ylim=(-50, 450)); ax[1].legend()
fig.tight_layout(); plt.show()
# the hover-slam asks for more height than allowed, so the 6 km cap lights the burn
assert stop_height > h_ign and abs(h_ign - 6000) < 0.03 * 6000
""")

md(r"""
## 5. Entry

`ShipEntryLanding` starts from the ship's parking orbit at 3900 s, the same state as `FullMission`. At the entry interface it is near orbital speed; at 60° angle of attack it decelerates high in the atmosphere, where the heat flux into its nose, by Sutton and Graves $q = k\sqrt{\rho/R_n}\,V^3$, peaks. Recomputed here from the run's density and airspeed it matches what the heat shield received; its integral is the heat load the tiles have to store or radiate.
""")

code(r"""
ent = sim("ShipEntryLanding")
te = ent.time
rho, V = ent["ship.atmosphere.rho"], ent["ship.airData.V"]
q = 1.7415e-4 * np.sqrt(rho / 4.5) * V**3
i_peak = int(np.argmax(q))
heat_load = np.trapezoid(q, te)
display(Markdown(f"Peak flux **{q[i_peak]/1e3:.0f} kW/m²** at {ent['ship.airData.h'][i_peak]/1e3:.0f} km and Mach "
                 f"{ent['ship.airData.Mach'][i_peak]:.1f}; heat load {heat_load/1e6:.0f} MJ/m²; tiles peak at "
                 f"**{ent['ship.heatShield.T'].max():.0f} K**; the deceleration peaks at {ent['ship.imu.loadFactor'].max():.2f} g."))
assert np.allclose(q, ent["ship.heatShield.heating.q"], rtol=1e-6, atol=1e-6)
assert 900 < ent["ship.heatShield.T"].max() < 1700
fig, ax = plt.subplots(1, 3, figsize=(13, 3.4))
ax[0].plot(ent["ship.airData.V"] / 1e3, ent["ship.airData.h"] / 1e3); ax[0].set(xlabel="airspeed (km/s)", ylabel="altitude (km)", ylim=(0, 130))
ax[1].plot(te, q / 1e3); ax[1].set(xlabel="time (s)", ylabel="stagnation heat flux (kW/m2)", xlim=(5200, 6400))
ax[2].plot(te, ent["ship.heatShield.T"]); ax[2].set(xlabel="time (s)", ylabel="tile temperature (K)", xlim=(5200, 6400))
fig.tight_layout(); plt.show()
""")

md(r"""
## 6. The landing burn against the fuel-optimal one

The ship flips on three engines and lands on one. `Descent3DOF` is the same burn as a point mass in the vertical plane, with the thrust the ship can give (one engine at 40 % up to all three at full): from the 6-DOF ship's state as its flip begins, `ef.optimal_control` finds the throttle and thrust direction that bring it to rest on the pad with the most propellant left, for a few burn times. The ship's guidance, which also has to turn the ship upright, cannot do better than that bound.
""")

code(r"""
i7 = first(ent["ship.computer.flight.phase"] >= 7)
i8 = first(ent["ship.computer.flight.phase"] >= 8)
used_6dof = ent["ship.header.propellant"][i7] - ent["ship.header.propellant"][i8]
sink_td = ent["ship.computer.landing.sinkRate"][i8]
Rp = vec(ent, "ship.padTarget.r")[i7]; up = Rp / np.linalg.norm(Rp)
d = vec(ent, "ship.motion.r")[i7] - Rp; dv_ = vec(ent, "ship.motion.v")[i7] - vec(ent, "ship.padTarget.v")[i7]
dh = d - (d @ up) * up; e1 = dh / np.linalg.norm(dh)
# the ship can give from one engine at 40 % to all three at full thrust: the point mass gets that range
start = {"h0": d @ up, "x0": -np.linalg.norm(dh), "vh0": dv_ @ up, "vx0": -(dv_ @ e1), "m0": ent["ship.shipMass.y.m"][i7],
         "Fmax": 3 * 2.5e6}
print("flip starts at", {k: round(float(v), 1) for k, v in start.items()})
# the point-mass burn from the ship's state: a model that extends Descent3DOF with it
descent = out / "Descent.mo"
descent.write_text("model Descent extends StarVesselMission.Descent3DOF(" +
                   ", ".join(f"{k} = {v:.6g}" for k, v in start.items()) + "); end Descent;")
best_oc = None
for T in DESCENT_TIMES:
    oc = ef.optimal_control(descent, model="Descent", libraries=[source, *libraries], controls={"throttle": (0.4 / 3, 1.0, 0.3), "tilt": (-0.3, 0.3, 0.0)},
                            stop=T, intervals=40, terminal="-m", final={"h": 0.0, "vh": -1.0, "x": 0.0, "vx": 0.0},
                            bounds={"h": (0.0, 3000.0)})
    used = start["m0"] - oc.x["m"][-1]
    print(f"{T:4.0f} s: converged {oc.converged}, propellant {used/1e3:.2f} t")
    if oc.converged and (best_oc is None or used < best_oc[1]):
        best_oc = (T, used, oc)
print(f"the 6-DOF ship used {used_6dof/1e3:.2f} t from its flip and touched down at {sink_td:.2f} m/s; the optimum "
      f"{best_oc[1]/1e3:.2f} t in {best_oc[0]} s")
assert best_oc is not None and best_oc[1] <= used_6dof
assert abs(sink_td) < 2.0
""")

md(r"""
## 7. The autopilot

On one engine the ship is a pitch inertia that its gimbal turns: `AutopilotPlant` holds the gimbal actuator, the thrust's moment and the sideways speed the tilted thrust gives. `ef.linearize` turns it into a state-space model; with the attitude loop's proportional-derivative law at the landing bandwidth, the loop's margins follow from its frequency response.
""")

code(r"""
lin = ef.linearize(source, model="StarVesselMission.AutopilotPlant", libraries=libraries)
display(Markdown(f"States {lin.states}, input {lin.inputs}, outputs {lin.outputs}."))
A, B, C = lin.A, lin.B, lin.C[lin.outputs.index("tilt")]
w = np.logspace(-2, 2, 2000)
P = np.array([C @ np.linalg.solve(1j * wi * np.eye(len(A)) - A, B)[:, 0] for wi in w])
zeta = 0.9
K = lambda s: -(LOOP_BANDWIDTH**2 + 2 * zeta * LOOP_BANDWIDTH * s) / 1.5918   # PD on the tilt; the plant's -T l/J
L = np.array([K(1j * wi) for wi in w]) * P
ic = int(np.argmin(abs(abs(L) - 1)))
pm = 180 + np.angle(L[ic], deg=True)
print(f"crossover {w[ic]:.2f} rad/s, phase margin {pm:.0f} deg")
fig, ax = plt.subplots(2, 1, figsize=(8, 5), sharex=True)
ax[0].loglog(w, abs(L)); ax[0].axhline(1, color="k", lw=0.5); ax[0].set(ylabel="|L|")
ax[1].semilogx(w, np.unwrap(np.angle(L)) * DEG); ax[1].axhline(-180, color="k", lw=0.5); ax[1].set(xlabel="rad/s", ylabel="phase (deg)")
plt.show()
assert pm > 30
""")

md(r"""
## 8. Monte Carlo: the booster's catch

The engines' thrust, the propellant the booster keeps for its return and the oxygen loaded at the pad all scatter a little from flight to flight. The runs below draw them at random (the settings cell sets their spread) and fly `BoosterReturn` again each time, through the same translated model: the arms close on it if it reaches them within 20 m.
""")

code(r"""
rng = np.random.default_rng(2026)
mc = []
for k in range(MC_RUNS):
    f = 1 + MC_THRUST * rng.standard_normal()
    s = {"booster.centerRing.F_vac": 2.65e6 * f, "booster.innerRing.F_vac": 2.65e6 * f, "booster.outerRing.F_vac": 2.65e6 * f,
         "booster.m_MECO": 4e5 * (1 + MC_RESERVE * rng.standard_normal()), "booster.m_lox": 2.661e6 * (1 + MC_LOAD * rng.standard_normal())}
    mc.append(catch(booster.simulate(stop=480, interval=0.5, outputs=outs, set=s)))
caught_share = np.mean([c for c, *_ in mc])
misses = np.array([m for c, m, *_ in mc if c])
print(f"{MC_RUNS} runs: {caught_share:.0%} caught, miss {misses.mean():.1f} m on average, at most {misses.max():.1f} m")
fig, ax = plt.subplots(figsize=(6, 3))
ax.hist(misses, bins=10); ax.set(xlabel="miss at the catch point (m)", ylabel="runs"); plt.show()
assert caught_share >= 0.9
""")

md(r"""
## 9. The whole mission

`FullMission` (run above) flies both vehicles from the pad to their homes in one run and stops 15 s after both are there. Its results keep only the signals its plots, this worksheet and the 3-D view need (the `__EquaForge_Outputs` filter), on a fine output grid through the burns and a coarse one through the coast (`__EquaForge_OutputIntervals`). The 3-D view below opens on the launch site, drawn in the axes of its ground (**site.ground axes**: east, north and up), with the camera on the ship; choose **booster.look.hull** in its follow box to ride back with the booster.
""")

code(r"""
names = {0: "on the pad", 1: "ascent", 2: "hot staging", 3: "flip and boostback", 4: "fall", 5: "landing burn", 6: "caught"}
names_s = {1: "hot staging", 2: "ascent", 3: "coast", 4: "deorbit burn", 5: "entry", 6: "belly-flop", 7: "flip and landing burn", 8: "landed"}
rows = []
for veh, key, lab in (("booster", "booster.computer.flight.phase", names), ("ship", "ship.computer.flight.phase", names_s)):
    ph = mission[key]
    for i in np.flatnonzero(np.diff(ph) > 0) + 1:
        rows.append((tm[i], veh, lab.get(int(ph[i]), str(int(ph[i])))))
rows.sort()
display(Markdown("| t (s) | vehicle | begins |\n|---|---|---|\n" + "\n".join(f"| {t_:.1f} | {v} | {p} |" for t_, v, p in rows)))
i_end = len(tm) - 1
print(f"{len(mission.events)} events; the booster {mission['booster.computer.landing.offset'][i_end]:.2g} m from its catch point, "
      f"the ship {mission['ship.computer.landing.offset'][i_end]:.0f} m from its pad, {mission['ship.header.propellant'][i_end]/1e3:.1f} t of landing propellant left")
assert mission["booster.caught"][i_end] > 0.5 and mission["ship.landed"][i_end] > 0.5
assert len(mission.events) < 200
mission.save(out / "FullMission.csv")
ef.Animation(mission)
""")

nb = {"cells": cells, "metadata": {"kernelspec": {"display_name": "EquaForge (Python)", "language": "python", "name": "python3"},
                                   "language_info": {"name": "python"}},
      "nbformat": 4, "nbformat_minor": 5}
target = sys.argv[1] if len(sys.argv) > 1 else OUT
with open(target, "w", encoding="utf-8", newline="\n") as f:
    json.dump(nb, f, indent=1, ensure_ascii=False)
    f.write("\n")
print(f"wrote {target} ({len(cells)} cells)")
