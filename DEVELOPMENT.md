# Library development

This folder is an independent Git repository, kept inside the app checkout at
`toolboxes/EquaForgeAerospace` (the app repository ignores it). Edit and commit here while the
app stays on its own branch. Keep the package folder name unchanged so Modelica and Library
registration continue to resolve it. Source, examples, help and tests are versioned together.
Core app changes, including blocks of `EquaForgeVC`, belong in the app repository.

Library source can be edited without recompiling the app; reload the libraries in Studio
afterward. Commits here use the aisvo identity, set in this repository's Git config. It has no
remote yet. Licensing remains `NOASSERTION`.

Commits follow the app's rules: a concise, bulleted message with no attribution footers (the
app's `commit-msg` hook, copied into `.git/hooks`, strips them), and C++ formatted with
clang-format 18.1.8 and the app's `.clang-format`, as its CI checks.

## Tests

The tests run inside the app's test suite. Configure the app's build with this folder:

```powershell
cmake -S . -B build/mingw-release -DEF_AEROSPACE_TOOLBOX_DIR=D:/proj/cpp/equaforge/toolboxes/EquaForgeAerospace
cmake --build build/mingw-release
ctest --test-dir build/mingw-release -R "aerospace|StarshipMission|studio\.help$"
```

That adds:

- `unit.aerospace` (`tests/test_aerospace.cpp`): the blocks against analytic results, published
  tables and worked examples, and every help page (its class, its place, its figures).
- `examples.model.StarshipMission.*`: every model of the study runs as shipped.
- `examples.study.StarshipMission_Analysis`: the worksheet runs and its checks pass (about 90 s).
- In `studio.help` (`tests/test_aerospace_help_ui.cpp`): the pages draw every formula, diagram
  and figure.
- In `studio.ui`, the app's examples audit also covers the study: every model has named plots,
  notes that do not overlap, and a 3-D view that names shapes the model has.

Leave `EF_AEROSPACE_TOOLBOX_DIR` empty to build the app without them.

## Generated files

Edit the generators and run them again rather than editing their output. Both need an
EquaForge checkout (`EF_SOURCE_DIR`, or the app this folder sits in):

- `python tools/make_figures.py` draws `Resources/Documentation/figures/*.svg` with the app's
  figure kit (`tools/make_library_figures.py`).
- `python tools/make_starship_worksheet.py` writes
  `examples/starship_mission/StarshipMission_Analysis.ipynb`.
- `python docs/starship/make_figures.py` runs the mission and draws the tutorial's mission
  profile; it needs the equaforge Python package of a build (`PYTHONPATH`, `EQUAFORGE_DLL_DIR`).
