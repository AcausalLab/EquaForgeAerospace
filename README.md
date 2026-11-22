# Aerospace

This optional library adds launch vehicles and spacecraft to EquaForge: the turning Earth,
launch sites, gravity with J2, the 1976 standard atmosphere and air data; body, flap and
grid-fin aerodynamics; propellant tanks, turbopumps, nozzles, engines and engine clusters;
electromechanical actuators; orbital elements, ground tracks, an IMU, attitude errors, entry
attitude, an impact point predictor and powered-descent guidance; stagnation-point heating. Its
namespace is `EquaForgeAerospace`. It builds on the free bodies of the core library
(`EquaForgeVC.Multibody`).

| Folder | What |
|---|---|
| `package.mo` | The library, with four small examples in `EquaForgeAerospace.Examples` (an orbit with J2, a static fire, a capsule's entry heating, a hopper that lands again) |
| `Resources/Documentation` | Help pages (F1) with equations, Mermaid diagrams and figures |
| `examples/starvessel_mission` | A StarVessel round trip: two 6-DOF stages, booster tower catch, orbit, entry and landing, with an analysis worksheet |
| `docs/starvessel-mission.md` | A tutorial through the StarVessel study |
| `tests`, `tools` | Development checks and the generators of the figures and the worksheet (not distributed) |

The vehicle data in the StarVessel study are **illustrative**: rounded from public estimates for
a fully reusable two-stage launcher, not any manufacturer's data.

In Studio, open Settings > Libraries, choose Add Folder, and select this folder (the folder
containing `package.mo` and `library.json`). The Library, Blocks, Examples and F1 help features
use the registered package; the study appears under Examples > Studies. Remove its library path
to unload it. Reload libraries after editing source files.

The library needs an EquaForge with the free-flight multibody blocks, the follow camera and the
simulation controls of long runs (output filters, piecewise output grids, maximum step).

From the app's repository root, simulate a model with:

```text
equaforge simulate toolboxes/EquaForgeAerospace --model EquaForgeAerospace.Examples.Hopper --quiet -o results/hopper.csv
equaforge simulate toolboxes/EquaForgeAerospace/examples/starvessel_mission/StarVesselMission.mo --lib toolboxes/EquaForgeAerospace --model StarVesselMission.FullMission --quiet -o results/mission.csv
```

EquaForgeVC is added automatically when a model uses it. From Python, pass the toolbox folder
in `libraries`:

```python
r = ef.simulate("StarVesselMission.mo", model="StarVesselMission.FullMission", libraries=["../.."])
```

Package a development ZIP with:

```text
python tools/package_toolbox.py toolboxes/EquaForgeAerospace --output build/toolboxes/EquaForgeAerospace-0.1.0.zip
```

Unpack the ZIP and register its `EquaForgeAerospace` folder. The core application installer
excludes this independently maintained library.

To install a release instead, open Settings > Libraries > Browse online… > Catalog sources in
Studio and add
`https://github.com/AcausalLab/EquaForgeAerospace/releases/latest/download/toolboxes.json`.

The toolbox is licensed under the BSD 3-Clause License; see [LICENSE](LICENSE).

See [DEVELOPMENT.md](DEVELOPMENT.md) for the repository and test workflow.
